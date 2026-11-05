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
            ...\App\Support\UploadRules::fileFields(),
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
            return response()->json(['success' => false, 'message' => __('You are not allowed to perform this action.')], 403);
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
            'message' => __('Request created successfully'),
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

        if ($intervention->assignments()->where('user_id', $user->id)->whereNull('unassigned_at')->exists()) {
            return true;
        }

        // fallback: the mission this intervention was made from is assigned to the user
        $missionId = $intervention->assignments()->whereNotNull('mission_id')->value('mission_id');

        return $missionId !== null && Mission::where('id', $missionId)->where('assigned_user_id', $user->id)->exists();
    }

    /** Runs a side effect (notification, history, e-mail) whose failure must never undo or fail a save that already happened. */
    private function bestEffort(callable $step, string $what, array &$warnings = []): void
    {
        try {
            $step();
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning("Intervention update: {$what} failed: " . $e->getMessage());
            $warnings[] = $what;
        }
    }

    /**
     * The uploads of a technician's phone are checked one by one and a file that does not pass is left out
     * (and reported in `warnings`) instead of failing the whole save. Admins keep the strict validation.
     *
     * @return array{0: array<int, \Illuminate\Http\UploadedFile>, 1: array<int, \Illuminate\Http\UploadedFile>, 2: array<int, string>}
     */
    private function acceptableUploads(Request $request): array
    {
        $rules = \App\Support\UploadRules::fileFields();
        $photos = [];
        $files = [];
        $skipped = [];

        foreach (['photos' => 'photos.*', 'files' => 'files.*'] as $field => $ruleKey) {
            foreach ((array) $request->file($field) as $file) {
                if (!$file instanceof \Illuminate\Http\UploadedFile) {
                    continue;
                }
                $valid = !$file->getError()
                    && \Illuminate\Support\Facades\Validator::make([$field => $file], [$field => str_replace('|', '|', $rules[$ruleKey])])->passes();
                if ($valid) {
                    $field === 'photos' ? $photos[] = $file : $files[] = $file;
                } else {
                    $skipped[] = (string) $file->getClientOriginalName();
                }
            }
        }

        return [$photos, $files, $skipped];
    }

    public function getMissions()
    {
        $user = auth('sanctum')->user();

        $query = Mission::with(['documents', 'email', 'building', 'syndic', 'updates', 'assignedUser:id,name,email,role,phone'])->latest();

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
        $query = Mission::with(['documents', 'email', 'building', 'updates', 'assignedUser:id,name,email,role,phone']);
        
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
        
        $query = Intervention::with(['documents', 'building', 'professional', 'syndic', 'submitter:id,name']);

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
        $query = Intervention::with(['documents', 'building', 'professional', 'syndic', 'submitter:id,name']);

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
                        'message' => __('This mission is missing an address. Please assign a building to it before approving.')
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
                        $this->pushNotificationService->notifyUser(
                            $syndic,
                            'mission_approved',
                            fn (string $locale) => ['title' => \App\Support\MessageText::field($mission, 'title', $locale)],
                            ['type' => 'intervention', 'intervention_id' => $intervention->id],
                            'intervention'
                        );
                    }
                }

                return response()->json([
                    'message' => __('Mission approved successfully'),
                    'mission' => $mission,
                    'intervention' => $intervention->load('documents')
                ]);
            });
        } catch (\Exception $e) {
            return response()->json([
                'message' => __('Failed to approve mission: :error', ['error' => $e->getMessage()])
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
                $this->pushNotificationService->notifyUser(
                    $syndic,
                    'mission_rejected',
                    fn (string $locale) => ['title' => \App\Support\MessageText::field($mission, 'title', $locale)],
                    ['type' => 'mission', 'mission_id' => $mission->id],
                    'mission'
                );
            }
        }

        return response()->json([
            'message' => __('Mission rejected successfully'),
            'mission' => $mission
        ]);
    }

    /**
     * Delete a mission (requires missions.delete). It is a soft delete: the mission is only hidden
     * (deleted_at), with its files, updates and history, so it can be restored. Interventions made
     * from it are untouched.
     */
    public function destroyMission($id)
    {
        Mission::findOrFail($id)->delete();

        return response()->json(['success' => true, 'message' => __('Mission deleted.')]);
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
            ...\App\Support\UploadRules::fileFields(),
        ]);
        // files are saved below, they are not columns of the missions table
        $validated = array_diff_key($validated, array_flip(['files', 'photos']));

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
            'message' => __('Mission updated successfully'),
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
                'message' => __('This intervention is not assigned to you.'),
            ], 403);
        }
        
        $actingUser = $request->user();
        $lenientFiles = $this->isFieldWorker($actingUser); // a technician's phone must not lose a save over one bad file

        // A retry of a save that already went through (the answer was lost on the way): answer "done" again
        $submissionKey = $request->filled('submission_id') ? 'intervention-submission:' . $id . ':' . substr((string) $request->input('submission_id'), 0, 100) : null;
        if ($submissionKey && \Illuminate\Support\Facades\Cache::has($submissionKey)) {
            return response()->json([
                'message' => __('Intervention updated successfully'),
                'intervention' => $intervention->fresh()->load(['documents', 'building', 'professional', 'syndic', 'submitter:id,name']),
                'report' => null,
                'submitted' => true,
                'duplicate' => true,
            ]);
        }

        $validated = $request->validate([
            'submission_id' => 'sometimes|nullable|string|max:100',
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
            ...($lenientFiles ? [] : \App\Support\UploadRules::fileFields()),
        ]);

        $oldStatus = $intervention->status;
        $oldProId = $intervention->pro_id;

        // "Send to Admin": the technician hands the work over for review. Only Completed or Delayed
        // can be sent, and a delay needs its reason. (Checked first: nothing is changed if it fails.)
        $submitting = $request->input('save_mode') === 'SUBMIT';
        if ($submitting) {
            $target = strtoupper((string) ($validated['status'] ?? $oldStatus));
            if (!in_array($target, ['COMPLETED', 'DELAYED'], true)) {
                return response()->json(['success' => false, 'message' => __('Choose Completed or Delayed before sending to the admin.')], 422);
            }
            if ($target === 'DELAYED' && trim((string) ($validated['delay_reason'] ?? $intervention->delay_reason)) === '') {
                return response()->json(['success' => false, 'message' => __('Select the reason for the delay before sending to the admin.')], 422);
            }
        }

        // Status can be changed by admins / super admins, and by the field worker the
        // intervention is assigned to (checked above). Everyone else is refused.
        $actor = $request->user();
        $isFieldWorker = $this->isFieldWorker($actor);
        if (isset($validated['status']) && $validated['status'] !== $oldStatus) {
            $isAdminOrSuperAdmin = $actor && ($actor->isSuperAdmin() || strtoupper((string) $actor->role) === 'ADMIN');
            if (!$isAdminOrSuperAdmin && !$isFieldWorker) {
                return response()->json([
                    'success' => false,
                    'message' => __('You are not allowed to update this intervention status.'),
                ], 403);
            }
        }

        // A field worker updates the job, not who it is assigned to / for / when
        if ($isFieldWorker) {
            unset($validated['pro_id'], $validated['syndic_id'], $validated['scheduled_date']);
        }

        // A completed mission is locked: only roles with interventions.reopen (admin) may change it
        if ($oldStatus === 'COMPLETED' && !$request->user()->hasPermission('interventions.reopen')) {
            return response()->json([
                'success' => false,
                'message' => __('This mission is completed. Only an admin can change it.'),
            ], 403);
        }

        if (($validated['status'] ?? null) === 'COMPLETED' && $oldStatus !== 'COMPLETED'
            && !$isFieldWorker && !$request->user()->hasPermission('interventions.reopen')) {
            return response()->json([
                'success' => false,
                'message' => __('Only an admin can mark a mission as completed.'),
            ], 403);
        }

        if (array_key_exists('syndic_id', $validated) && ($validated['syndic_id'] === 'null' || $validated['syndic_id'] === '')) {
            $validated['syndic_id'] = null;
        }

        if (array_key_exists('pro_id', $validated) && ($validated['pro_id'] === 'null' || $validated['pro_id'] === '')) {
            $validated['pro_id'] = null;
        }

        $updateData = array_diff_key($validated, array_flip(['files', 'photos', 'submission_id']));
        
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

        // The hand-over to the admin is the most important part: it is recorded right after the status, before anything
        // that could fail (files, notifications).
        if ($submitting) {
            $intervention->update(['submitted_at' => now(), 'submitted_by' => $actor?->id]);
        } elseif ($intervention->submitted_at && $actor?->hasPermission('interventions.reopen')
            && ($request->has('save_mode') || array_key_exists('status', $validated))) {
            $intervention->update(['submitted_at' => null, 'submitted_by' => null]);
        }

        // From here the save has happened: remember this submission, so a retry of it (the answer was lost) is answered
        // "done" instead of being refused by the completed-lock.
        if ($submissionKey) {
            \Illuminate\Support\Facades\Cache::put($submissionKey, true, now()->addDay());
        }

        // Everything below is best effort: it is logged when it fails, but the save has happened and is reported as done.
        $warnings = [];

        // Notify Syndic about Status Update
        if (isset($updateData['status']) && $updateData['status'] !== $oldStatus && $intervention->syndic_id) {
            $this->bestEffort(function () use ($intervention, $updateData) {
                $syndic = User::find($intervention->syndic_id);
                if ($syndic) {
                    $newStatus = $updateData['status'];
                    $this->pushNotificationService->notifyUser(
                        $syndic,
                        'intervention_update',
                        fn (string $locale) => [
                            'title' => \App\Support\MessageText::field($intervention, 'title', $locale),
                            'status' => \App\Support\MessageText::word('status', $newStatus, $locale),
                        ],
                        ['type' => 'intervention', 'intervention_id' => $intervention->id],
                        'intervention'
                    );
                }
            }, 'syndic notification', $warnings);
        }

        // Record the assignment history and notify the newly assigned user
        if (array_key_exists('pro_id', $updateData) && $updateData['pro_id'] != $oldProId) {
            $this->bestEffort(function () use ($intervention, $updateData) {
                $missionId = Assignment::where('intervention_id', $intervention->id)->whereNotNull('mission_id')->value('mission_id');
                Assignment::record($intervention->id, $missionId, $updateData['pro_id'] ? (int) $updateData['pro_id'] : null, auth('sanctum')->id());

                if ($updateData['pro_id']) {
                    $this->notifyAssignedUser(User::find($updateData['pro_id']), $intervention);
                }
            }, 'assignment history', $warnings);
        }

        // Uploads: a technician's bad file is skipped and reported; each file is stored on its own so one failure
        // does not lose the others.
        $photoFiles = $request->file('photos') ?? [];
        $documentFiles = $request->file('files') ?? [];
        $skippedFiles = [];
        if ($lenientFiles) {
            [$photoFiles, $documentFiles, $skippedFiles] = $this->acceptableUploads($request);
        }
        foreach ([['photos', (array) $photoFiles], ['documents', (array) $documentFiles]] as [$folder, $uploads]) {
            foreach ($uploads as $file) {
                $this->bestEffort(function () use ($intervention, $file, $folder) {
                    $path = $file->store($folder, 'public');
                    $intervention->documents()->create([
                        'file_path' => $path,
                        'file_name' => $file->getClientOriginalName(),
                        'file_type' => $file->getClientMimeType(),
                    ]);
                }, 'file ' . $file->getClientOriginalName(), $warnings);
            }
        }
        foreach ($skippedFiles as $name) {
            $warnings[] = 'file ' . $name;
        }

        if ($submitting) {
            $this->bestEffort(fn () => $this->notifyReviewers($intervention->fresh(), $actor), 'notification to the admins', $warnings);
        }

        // "Save & send e-mail": the report goes out right after the save (the phone only sends
        // save_mode=EMAIL; the website calls send-report itself). A mail problem never undoes the save:
        // the answer says who received the report and who did not.
        $report = null;
        if ($request->input('save_mode') === 'EMAIL') {
            $report = app(\App\Services\InterventionReportService::class)
                ->send($intervention->fresh()->load(['building.syndic', 'syndic', 'professional', 'documents']));
        }

        return response()->json([
            'message' => __('Intervention updated successfully'),
            'intervention' => $intervention->fresh()->load(['documents', 'building', 'professional', 'syndic', 'submitter:id,name']),
            'report' => $report,
            'submitted' => $submitting,
            'warnings' => $warnings,
        ]);
    }

    /** Tells the admins (everyone who may reopen / review interventions) that a technician sent work for review. */
    protected function notifyReviewers(Intervention $intervention, ?User $technician): void
    {
        foreach (User::withPermission('interventions.reopen')->staff()->get() as $reviewer) {
            if ($technician && $reviewer->id === $technician->id) {
                continue;
            }
            $this->pushNotificationService->notifyUser(
                $reviewer,
                'intervention_submitted',
                fn (string $locale) => [
                    'technician' => $technician?->name ?? '',
                    'title' => \App\Support\MessageText::field($intervention, 'title', $locale),
                    'status' => \App\Support\MessageText::word('status', $intervention->status, $locale),
                ],
                ['type' => 'intervention', 'intervention_id' => $intervention->id, 'important' => '1'],
                'intervention',
                true
            );
        }
    }

    protected function notifyAssignedUser(?User $user, Intervention $intervention): void
    {
        if (!$user) {
            return;
        }

        $this->pushNotificationService->notifyUser(
            $user,
            'new_assignment',
            fn (string $locale) => ['title' => \App\Support\MessageText::field($intervention, 'title', $locale)],
            ['type' => 'intervention', 'intervention_id' => $intervention->id],
            'intervention'
        );
    }

    public function sendReport($id, \App\Services\InterventionReportService $reports)
    {
        try {
            $intervention = Intervention::with(['building.syndic', 'syndic', 'professional', 'documents'])->findOrFail($id);
            $result = $reports->send($intervention);

            if (empty($result['sent'])) {
                return response()->json([
                    'message' => __('Failed to send report'),
                    'error' => $result['failed'][0]['error'] ?? __('Unknown error'),
                    'failed' => $result['failed'],
                ], 500);
            }

            return response()->json([
                'message' => __('Report sent successfully'),
                'recipients' => $result['sent'],
                'failed' => $result['failed'],
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Email sending failure: " . $e->getMessage());
            return response()->json([
                'message' => __('Failed to send report'),
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
