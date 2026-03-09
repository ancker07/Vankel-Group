<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class IngestEmails extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'emails:ingest';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Ingest all pending emails using AI processing';

    /**
     * Execute the console command.
     */
    public function handle(\App\Services\EmailIngestionService $ingestionService)
    {
        $emails = \App\Models\Email::whereNull('ingested_at')->get();
        
        if ($emails->isEmpty()) {
            $this->info('No pending emails to ingest.');
            return;
        }

        $this->info('Found ' . $emails->count() . ' pending email(s).');

        foreach ($emails as $email) {
            $this->info('Ingesting: ' . $email->subject);
            $result = $ingestionService->ingest($email);
            
            if ($result['success']) {
                $this->info(' - Result: ' . $result['status']);
            } else {
                $this->error(' - Error: ' . $result['message']);
            }
        }

        $this->info('Ingestion process completed.');
    }
}
