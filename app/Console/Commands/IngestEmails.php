<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Email;
use App\Services\EmailIngestionService;

class IngestEmails extends Command
{
    protected $signature = 'emails:ingest';
    protected $description = 'Ingest all pending and deferred emails using AI processing';

    public function handle(EmailIngestionService $ingestionService)
    {
        // Include both un-ingested AND deferred emails
        $emails = Email::where(function ($query) {
            $query->whereNull('ingested_at')
                  ->orWhere('ingestion_status', 'DEFERRED');
        })->with('attachments')->get();
        
        if ($emails->isEmpty()) {
            $this->info('No pending or deferred emails to ingest.');
            return;
        }

        $this->info('Found ' . $emails->count() . ' email(s) to process (pending + deferred).');

        foreach ($emails as $email) {
            // Reload to check if this email was already marked by a thread-mate
            $email->refresh();
            if ($email->ingested_at && $email->ingestion_status !== 'DEFERRED') {
                $this->line(" - Skipping #{$email->id} (already processed by thread)");
                continue;
            }

            $this->info("Ingesting #{$email->id}: {$email->subject}" . ($email->ingestion_status === 'DEFERRED' ? ' [RE-PROCESSING DEFERRED]' : ''));
            $result = $ingestionService->ingest($email);
            
            if ($result['success']) {
                $this->info(" - Result: {$result['status']}");
                if (isset($result['reason'])) {
                    $this->line("   Reason: {$result['reason']}");
                }
            } else {
                $this->error(" - Error: {$result['message']}");
            }
        }

        $this->info('Ingestion process completed.');
    }
}
