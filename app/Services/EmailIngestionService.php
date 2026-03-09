<?php

namespace App\Services;

use App\Models\Email;
use App\Models\Building;
use App\Models\Mission;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class EmailIngestionService
{
    protected $aiService;

    public function __construct(AiService $aiService)
    {
        $this->aiService = $aiService;
    }

    public function ingest(Email $email)
    {
        if ($email->ingested_at) {
            return [
                'success' => true,
                'message' => 'Email already ingested.',
                'status' => 'SKIPPED'
            ];
        }

        try {
            $content = "Subject: {$email->subject}\n\nBody:\n{$email->body_text}\n";
            foreach ($email->attachments as $attachment) {
                $content .= "\nAttachment: {$attachment->file_name}";
            }

            $aiData = $this->aiService->extractEmailData($content);

            if ($aiData['classification'] === 'NON_MISSION') {
                $email->update(['ingested_at' => now()]);
                return [
                    'success' => true,
                    'status' => 'IGNORED',
                    'reason' => $aiData['reasons'][0] ?? 'Classified as non-mission'
                ];
            }

            return DB::transaction(function () use ($email, $aiData) {
                $missionData = $aiData['mission'] ?? [];
                $rawAddress = $missionData['address']['raw'] ?? null;
                
                $building = null;
                if ($rawAddress) {
                    $building = $this->findOrCreateBuilding($missionData['address']);
                }

                if (!$building && $aiData['classification'] === 'MISSION') {
                     // If it's a mission but no building found/created, maybe it needs review
                     $aiData['classification'] = 'NEEDS_REVIEW';
                }

                $mission = null;
                if ($building) {
                    $mission = Mission::create([
                        'building_id' => $building->id,
                        'syndic_id' => $building->syndic_id,
                        'requested_by' => 'SYNDIC', // Defaulting to SYNDIC if from email
                        'title' => $missionData['title'] ?? $email->subject,
                        'description' => $missionData['description'] ?? $email->body_text,
                        'urgency' => 'MEDIUM',
                        'status' => $aiData['classification'] === 'MISSION' ? 'PENDING' : 'NEEDS_REVIEW',
                        'source_type' => 'EMAIL',
                        'source_message_id' => $email->message_id,
                        'reference' => $missionData['reference'] ?? null,
                        'on_site_contact_name' => $missionData['contactOnSite']['name'] ?? null,
                        'on_site_contact_phone' => $missionData['contactOnSite']['phone'] ?? null,
                        'on_site_contact_email' => $missionData['contactOnSite']['email'] ?? null,
                    ]);
                }

                $email->update(['ingested_at' => now()]);

                return [
                    'success' => true,
                    'status' => $mission ? 'PROCESSED' : ($aiData['classification'] === 'NEEDS_REVIEW' ? 'NEEDS_REVIEW' : 'IGNORED'),
                    'mission_id' => $mission ? $mission->id : null,
                    'building_id' => $building ? $building->id : null,
                    'extracted_data' => $aiData
                ];
            });

        } catch (\Exception $e) {
            Log::error("Email Ingestion Error: " . $e->getMessage());
            return [
                'success' => false,
                'status' => 'ERROR',
                'message' => $e->getMessage()
            ];
        }
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
                'admin_note' => 'Automatically created from email ingestion.',
            ]);
        }

        return $building;
    }
}
