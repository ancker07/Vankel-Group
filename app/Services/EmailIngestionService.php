<?php

namespace App\Services;

use App\Models\Email;
use App\Models\Building;
use App\Models\Mission;
use App\Models\Syndic;
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
            // Build content string with clear structure for AI
            $content = "=== EMAIL METADATA ===\n";
            $content .= "From: {$email->from_address}\n";
            $content .= "Subject: {$email->subject}\n";
            $content .= "Date: {$email->received_at}\n\n";
            $content .= "=== EMAIL BODY ===\n{$email->body_text}\n";

            $attachmentsForAi = [];
            
            foreach ($email->attachments as $attachment) {
                // Prepare for AI if it's an image or PDF
                if (str_starts_with($attachment->mime_type ?? '', 'image/') || ($attachment->mime_type ?? '') === 'application/pdf') {
                    $filePath = storage_path('app/public/' . $attachment->file_path);
                    if (file_exists($filePath)) {
                        $attachmentsForAi[] = [
                            'name' => $attachment->file_name,
                            'mime_type' => $attachment->mime_type,
                            'data' => base64_encode(file_get_contents($filePath))
                        ];
                        $content .= "\n[ATTACHMENT: {$attachment->file_name} — READ ALL TEXT, TABLES, AND DATA FROM THIS DOCUMENT]\n";
                    }
                } else {
                    $content .= "\nAttachment (non-readable): {$attachment->file_name}\n";
                }
            }

            $aiData = $this->aiService->extractEmailData($content, $attachmentsForAi);

            if ($aiData['classification'] === 'NON_MISSION') {
                $email->update([
                    'ingested_at' => now(),
                    'ingestion_status' => 'IGNORED',
                    'ingestion_reason' => $aiData['reasons'][0] ?? 'Classified as non-mission'
                ]);
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

                if (!$building && ($aiData['classification'] === 'MISSION' || $aiData['classification'] === 'NEEDS_REVIEW')) {
                     $aiData['classification'] = 'NEEDS_REVIEW';
                }

                // ========= SYNDIC MATCHING =========
                $syndicId = null;
                $extractedSyndicName = $missionData['syndicName'] ?? null;

                if ($extractedSyndicName) {
                    $syndicId = $this->matchSyndic($extractedSyndicName);
                }

                // Fallback: use building's syndic if no AI match
                if (!$syndicId && $building && $building->syndic_id) {
                    $syndicId = $building->syndic_id;
                }

                // If we matched a syndic AND created/found a building without one, link them
                if ($syndicId && $building && !$building->syndic_id) {
                    $building->update(['syndic_id' => $syndicId]);
                }

                $mission = null;
                if ($aiData['classification'] === 'MISSION' || $aiData['classification'] === 'NEEDS_REVIEW') {
                    $mission = Mission::create([
                        'building_id' => $building ? $building->id : null,
                        'syndic_id' => $syndicId,
                        'extracted_address' => $building ? null : $rawAddress,
                        'requested_by' => 'SYNDIC',
                        'title' => $missionData['title'] ?? $email->subject,
                        'description' => $missionData['description'] ?? $email->body_text,
                        'sector' => $missionData['sector'] ?? 'GENERAL',
                        'urgency' => $missionData['urgency'] ?? 'MEDIUM',
                        'status' => ($aiData['classification'] === 'MISSION' && $building) ? 'PENDING' : 'NEEDS_REVIEW',
                        'source_type' => 'EMAIL',
                        'source_message_id' => $email->message_id,
                        'reference' => $missionData['reference'] ?? null,
                        'on_site_contact_name' => $missionData['contactOnSite']['name'] ?? null,
                        'on_site_contact_phone' => $missionData['contactOnSite']['phone'] ?? null,
                        'on_site_contact_email' => $missionData['contactOnSite']['email'] ?? null,
                    ]);

                    // Link attachments to mission as documents
                    foreach ($email->attachments as $attachment) {
                        $mission->documents()->create([
                            'file_path' => $attachment->file_path,
                            'file_name' => $attachment->file_name,
                            'file_type' => $attachment->mime_type,
                        ]);
                    }
                }

                $status = $mission ? 'PROCESSED' : ($aiData['classification'] === 'NEEDS_REVIEW' ? 'NEEDS_REVIEW' : 'IGNORED');
                
                $email->update([
                    'ingested_at' => now(),
                    'ingestion_status' => $status,
                    'ingestion_reason' => $aiData['reasons'][0] ?? null,
                    'extracted_data' => $aiData
                ]);

                return [
                    'success' => true,
                    'status' => $status,
                    'mission_id' => $mission ? $mission->id : null,
                    'building_id' => $building ? $building->id : null,
                    'syndic_id' => $syndicId,
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

    /**
     * Match an extracted syndic name to an existing syndic in the database.
     */
    protected function matchSyndic(string $name): ?int
    {
        $normalized = strtolower(trim($name));
        
        if (strlen($normalized) < 2) {
            return null;
        }

        // Try exact match first
        $syndic = Syndic::whereRaw('LOWER(company_name) = ?', [$normalized])->first();
        
        if ($syndic) {
            return $syndic->id;
        }

        // Try fuzzy match (contains)
        $syndic = Syndic::whereRaw('LOWER(company_name) LIKE ?', ["%{$normalized}%"])->first();
        
        if ($syndic) {
            return $syndic->id;
        }

        // Try reverse: syndic name contains the extracted name
        $syndics = Syndic::all();
        foreach ($syndics as $s) {
            if (str_contains(strtolower($s->company_name), $normalized) || str_contains($normalized, strtolower($s->company_name))) {
                return $s->id;
            }
        }

        return null;
    }

    protected function findOrCreateBuilding(array $addressData)
    {
        $raw = $addressData['raw'];
        $normalizedRaw = strtolower(preg_replace('/[^a-z0-9\s]/i', '', $raw));
        
        // Try normalized match against existing buildings
        $buildings = Building::all();
        foreach ($buildings as $b) {
            $normalizedExisting = strtolower(preg_replace('/[^a-z0-9\s]/i', '', $b->address));
            if ($normalizedExisting === $normalizedRaw || str_contains($normalizedExisting, $normalizedRaw) || str_contains($normalizedRaw, $normalizedExisting)) {
                return $b;
            }
        }

        // Try matching by street and number separately
        if (!empty($addressData['street']) && !empty($addressData['number'])) {
            $building = Building::where('address', 'LIKE', "%{$addressData['street']}%")
                                ->where('address', 'LIKE', "%{$addressData['number']}%")
                                ->first();
            if ($building) return $building;
        }

        // Create new building if we have enough data
        if (!empty($addressData['street']) && !empty($addressData['number'])) {
            $building = Building::create([
                'address' => $raw,
                'city' => $addressData['city'] ?? null,
                'admin_note' => 'Automatically created from email ingestion.',
            ]);
            return $building;
        }

        return null;
    }
}

