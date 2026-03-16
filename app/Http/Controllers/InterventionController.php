<?php

namespace App\Http\Controllers;

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
        $type = $request->input('type', ($validated['role'] === 'SYNDIC' ? 'mission' : 'intervention'));

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

            // Notify Admins about new Mission
            $title = "New Mission: {$entity->title}";
            $body = "Urgency: {$entity->urgency}. Requested by a Syndic.";
            
            $aiService = new \App\Services\AiService();
            $translated = $aiService->translateToFill($title, $body);

            $admins = User::whereIn('role', ['ADMIN', 'SUPERADMIN'])->get();
            foreach ($admins as $admin) {
                if ($admin->fcm_token) {
                    $this->pushNotificationService->sendNotification(
                        $admin->fcm_token,
                        $title,
                        $body
                    );
                }

                Notification::create([
                    'user_id' => $admin->id,
                    'title' => $title,
                    'title_en' => $translated['title']['en'] ?? null,
                    'title_fr' => $translated['title']['fr'] ?? null,
                    'title_nl' => $translated['title']['nl'] ?? null,
                    'body' => $body,
                    'body_en' => $translated['description']['en'] ?? null,
                    'body_fr' => $translated['description']['fr'] ?? null,
                    'body_nl' => $translated['description']['nl'] ?? null,
                    'type' => 'mission',
                    'data' => ['mission_id' => $entity->id]
                ]);
            }
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
                'status' => $validated['status'] ?? 'PENDING',
                'category' => $validated['sector'] ?? 'GENERAL',
                'sector' => $validated['sector'] ?? 'GENERAL',
                'on_site_contact_name' => $validated['onSiteContactName'] ?? null,
                'on_site_contact_phone' => $validated['onSiteContactPhone'] ?? null,
                'on_site_contact_email' => $validated['onSiteContactEmail'] ?? null,
            ]);
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

    public function getMissions()
    {
        $user = auth('sanctum')->user();

        $query = Mission::with(['documents', 'email', 'building', 'syndic'])->latest();

        if ($user && $user->role === 'SYNDIC') {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email)
                  ->orWhereHas('email', function ($emailQuery) use ($user) {
                      $emailQuery->where('from_address', $user->email);
                  });
            });
        }

        return response()->json($query->get());
    }

    public function getMissionById($id)
    {
        $user = auth('sanctum')->user();
        $query = Mission::with(['documents', 'email', 'building']);
        
        if ($user && $user->role === 'SYNDIC') {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email)
                  ->orWhereHas('email', function ($emailQuery) use ($user) {
                      $emailQuery->where('from_address', $user->email);
                  });
            });
        }
        
        $mission = $query->findOrFail($id);
        return response()->json($mission);
    }

    public function getInterventions()
    {
        $user = auth('sanctum')->user();
        
        $query = Intervention::with(['documents', 'building', 'professional', 'syndic']);

        if ($user && $user->role === 'SYNDIC') {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email);
            });
        }

        return response()->json($query->get());
    }

    public function getInterventionById($id)
    {
        $user = auth('sanctum')->user();
        $query = Intervention::with(['documents', 'building', 'professional', 'syndic']);

        if ($user && $user->role === 'SYNDIC') {
            $query->where(function ($q) use ($user) {
                $q->where('syndic_id', $user->id)
                  ->orWhere('on_site_contact_email', $user->email);
            });
        }

        $intervention = $query->findOrFail($id);
        return response()->json($intervention);
    }

    public function approveMission(Request $request, $id)
    {
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

                $mission->update(['status' => 'APPROVED']);

                // 3. Create an Intervention based on the mission
                $intervention = Intervention::create([
                    'building_id' => $buildingId,
                    'syndic_id' => $mission->syndic_id,
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

                // 5. Notify Syndic about Approval
                if ($mission->syndic_id) {
                    // Attempt to find the user linked to this syndic company or using the ID directly
                    $syndic = User::where('id', $mission->syndic_id)
                                 ->orWhere('role', 'SYNDIC') // Fallback if needed, but not ideal
                                 ->first();
                    
                    if ($syndic) {
                        $title = "Mission Approved!";
                        $body = "Your mission '{$mission->title}' has been approved.";

                        if ($syndic->fcm_token) {
                            try {
                                $this->pushNotificationService->sendNotification($syndic->fcm_token, $title, $body);
                            } catch (\Exception $e) {}
                        }

                        Notification::createWithTranslation([
                            'user_id' => $syndic->id,
                            'title' => $title,
                            'body' => $body,
                            'type' => 'intervention',
                            'data' => ['intervention_id' => $intervention->id]
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
            $syndic = User::find($mission->syndic_id);
            if ($syndic) {
                $title = "Mission Rejected";
                $body = "Your mission '{$mission->title}' was unfortunately rejected.";

                if ($syndic->fcm_token) {
                    $this->pushNotificationService->sendNotification($syndic->fcm_token, $title, $body);
                }

                Notification::createWithTranslation([
                    'user_id' => $syndic->id,
                    'title' => $title,
                    'body' => $body,
                    'type' => 'mission',
                    'data' => ['mission_id' => $mission->id]
                ]);
            }
        }

        return response()->json([
            'message' => 'Mission rejected successfully',
            'mission' => $mission
        ]);
    }

    public function updateIntervention(Request $request, $id)
    {
        $intervention = Intervention::findOrFail($id);
        
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

                    if ($syndic->fcm_token) {
                        $this->pushNotificationService->sendNotification($syndic->fcm_token, $title, $body);
                    }

                    Notification::createWithTranslation([
                        'user_id' => $syndic->id,
                        'title' => $title,
                        'body' => $body,
                        'type' => 'intervention',
                        'data' => ['intervention_id' => $intervention->id]
                    ]);
                }
            }
        }

        // Notify Professional about Assignment
        if (isset($updateData['pro_id']) && $updateData['pro_id'] != $intervention->getOriginal('pro_id')) {
            $professional = User::find($updateData['pro_id']);
            if ($professional) {
                $title = "New Assignment";
                $body = "You have been assigned to a new intervention: '{$intervention->title}'.";

                if ($professional->fcm_token) {
                    $this->pushNotificationService->sendNotification($professional->fcm_token, $title, $body);
                }

                Notification::createWithTranslation([
                    'user_id' => $professional->id,
                    'title' => $title,
                    'body' => $body,
                    'type' => 'intervention',
                    'data' => ['intervention_id' => $intervention->id]
                ]);
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


