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
            // ========= THREAD / CONVERSATION DETECTION =========
            $conversation = $email->getConversation();
            $isThread = $conversation->count() > 1;

            // If this email is part of a thread, check for existing processing
            if ($isThread) {
                // Check if any thread email was DEFERRED — if so, re-process the FULL thread
                $deferredInThread = $conversation->where('id', '!=', $email->id)
                    ->where('ingestion_status', 'DEFERRED')
                    ->first();

                if ($deferredInThread) {
                    // Clear deferred status so the full thread gets re-analyzed
                    foreach ($conversation as $e) {
                        if ($e->ingestion_status === 'DEFERRED') {
                            $e->update([
                                'ingested_at' => null,
                                'ingestion_status' => 'PENDING',
                                'ingestion_reason' => 'Re-processing: new message arrived in thread'
                            ]);
                        }
                    }
                    // Refresh the conversation after clearing
                    $conversation = $email->getConversation();
                }

                // Skip if thread was already fully processed (not deferred)
                $alreadyProcessed = $conversation->where('id', '!=', $email->id)
                    ->whereNotNull('ingested_at')
                    ->whereIn('ingestion_status', ['PROCESSED', 'IGNORED', 'SKIPPED'])
                    ->first();

                if ($alreadyProcessed) {
                    $email->update([
                        'ingested_at' => now(),
                        'ingestion_status' => 'SKIPPED',
                        'ingestion_reason' => "Thread already processed via email #{$alreadyProcessed->id}"
                    ]);
                    return [
                        'success' => true,
                        'status' => 'SKIPPED',
                        'message' => "Thread already processed via email #{$alreadyProcessed->id}"
                    ];
                }
            }

            // ========= AUTO-EXPIRE OLD DEFERRED EMAILS =========
            $forceProcess = false;
            if ($email->ingestion_status === 'DEFERRED' && $email->updated_at) {
                $hoursSinceDeferred = now()->diffInHours($email->updated_at);
                if ($hoursSinceDeferred >= 48) {
                    $forceProcess = true;
                    Log::info("Force-processing deferred email #{$email->id} (deferred for {$hoursSinceDeferred}h)");
                }
            }

            // ========= BUILD CONTENT FOR AI =========
            $content = '';
            $attachmentsForAi = [];

            if ($isThread) {
                $content .= "=== CONVERSATION THREAD ({$conversation->count()} messages) ===\n";
                $content .= "⚠️ This email is part of a conversation. Read ALL messages below in order to understand the full context.\n\n";

                $messageNum = 0;
                foreach ($conversation as $threadEmail) {
                    $messageNum++;
                    $content .= "--- [Message {$messageNum} of {$conversation->count()}] ---\n";
                    $content .= "From: {$threadEmail->from_address}\n";
                    $content .= "Subject: {$threadEmail->subject}\n";
                    $content .= "Date: {$threadEmail->received_at}\n";
                    $content .= "Body:\n{$threadEmail->body_text}\n\n";

                    foreach ($threadEmail->attachments as $attachment) {
                        if (str_starts_with($attachment->mime_type ?? '', 'image/') || ($attachment->mime_type ?? '') === 'application/pdf') {
                            $filePath = storage_path('app/public/' . $attachment->file_path);
                            if (file_exists($filePath)) {
                                $attachmentsForAi[] = [
                                    'name' => $attachment->file_name,
                                    'mime_type' => $attachment->mime_type,
                                    'data' => base64_encode(file_get_contents($filePath))
                                ];
                                $content .= "[ATTACHMENT from Message {$messageNum}: {$attachment->file_name} — READ ALL TEXT, TABLES, AND DATA FROM THIS DOCUMENT]\n";
                            }
                        } else {
                            $content .= "Attachment (non-readable) from Message {$messageNum}: {$attachment->file_name}\n";
                        }
                    }
                    $content .= "\n";
                }

                $content .= "=== END OF CONVERSATION THREAD ===\n";
                $content .= "Based on the COMPLETE conversation above, determine if this thread represents a mission request and extract all relevant data.\n";
            } else {
                $content .= "=== SINGLE EMAIL (Not part of a thread) ===\n";
                $content .= "From: {$email->from_address}\n";
                $content .= "Subject: {$email->subject}\n";
                $content .= "Date: {$email->received_at}\n\n";
                $content .= "=== EMAIL BODY ===\n{$email->body_text}\n";

                foreach ($email->attachments as $attachment) {
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
            }

            $aiData = $this->aiService->extractEmailData($content, $attachmentsForAi);

            // ========= HANDLE AWAITING_CONTEXT (DEFER) =========
            if ($aiData['classification'] === 'AWAITING_CONTEXT' && !$forceProcess) {
                $email->update([
                    'ingestion_status' => 'DEFERRED',
                    'ingestion_reason' => $aiData['reasons'][0] ?? 'Awaiting more context from conversation',
                    'extracted_data' => $aiData
                ]);
                Log::info("Email #{$email->id} deferred: awaiting context. Reason: " . ($aiData['reasons'][0] ?? 'N/A'));
                return [
                    'success' => true,
                    'status' => 'DEFERRED',
                    'reason' => $aiData['reasons'][0] ?? 'Awaiting more context'
                ];
            }

            // If AI said AWAITING_CONTEXT but we're force-processing, treat as NEEDS_REVIEW
            if ($aiData['classification'] === 'AWAITING_CONTEXT' && $forceProcess) {
                $aiData['classification'] = 'NEEDS_REVIEW';
                $aiData['reasons'][] = 'Auto-escalated from DEFERRED after 48h timeout';
            }

            if ($aiData['classification'] === 'NON_MISSION') {
                $emailsToMark = $isThread ? $conversation : collect([$email]);
                foreach ($emailsToMark as $e) {
                    if (!$e->ingested_at) {
                        $e->update([
                            'ingested_at' => now(),
                            'ingestion_status' => 'IGNORED',
                            'ingestion_reason' => $aiData['reasons'][0] ?? 'Classified as non-mission'
                        ]);
                    }
                }
                return [
                    'success' => true,
                    'status' => 'IGNORED',
                    'reason' => $aiData['reasons'][0] ?? 'Classified as non-mission'
                ];
            }

            return DB::transaction(function () use ($email, $aiData, $isThread, $conversation) {
                $missionData = $aiData['mission'] ?? [];
                $rawAddress = $missionData['address']['raw'] ?? null;
                
                $building = null;
                if ($rawAddress) {
                    $building = $this->findOrCreateBuilding($missionData['address']);
                }

                if (!$building && ($aiData['classification'] === 'MISSION' || $aiData['classification'] === 'NEEDS_REVIEW')) {
                     $aiData['classification'] = 'NEEDS_REVIEW';
                }

                // ========= SYNDIC MATCHING & CONFLICT RESOLUTION =========
                $syndicId = null;
                $extractedSyndicName = null;
                
                $syndicFromBody = $missionData['syndicFromBody'] ?? null;
                $syndicFromAttachments = $missionData['syndicFromAttachments'] ?? null;

                if ($syndicFromAttachments) {
                    $extractedSyndicName = $syndicFromAttachments;
                } elseif ($syndicFromBody) {
                    $extractedSyndicName = $syndicFromBody;
                }

                if ($extractedSyndicName) {
                    $syndicId = $this->matchSyndic($extractedSyndicName);
                }

                if (!$syndicId && $building && $building->syndic_id) {
                    $syndicId = $building->syndic_id;
                }

                if ($syndicId && $building && !$building->syndic_id) {
                    $building->update(['syndic_id' => $syndicId]);
                }

                $mission = null;
                if ($aiData['classification'] === 'MISSION' || $aiData['classification'] === 'NEEDS_REVIEW') {
                    $title_fr = $missionData['title']['fr'] ?? (is_string($missionData['title'] ?? null) ? $missionData['title'] : $email->subject);
                    $title_en = $missionData['title']['en'] ?? $title_fr;
                    $title_nl = $missionData['title']['nl'] ?? $title_fr;

                    $desc_fr = $missionData['description']['fr'] ?? (is_string($missionData['description'] ?? null) ? $missionData['description'] : $email->body_text);
                    $desc_en = $missionData['description']['en'] ?? $desc_fr;
                    $desc_nl = $missionData['description']['nl'] ?? $desc_fr;

                    $mission = Mission::create([
                        'building_id' => $building ? $building->id : null,
                        'syndic_id' => $syndicId,
                        'extracted_syndic_name' => $extractedSyndicName,
                        'extracted_address' => $building ? null : $rawAddress,
                        'requested_by' => 'SYNDIC',
                        'title' => $title_fr,
                        'title_en' => $title_en,
                        'title_fr' => $title_fr,
                        'title_nl' => $title_nl,
                        'description' => $desc_fr,
                        'description_en' => $desc_en,
                        'description_fr' => $desc_fr,
                        'description_nl' => $desc_nl,
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

                    // Link attachments from ALL thread emails to mission as documents
                    $emailsForAttachments = $isThread ? $conversation : collect([$email]);
                    foreach ($emailsForAttachments as $threadEmail) {
                        foreach ($threadEmail->attachments as $attachment) {
                            $mission->documents()->create([
                                'file_path' => $attachment->file_path,
                                'file_name' => $attachment->file_name,
                                'file_type' => $attachment->mime_type,
                            ]);
                        }
                    }
                }

                $status = $mission ? 'PROCESSED' : ($aiData['classification'] === 'NEEDS_REVIEW' ? 'NEEDS_REVIEW' : 'IGNORED');

                // Mark ALL thread emails as ingested
                $emailsToMark = $isThread ? $conversation : collect([$email]);
                foreach ($emailsToMark as $e) {
                    if (!$e->ingested_at || $e->ingestion_status === 'DEFERRED') {
                        $e->update([
                            'ingested_at' => now(),
                            'ingestion_status' => $status,
                            'ingestion_reason' => $aiData['reasons'][0] ?? null,
                            'extracted_data' => $e->id === $email->id ? $aiData : null
                        ]);
                    }
                }

                return [
                    'success' => true,
                    'status' => $status,
                    'mission_id' => $mission ? $mission->id : null,
                    'building_id' => $building ? $building->id : null,
                    'syndic_id' => $syndicId,
                    'is_thread' => $isThread,
                    'thread_emails_count' => $isThread ? $conversation->count() : 1,
                    'extracted_data' => $aiData
                ];
            });

        } catch (\Exception $e) {
            Log::error("Email Ingestion Error: " . $e->getMessage());
            
            // Mark as error in DB so it shows in UI
            $email->update([
                'ingested_at' => now(),
                'ingestion_status' => 'ERROR',
                'ingestion_reason' => $e->getMessage()
            ]);

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
