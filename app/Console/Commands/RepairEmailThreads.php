<?php

namespace App\Console\Commands;

use App\Models\Email;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RepairEmailThreads extends Command
{
    protected $signature = 'emails:repair-threads';
    protected $description = 'Backfill thread_id for existing emails';

    public function handle()
    {
        $this->info('Starting email thread repair...');

        // 1. First, assign thread_id = message_id to all emails that have none
        // This ensures every email has a thread_id starter
        DB::table('emails')->whereNull('thread_id')->update([
            'thread_id' => DB::raw('message_id')
        ]);

        $emails = Email::orderBy('received_at', 'asc')->get();
        $this->info("Processing {$emails->count()} emails...");

        foreach ($emails as $email) {
            $newThreadId = null;

            // Clean In-Reply-To
            $cleanInReplyTo = $email->in_reply_to ? trim($email->in_reply_to, '<>') : null;

            if ($cleanInReplyTo) {
                $parent = Email::where('message_id', $cleanInReplyTo)->first();
                if ($parent) {
                    $newThreadId = $parent->thread_id;
                }
            }

            if (!$newThreadId && $email->references) {
                $refIds = preg_split('/\s+/', $email->references);
                foreach ($refIds as $refId) {
                    $cleanRefId = trim($refId, '<>');
                    if (!$cleanRefId) continue;
                    
                    $refEmail = Email::where('message_id', $cleanRefId)->first();
                    if ($refEmail) {
                        $newThreadId = $refEmail->thread_id;
                        break;
                    }
                }
            }

            // Fallback: Subject-based threading for emails with similar subjects within 7 days
            if (!$newThreadId) {
                $cleanSubject = preg_replace('/^(Re|Fwd|Aw|Tr):/i', '', $email->subject);
                $cleanSubject = trim($cleanSubject);

                if ($cleanSubject) {
                    $potentialParent = Email::where('id', '!=', $email->id)
                        ->where('subject', 'LIKE', '%' . $cleanSubject . '%')
                        ->where('received_at', '<', $email->received_at)
                        ->where('received_at', '>', $email->received_at->subDays(7))
                        ->orderBy('received_at', 'asc')
                        ->first();
                    
                    if ($potentialParent) {
                        $newThreadId = $potentialParent->thread_id;
                    }
                }
            }

            if ($newThreadId && $newThreadId !== $email->thread_id) {
                $email->update(['thread_id' => $newThreadId]);
                $this->line("Updated Email #{$email->id} to Thread: {$newThreadId}");
            }
        }

        $this->info('Repair complete!');
    }
}
