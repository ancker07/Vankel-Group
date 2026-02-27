<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\Document;
use App\Models\Syndic;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class InterventionController extends Controller
{
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

        if ($type === 'mission') {
            $entity = Mission::create([
                'building_id' => $building->id,
                'syndic_id' => $validated['syndicId'] ?? null,
                'requested_by' => $validated['role'],
                'title' => $validated['title'],
                'description' => $validated['description'],
                'urgency' => $validated['urgency'],
                'status' => 'PENDING',
                'category' => $validated['sector'] ?? 'GENERAL',
                'sector' => $validated['sector'] ?? 'GENERAL',
                'on_site_contact_name' => $validated['onSiteContactName'] ?? null,
                'on_site_contact_phone' => $validated['onSiteContactPhone'] ?? null,
                'on_site_contact_email' => $validated['onSiteContactEmail'] ?? null,
            ]);
        } else {
            $entity = Intervention::create([
                'building_id' => $building->id,
                'syndic_id' => $validated['syndicId'] ?? null,
                'title' => $validated['title'],
                'description' => $validated['description'],
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
        return response()->json(Mission::with('documents')->get());
    }

    public function getInterventions()
    {
        return response()->json(Intervention::with('documents')->get());
    }

    public function approveMission(Request $request, $id)
    {
        $mission = Mission::findOrFail($id);
        $mission->update(['status' => 'APPROVED']);

        // Create an Intervention based on the mission
        $intervention = Intervention::create([
            'building_id' => $mission->building_id,
            'syndic_id' => $mission->syndic_id,
            'title' => $mission->title ?? 'Approved Mission',
            'category' => $mission->category,
            'sector' => $mission->sector,
            'description' => $mission->description,
            'urgency' => $mission->urgency,
            'status' => 'PENDING',
            'on_site_contact_name' => $mission->on_site_contact_name,
            'on_site_contact_phone' => $mission->on_site_contact_phone,
            'on_site_contact_email' => $mission->on_site_contact_email,
        ]);

        return response()->json([
            'message' => 'Mission approved successfully',
            'mission' => $mission,
            'intervention' => $intervention->load('documents')
        ]);
    }

    public function rejectMission($id)
    {
        $mission = Mission::findOrFail($id);
        $mission->update(['status' => 'REJECTED']);

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
        ]);

        $intervention->update($validated);

        return response()->json([
            'message' => 'Intervention updated successfully',
            'intervention' => $intervention->load('documents')
        ]);
    }

    public function sendReport($id)
    {
        try {
            $intervention = Intervention::with(['building.syndic', 'syndic', 'professional', 'documents'])->findOrFail($id);
            
            $recipients = ['admin@vanakelgroup.com'];
            
            if ($intervention->on_site_contact_email) {
                $recipients[] = $intervention->on_site_contact_email;
            }
            
            // Prioritize the requesting syndic if explicitly linked
            if ($intervention->syndic && $intervention->syndic->email) {
                $recipients[] = $intervention->syndic->email;
            } elseif ($intervention->building->syndic && $intervention->building->syndic->email) {
                // Fallback to building's default syndic
                $recipients[] = $intervention->building->syndic->email;
            }
            
            if ($intervention->professional && $intervention->professional->email) {
                $recipients[] = $intervention->professional->email;
            }
            
            // Filter unique emails and valid ones
            $recipients = array_unique(array_filter($recipients));

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


