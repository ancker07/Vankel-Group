<?php

namespace App\Http\Controllers;

use App\Models\Contact;
use App\Models\Mission;
use App\Models\Building;
use App\Services\AiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ContactController extends Controller
{
    protected $aiService;

    public function __construct(AiService $aiService)
    {
        $this->aiService = $aiService;
    }

    public function index()
    {
        return response()->json(Contact::with('mission')->latest()->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string',
            'email' => 'required|email',
            'subject' => 'nullable|string',
            'message' => 'required|string',
        ]);

        try {
            return DB::transaction(function () use ($validated) {
                // 1. Create the Contact record
                $contact = Contact::create($validated);

                // 2. Analyze with AI (simulating extraction logic like email)
                $content = "From: {$validated['name']} ({$validated['email']})\nSubject: {$validated['subject']}\n\nMessage:\n{$validated['message']}";
                $aiData = $this->aiService->extractEmailData($content);

                $contact->update([
                    'extracted_data' => $aiData
                ]);

                // 3. Create Mission if relevant
                if ($aiData['classification'] === 'MISSION' || $aiData['classification'] === 'NEEDS_REVIEW') {
                    $missionData = $aiData['mission'] ?? [];
                    $rawAddress = $missionData['address']['raw'] ?? null;

                    $building = null;
                    if ($rawAddress) {
                        $building = $this->findOrCreateBuilding($missionData['address']);
                    }

                    $mission = Mission::create([
                        'building_id' => $building ? $building->id : null,
                        'syndic_id' => $building ? $building->syndic_id : null,
                        'extracted_address' => $building ? null : $rawAddress,
                        'requested_by' => 'CONTACT_FORM',
                        'title' => $missionData['title'] ?? ($validated['subject'] ?: 'Contact Form Request'),
                        'description' => $missionData['description'] ?? $validated['message'],
                        'sector' => $missionData['sector'] ?? 'GENERAL',
                        'urgency' => $missionData['urgency'] ?? 'MEDIUM',
                        'status' => ($aiData['classification'] === 'MISSION' && $building) ? 'PENDING' : 'NEEDS_REVIEW',
                        'source_type' => 'CONTACT_FORM',
                        'source_message_id' => (string)$contact->id,
                        'on_site_contact_name' => $missionData['contactOnSite']['name'] ?? $validated['name'],
                        'on_site_contact_phone' => $missionData['contactOnSite']['phone'] ?? null,
                        'on_site_contact_email' => $missionData['contactOnSite']['email'] ?? $validated['email'],
                    ]);

                    $contact->update([
                        'mission_id' => $mission->id,
                        'status' => 'PROCESSED'
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Your message has been sent successfully.',
                    'contact' => $contact->load('mission')
                ]);
            });
        } catch (\Exception $e) {
            Log::error("Contact Form error: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while processing your message.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id)
    {
        $contact = Contact::findOrFail($id);
        $contact->delete();
        return response()->json(['success' => true]);
    }

    protected function findOrCreateBuilding(array $addressData)
    {
        $raw = $addressData['raw'];
        
        // Simple match by address string
        $building = Building::where('address', 'LIKE', "%{$raw}%")->first();
        
        if (!$building && !empty($addressData['street']) && !empty($addressData['number'])) {
            // Try matching by street and number
            $building = Building::where('address', 'LIKE', "%{$addressData['street']}%")
                                ->where('address', 'LIKE', "%{$addressData['number']}%")
                                ->first();
        }

        if (!$building && !empty($addressData['street']) && !empty($addressData['number'])) {
             // Create new building if not found but we have enough info
             $building = Building::create([
                 'address' => $raw,
                 'city' => $addressData['city'] ?? null,
                 'admin_note' => 'Automatically created from Contact Form submission.',
             ]);
        }

        return $building;
    }
}
