<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Webklex\IMAP\Facades\Client;
use App\Models\Email;
use Carbon\Carbon;

class FetchEmails extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'emails:fetch {--loop : Run the command continuously}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Fetch unseen emails via IMAP and save to database';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $loop = $this->option('loop');

        if ($loop) {
            $this->info('Starting continuous email fetching mode (Ctrl+C to stop)...');
            while (true) {
                $this->fetchEmails();
                $this->info('Waiting 15 seconds for next check...');
                sleep(15);
            }
        } else {
            $this->fetchEmails();
        }
    }

    /**
     * Perform the actual email fetching logic.
     */
    protected function fetchEmails()
    {
        $this->info('[' . now()->toDateTimeString() . '] Connecting to mail server...');

        try {
            $client = Client::account('default');
            $client->connect();

            $folders = $client->getFolders();
            $inbox = null;

            foreach ($folders as $folder) {
                if (strtolower($folder->name) === 'inbox') {
                    $inbox = $folder;
                    break;
                }
            }

            if (!$inbox) {
                $this->error('Inbox not found.');
                return;
            }

            $messages = $inbox->query()->unseen()->get();
            
            if ($messages->count() > 0) {
                $this->info('Found ' . $messages->count() . ' new message(s).');

                foreach ($messages as $message) {
                    $messageId = $message->getMessageId() ? (string) $message->getMessageId() : (string) $message->getUid();

                    // Skip if we already saved this email
                    if (Email::where('message_id', $messageId)->exists()) {
                        continue; 
                    }

                    $from = $message->getFrom()[0] ?? null;
                    $to = $message->getTo()[0] ?? null;

                    Email::create([
                        'message_id' => $messageId,
                        'from_address' => $from ? $from->mail : 'unknown',
                        'from_name' => $from ? $from->personal : null,
                        'to_address' => $to ? $to->mail : null,
                        'subject' => clone $message->getSubject() ?: '(No Subject)',
                        'body_text' => $message->getTextBody(),
                        'body_html' => $message->getHTMLBody(),
                        'received_at' => Carbon::parse($message->getDate()),
                    ]);

                    // Mark the message as Read on the server
                    $message->setFlag(['Seen']);
                    $this->info("Saved and marked as seen: " . clone $message->getSubject());
                }
            } else {
                $this->line('No new emails found.');
            }

            // Disconnect to avoid keeping stale connections in long loops
            $client->disconnect();

        } catch (\Exception $e) {
            $this->error('Error fetching emails: ' . $e->getMessage());
            // If in loop mode, don't crash the whole command, just wait and retry
        }
    }
}