<?php

namespace App\Http\Controllers;

use App\Models\Assignment;
use App\Models\Building;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\Document;
use App\Models\Syndic;
use App\Models\Notification;
use App\Models\User;
use App\Services\NotificationService as PushNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class InterventionController extends Controller
{
    protected $pushNotificationService;
    protected $aiService;

    public function __construct(PushNotificationService $pushNotificationService, \App\Services\AiService $aiService)
    {
        $this->pushNotificationService = $pushNotificationService;
        $this->aiService = $aiService;
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'description' => 'required|string',
            'addressFull' => 'required|string',
            'urgency' => 'required|string',
            'role' => 'required|string',
            'syndicId' => 'nullable|string',
            'status' => 'nullable|string',
            'sector' => 'nullable|string',
            'onSiteContactName' => 'required|string',
            'onSiteContactPhone' => 'required|string',
            'onSiteContactEmail' => 'nullable|string',
            'files.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx|max:10240',
            'photos.*' => 'nullable|file|image|max:10240',
        ]);

        // 1. Find or create building
        $building = Building::where('address', $validated['addressFull'])->first();
        if (!$building) {
            $building = Building::create([
                'address' => $validated['addressFull'],
                'syndic_id' => $validated['syndicId'] ?? null,
                'city' => 'Unknown',
            ]);
        }

        $entity = null;
        $user = $request->user();
        // Client users can only send mission requests; staff create interventions directly
        $type = $user->isClient() ? 'mission' : $request->input('type', 'intervention');
        $required = $type === 'mission' ? 'missions.create' : 'interventions.create';
        if (!$user->hasPermission($required)) {
            return response()->json(['success' => false, 'message' => 'You are not allowed to perform this action.'], 403);
        }

        $translations = $this->aiService->translateToFill($validated['title'], $validated['description']);

        if ($type === 'mission') {
            $entity = Mission::create([
                'building_id' => $building->id,
                'syndic_id' => $validated['syndicId'] ?? null,
                'requested_by' => $validated['role'],
                'title' => $validated['title'],
                'description' => $validated['description'],
                'title_en' => $translations['title']['en'] ?? $validated['title'],
                'title_fr' => $translations['title']['fr'] ?? $validated['title'],
                'title_nl' => $translations['title']['nl'] ?? $validated['title'],
                'description_en' => $translations['description']['en'] ?? $validated['description'],
                'description_fr' => $translations['description']['fr'] ?? $validated['description'],
                'description_nl' => $translations['description']['nl'] ?? $validated['description'],
                'urgency' => $validated['urgency'],
                'status' => 'PENDING',
                'category' => $validated['sector'] ?? 'GENERAL',
                'sector' => $validated['sector'] ?? 'GENERAL',
                'on_site_contact_name' => $validated['onSiteContactName'] ?? null,
                'on_site_contact_phone' => $validated['onSiteContactPhone'] ?? null,
                'on_site_contact_email' => $validated['onSiteContactEmail'] ?? null,
            ]);

            // Notify Admins about new Mission (push to phone + in-app)
            $this->pushNotificationService->notifyNewMission($entity);
        } else {
            $entity = Intervention::create([
                'building_id' => $building->id,
                'syndic_id' => $validated['syndicId'] ?? null,
                'pro_id' => $request->pro_id ?? null,
                'title' => $validated['title'],
                'description' => $validated['description'],
                'title_en' => $translations['title']['en'] ?? $validated['title'],
                'title_fr' => $translations['title']['fr'] ?? $validated['title'],
                'title_nl' => $translations['title']['nl'] ?? $validated['title'],
                'description_en' => $translations['description']['en'] ?? $validated['description'],
                'description_fr' => $translations['description']['fr'] ?? $validated['description'],
                'description_nl' => $translations['description']['nl'] ?? $validated['description'],
                'urgency' => $validated['urgency'],
                'status' => (($validated['status'] ?? null) === 'COMPLETED' && !$user->hasPermission('interventions.reopen'))
                    ? 'PENDING'
                    : ($validated['status'] ?? 'PENDING'),
                'category' => $validated['sector'] ?? 'GENERAL',
                'sector' => $validated['sector'] ?? 'GENERAL',
                'on_site_contact_name' => $validated['onSiteContactName'] ?? null,
                'on_site_contact_phone' => $validated['onSiteContactPhone'] ?? null,
                'on_site_contact_email' => $validated['onSiteContactEmail'] ?? null,
            ]);

            if ($entity->pro_id) {
                Assignment::record($entity->id, null, (int) $entity->pro_id, $user->id);
                $this->notifyAssignedUser(User::find($entity->pro_id), $entity);
            }
        }

        // 2. Handle file uploads
        if ($request->hasFile('files')) {
            foreach ($request->file('files') as $file) {
                $path = $file->store('documents', 'public');
                $entity->documents()->create([
                    'file_path' => $path,
                    'file_name' => $file->getClientOriginalName(),
                    'file_type' => $file->getClientMimeType(),
                ]);
            }
        }

        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $file) {
                $path = $file->store('photos', 'public');
                $entity->documents()->create([
                    'file_path' => $path,
                    'file_name' => $file->getClientOriginalName(),
                    'file_type' => $file->getClientMimeType(),
                ]);
            }
        }

        return response()->json([
            'message' => 'Request created successfully',
            'data' => $entity->load('documents'),
            'type' => $type
        ], 201);
    }


    public function getBuildings()
    {
        return response()->json(Building::all());
    }

    public function getSyndics()
    {
        return response()->json(Syndic::all());
    }

    /**
     * Field workers (the PROFESSIONAL / TECHNICIAN role used by the mobile app)
     * only get the work that is assigned to them. Dispatchers and admins still
     * see everything so they can assign and manage the whole team.
     */
    private function isFieldWorker(?User $user): bool
    {
        return $user !== null
            && !$user->isClient()
            && in_array(strtoupper((string) $user->role), ['PROFESSIONAL', 'TECHNICIAN'], true);
    }

    /** Restrict a mission query to the missions assigned to this field worker. */
    private function onlyAssignedMissions($query, User $user)
    {
        return $query->where('assigned_user_id', $user->id);
    }

    /** Restrict an intervention query to the interventions assigned to this field worker. */
    private function onlyAssignedInterventions($query, User $user)
    {
        return $query->where(function ($q) use ($user) {
            $q->where('pro_id', $user->id)
              ->orWhereHas('assignments', function ($assignmentQuery) use ($user) {
                  $assignmentQuery->where('user_id', $user->id)
                                  ->whereNull('unassigned_at');
              });
        });
    }

    /** Whether this intervention is currently assigned to the given field worker. */
    private function interventionBelongsTo(Intervention $intervention, User $user): bool
    {
        if ((int) $intervention->pro_id === (int) $user->id) {
            return true;
        }

        return $intervention->assignments()
            ->where('user_id', $user->id)
            ->whereNull('unassigned_at')
            ->exists();
    }

    public function getMissions()
    {
        $user = auth('sanctum')->user();

        $query = Mission::with(['documents', 'email', 'building', 'syndic', 'assignedUser:id,name,email,role,phone'])->latest();

        if ($user && $user->isClient()) {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email)
                  ->orWhereHas('email', function ($emailQuery) use ($user) {
                      $emailQuery->where('from_address', $user->email);
                  });
            });
        } elseif ($this->isFieldWorker($user)) {
            $this->onlyAssignedMissions($query, $user);
        }

        return response()->json($query->get());
    }

    public function getMissionById($id)
    {
        $user = auth('sanctum')->user();
        $query = Mission::with(['documents', 'email', 'building', 'assignedUser:id,name,email,role,phone']);
        
        if ($user && $user->isClient()) {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email)
                  ->orWhereHas('email', function ($emailQuery) use ($user) {
                      $emailQuery->where('from_address', $user->email);
                  });
            });
        } elseif ($this->isFieldWorker($user)) {
            $this->onlyAssignedMissions($query, $user);
        }
        
        $mission = $query->findOrFail($id);
        return response()->json($mission);
    }

    public function getInterventions()
    {
        $user = auth('sanctum')->user();
        
        $query = Intervention::with(['documents', 'building', 'professional', 'syndic']);

        if ($user && $user->isClient()) {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email);
            });
        } elseif ($this->isFieldWorker($user)) {
            $this->onlyAssignedInterventions($query, $user);
        }

        return response()->json($query->get());
    }

    public function getInterventionById($id)
    {
        $user = auth('sanctum')->user();
        $query = Intervention::with(['documents', 'building', 'professional', 'syndic']);

        if ($user && $user->isClient()) {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email);
            });
        } elseif ($this->isFieldWorker($user)) {
            $this->onlyAssignedInterventions($query, $user);
        }

        $intervention = $query->findOrFail($id);
        return response()->json($intervention);
    }

    public function approveMission(Request $request, $id)
    {
        $request->validate([
            'assigned_user_id' => ['nullable', \Illuminate\Validation\Rule::in(User::staff()->pluck('id')->all())],
        ]);

        try {
            return \Illuminate\Support\Facades\DB::transaction(function () use ($request, $id) {
                $mission = Mission::with('documents')->findOrFail($id);

                $buildingId = $mission->building_id;

                // 1. If no building assigned, try to find one from extracted_address
                if (!$buildingId && $mission->extracted_address) {
                    $raw = $mission->extracted_address;
                    $normalizedRaw = strtolower(preg_replace('/[^a-z0-9\s]/i', '', $raw));
                    
                    // Try normalized match against existing buildings
                    $buildings = Building::all();
                    foreach ($buildings as $b) {
                        $normalizedExisting = strtolower(preg_replace('/[^a-z0-9\s]/i', '', $b->address));
                        if ($normalizedExisting === $normalizedRaw || str_contains($normalizedExisting, $normalizedRaw) || str_contains($normalizedRaw, $normalizedExisting)) {
                            $buildingId = $b->id;
                            break;
                        }
                    }

                    // If still no building found, create a new one
                    if (!$buildingId) {
                        $building = Building::create([
                            'address' => $raw,
                            'city' => 'Unknown',
                            'syndic_id' => $mission->syndic_id,
                            'admin_note' => 'Automatically created during mission approval.',
                        ]);
                        $buildingId = $building->id;
                    }
                    
                    $mission->update(['building_id' => $buildingId]);
                }

                // 2. Validate we have a building now
                if (!$buildingId) {
                    return response()->json([
                        'message' => 'This mission is missing an address. Please assign a building to it before approving.'
                    ], 422);
                }

                $assignedUserId = $request->assigned_user_id ? (int) $request->assigned_user_id : null;

                $mission->update(['status' => 'APPROVED', 'assigned_user_id' => $assignedUserId]);

                // 3. Create an Intervention based on the mission
                $intervention = Intervention::create([
                    'building_id' => $buildingId,
                    'syndic_id' => $mission->syndic_id,
                    'pro_id' => $assignedUserId,
                    'title' => $mission->title ?? 'Approved Mission',
                    'title_en' => $mission->title_en,
                    'title_fr' => $mission->title_fr,
                    'title_nl' => $mission->title_nl,
                    'description' => $mission->description ?? 'No description provided.',
                    'description_en' => $mission->description_en,
                    'description_fr' => $mission->description_fr,
                    'description_nl' => $mission->description_nl,
                    'category' => $mission->category ?? 'GENERAL',
                    'sector' => $mission->sector ?? 'GENERAL',
                    'urgency' => $mission->urgency ?? 'MEDIUM',
                    'status' => 'PENDING',
                    'scheduled_date' => ($request->scheduled_date && $request->scheduled_date !== 'null') ? Carbon::parse($request->scheduled_date) : null,
                    'on_site_contact_name' => $mission->on_site_contact_name,
                    'on_site_contact_phone' => $mission->on_site_contact_phone,
                    'on_site_contact_email' => $mission->on_site_contact_email,
                    'extracted_syndic_name' => $mission->extracted_syndic_name,
                ]);

                // 4. Copy documents from mission to intervention
                foreach ($mission->documents as $doc) {
                    $intervention->documents()->create([
                        'file_path' => $doc->file_path,
                        'file_name' => $doc->file_name,
                        'file_type' => $doc->file_type,
                    ]);
                }

                // 5. Link the mission to the chosen user and keep a history of who worked on it
                if ($assignedUserId) {
                    Assignment::record($intervention->id, $mission->id, $assignedUserId, $request->user()?->id);
                    $this->notifyAssignedUser(User::find($assignedUserId), $intervention);
                }

                // 6. Notify Syndic about Approval
                if ($mission->syndic_id) {
                    // Only notify the syndic of this mission (no fallback: it would notify a random syndic)
                    $syndic = User::where('id', $mission->syndic_id)->where('role', 'SYNDIC')->first();
                    
                    if ($syndic) {
                        $title = "Mission Approved!";
                        $body = "Your mission '{$mission->title}' has been approved.";

                        $data = ['type' => 'intervention', 'intervention_id' => $intervention->id];

                        if ($syndic->fcm_token) {
                            try {
                                $this->pushNotificationService->sendNotification($syndic->fcm_token, $title, $body, $data);
                            } catch (\Exception $e) {}
                        }

                        Notification::createWithTranslation([
                            'user_id' => $syndic->id,
                            'title' => $title,
                            'body' => $body,
                            'type' => 'intervention',
                            'data' => $data
                        ]);
                    }
                }

                return response()->json([
                    'message' => 'Mission approved successfully',
                    'mission' => $mission,
                    'intervention' => $intervention->load('documents')
                ]);
            });
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to approve mission: ' . $e->getMessage()
            ], 500);
        }
    }

    public function rejectMission($id)
    {
        $mission = Mission::findOrFail($id);
        $mission->update(['status' => 'REJECTED']);

        // Notify Syndic about Rejection
        if ($mission->syndic_id) {
            $syndic = User::where('id', $mission->syndic_id)->where('role', 'SYNDIC')->first();
            if ($syndic) {
                $title = "Mission Rejected";
                $body = "Your mission '{$mission->title}' was unfortunately rejected.";
                $data = ['type' => 'mission', 'mission_id' => $mission->id];

                if ($syndic->fcm_token) {
                    try {
                        $this->pushNotificationService->sendNotification($syndic->fcm_token, $title, $body, $data);
                    } catch (\Exception $e) {}
                }

                Notification::createWithTranslation([
                    'user_id' => $syndic->id,
                    'title' => $title,
                    'body' => $body,
                    'type' => 'mission',
                    'data' => $data
                ]);
            }
        }

        return response()->json([
            'message' => 'Mission rejected successfully',
            'mission' => $mission
        ]);
    }

    public function updateMission(Request $request, $id)
    {
        $mission = Mission::findOrFail($id);
        
        $validated = $request->validate([
            'title' => 'sometimes|string',
            'description' => 'sometimes|string',
            'sector' => 'sometimes|string',
            'urgency' => 'sometimes|string',
            'buildingId' => 'sometimes|nullable|string',
            'syndicId' => 'sometimes|nullable|string',
            'onSiteContactName' => 'sometimes|nullable|string',
            'onSiteContactPhone' => 'sometimes|nullable|string',
            'onSiteContactEmail' => 'sometimes|nullable|string',
        ]);

        if (array_key_exists('sector', $validated)) {
            $validated['category'] = $validated['sector'];
        }

        if (array_key_exists('onSiteContactName', $validated)) {
            $validated['on_site_contact_name'] = $validated['onSiteContactName'];
            unset($validated['onSiteContactName']);
        }
        if (array_key_exists('onSiteContactPhone', $validated)) {
            $validated['on_site_contact_phone'] = $validated['onSiteContactPhone'];
            unset($validated['onSiteContactPhone']);
        }
        if (array_key_exists('onSiteContactEmail', $validated)) {
            $validated['on_site_contact_email'] = $validated['onSiteContactEmail'];
            unset($validated['onSiteContactEmail']);
        }

        if (array_key_exists('buildingId', $validated)) {
            $validated['building_id'] = $validated['buildingId'];
            unset($validated['buildingId']);
        }

        if (array_key_exists('syndicId', $validated)) {
            $validated['syndic_id'] = $validated['syndicId'];
            unset($validated['syndicId']);
        }

        // Re-translate if title or description changed
        if ($request->has('title') || $request->has('description')) {
            $newTitle = $validated['title'] ?? $mission->title;
            $newDesc = $validated['description'] ?? $mission->description;
            $translations = $this->aiService->translateToFill($newTitle, $newDesc);
            
            $validated['title_en'] = $translations['title']['en'] ?? $newTitle;
            $validated['title_fr'] = $translations['title']['fr'] ?? $newTitle;
            $validated['title_nl'] = $translations['title']['nl'] ?? $newTitle;
            $validated['description_en'] = $translations['description']['en'] ?? $newDesc;
            $validated['description_fr'] = $translations['description']['fr'] ?? $newDesc;
            $validated['description_nl'] = $translations['description']['nl'] ?? $newDesc;
        }

        $mission->update($validated);
        
        // Handle additional file uploads if any
        if ($request->hasFile('files')) {
            foreach ($request->file('files') as $file) {
                $path = $file->store('documents', 'public');
                $mission->documents()->create([
                    'file_path' => $path,
                    'file_name' => $file->getClientOriginalName(),
                    'file_type' => $file->getClientMimeType(),
                ]);
            }
        }

        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $file) {
                $path = $file->store('photos', 'public');
                $mission->documents()->create([
                    'file_path' => $path,
                    'file_name' => $file->getClientOriginalName(),
                    'file_type' => $file->getClientMimeType(),
                ]);
            }
        }

        return response()->json([
            'message' => 'Mission updated successfully',
            'mission' => $mission->fresh()->load(['documents', 'building', 'syndic'])
        ]);
    }

    public function updateIntervention(Request $request, $id)
    {
        $intervention = Intervention::findOrFail($id);

        // A field worker can only update work that is assigned to them.
        if ($this->isFieldWorker($request->user()) && !$this->interventionBelongsTo($intervention, $request->user())) {
            return response()->json([
                'success' => false,
                'message' => 'This intervention is not assigned to you.',
            ], 403);
        }
        
        $validated = $request->validate([
            'status' => 'sometimes|string',
            'pro_id' => 'sometimes|nullable',
            'scheduled_date' => 'sometimes|date',
            'admin_feedback' => 'sometimes|nullable|string',
            'on_site_contact_name' => 'sometimes|nullable|string',
            'on_site_contact_phone' => 'sometimes|nullable|string',
            'on_site_contact_email' => 'sometimes|nullable|string',
            'delay_reason' => 'sometimes|nullable|string',
            'delay_details' => 'sometimes|nullable|string',
            'delayed_reschedule_date' => 'sometimes|nullable|date',
            'completed_at' => 'sometimes|nullable|date',
            'syndic_id' => 'sometimes|nullable|string',
            'files.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx|max:10240',
            'photos.*' => 'nullable|file|image|max:10240',
        ]);

        $oldStatus = $intervention->status;
        $oldProId = $intervention->pro_id;

        // A completed mission is locked: only roles with interventions.reopen (admin) may change it
        if ($oldStatus === 'COMPLETED' && !$request->user()->hasPermission('interventions.reopen')) {
            return response()->json([
                'success' => false,
                'message' => 'This mission is completed. Only an admin can change it.',
            ], 403);
        }

        if (($validated['status'] ?? null) === 'COMPLETED' && $oldStatus !== 'COMPLETED'
            && !$request->user()->hasPermission('interventions.reopen')) {
            return response()->json([
                'success' => false,
                'message' => 'Only an admin can mark a mission as completed.',
            ], 403);
        }

        if (array_key_exists('syndic_id', $validated) && ($validated['syndic_id'] === 'null' || $validated['syndic_id'] === '')) {
            $validated['syndic_id'] = null;
        }

        if (array_key_exists('pro_id', $validated) && ($validated['pro_id'] === 'null' || $validated['pro_id'] === '')) {
            $validated['pro_id'] = null;
        }

        $updateData = array_diff_key($validated, array_flip(['files', 'photos']));
        
        // Parse date fields if they exist as ISO strings
        foreach (['scheduled_date', 'completed_at', 'delayed_reschedule_date'] as $field) {
            if (isset($updateData[$field]) && !empty($updateData[$field])) {
                try {
                    $updateData[$field] = Carbon::parse($updateData[$field])->toDateTimeString();
                } catch (\Exception $e) {
                    // Fallback to original if parse fails
                }
            }
        }
        
        $intervention->update($updateData);
        
        // Notify Syndic about Status Update
        if (isset($updateData['status']) && $updateData['status'] !== $oldStatus) {
             if ($intervention->syndic_id) {
                $syndic = User::find($intervention->syndic_id);
                if ($syndic) {
                    $title = "Intervention Update";
                    $body = "The status of '{$intervention->title}' has changed to {$updateData['status']}.";
                    $data = ['type' => 'intervention', 'intervention_id' => $intervention->id];

                    if ($syndic->fcm_token) {
                        try {
                            $this->pushNotificationService->sendNotification($syndic->fcm_token, $title, $body, $data);
                        } catch (\Exception $e) {}
                    }

                    Notification::createWithTranslation([
                        'user_id' => $syndic->id,
                        'title' => $title,
                        'body' => $body,
                        'type' => 'intervention',
                        'data' => $data
                    ]);
                }
            }
        }

        // Record the assignment history and notify the newly assigned user
        if (array_key_exists('pro_id', $updateData) && $updateData['pro_id'] != $oldProId) {
            $missionId = Assignment::where('intervention_id', $intervention->id)->whereNotNull('mission_id')->value('mission_id');
            Assignment::record($intervention->id, $missionId, $updateData['pro_id'] ? (int) $updateData['pro_id'] : null, auth('sanctum')->id());

            if ($updateData['pro_id']) {
                $this->notifyAssignedUser(User::find($updateData['pro_id']), $intervention);
            }
        }

        // Handle Photo Uploads (Stored as Documents with image type)
        if ($request->hasFile('photos')) {
            foreach ($request->file('photos') as $file) {
                $path = $file->store('photos', 'public');
                $intervention->documents()->create([
                    'file_path' => $path,
                    'file_name' => $file->getClientOriginalName(),
                    'file_type' => $file->getClientMimeType(),
                ]);
            }
        }

        // Handle File Uploads (General Documents)
        if ($request->hasFile('files')) {
            foreach ($request->file('files') as $file) {
                $path = $file->store('documents', 'public');
                $intervention->documents()->create([
                    'file_path' => $path,
                    'file_name' => $file->getClientOriginalName(),
                    'file_type' => $file->getClientMimeType(),
                ]);
            }
        }

        return response()->json([
            'message' => 'Intervention updated successfully',
            'intervention' => $intervention->fresh()->load(['documents', 'building', 'professional', 'syndic'])
        ]);
    }

    protected function notifyAssignedUser(?User $user, Intervention $intervention): void
    {
        if (!$user) {
            return;
        }

        $title = "New Assignment";
        $body = "You have been assigned to a new intervention: '{$intervention->title}'.";

        if ($user->fcm_token) {
            try {
                $this->pushNotificationService->sendNotification($user->fcm_token, $title, $body, ['type' => 'intervention', 'intervention_id' => $intervention->id]);
            } catch (\Exception $e) {}
        }

        Notification::createWithTranslation([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => 'intervention',
            'data' => ['intervention_id' => $intervention->id]
        ]);
    }

    public function sendReport($id)
    {
        try {
            $intervention = Intervention::with(['building.syndic', 'syndic', 'professional', 'documents'])->findOrFail($id);
            
            $recipients = ['admin@vanakelgroup.com'];
            
            // 1. Add On-site contact email
            if ($intervention->on_site_contact_email) {
                $recipients[] = $intervention->on_site_contact_email;
            }
            
            // 2. Add Requesting Syndic email (from the record explicitly linked to intervention)
            if ($intervention->syndic && $intervention->syndic->email) {
                $recipients[] = $intervention->syndic->email;
            } 
            
            // 2b. ALSO check if syndic_id points to a User (as suggested by getProfile logic and user feedback)
            if ($intervention->syndic_id) {
                $userSyndic = User::find($intervention->syndic_id);
                if ($userSyndic && $userSyndic->email) {
                    $recipients[] = $userSyndic->email;
                }
            }
            
            // 3. Add Building Syndic email (fallback/extra if different)
            if ($intervention->building->syndic && $intervention->building->syndic->email) {
                $recipients[] = $intervention->building->syndic->email;
            }
            
            // 4. Add Professional email
            if ($intervention->professional && $intervention->professional->email) {
                $recipients[] = $intervention->professional->email;
            }
            
            // Filter unique emails, valid ones, and trim whitespace
            $recipients = array_unique(array_filter(array_map('trim', $recipients)));

            \Illuminate\Support\Facades\Mail::to($recipients)->send(new \App\Mail\InterventionReportMail($intervention));

            return response()->json([
                'message' => 'Report sent successfully',
                'recipients' => $recipients
            ]);
            
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Email sending failure: " . $e->getMessage());
            return response()->json([
                'message' => 'Failed to send report',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}


