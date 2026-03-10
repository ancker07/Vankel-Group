<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Webklex\IMAP\Facades\Client;
use App\Models\Email;
use App\Models\EmailAttachment;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;

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
            $targetFolders = [];
            $blacklist = ['sent', 'trash', 'drafts', 'bin', 'corbeille', 'messages envoyés', 'brouillons'];

            foreach ($folders as $folder) {
                $name = strtolower($folder->name);
                $isBlacklisted = false;
                foreach ($blacklist as $term) {
                    if (str_contains($name, $term)) {
                        $isBlacklisted = true;
                        break;
                    }
                }
                
                if (!$isBlacklisted) {
                    $targetFolders[] = $folder;
                }
            }

            if (empty($targetFolders)) {
                $this->error('No suitable mail folders (Inbox/Junk) found.');
                return;
            }

            foreach ($targetFolders as $folder) {
                $this->info("Scanning folder: {$folder->name}");
                $messages = $folder->query()->unseen()->get();
                
                if ($messages->count() > 0) {
                    $this->info('Found ' . $messages->count() . ' new message(s) in ' . $folder->name);

                    foreach ($messages as $message) {
                    $messageId = $message->getMessageId() ? (string) $message->getMessageId() : (string) $message->getUid();

                    // Skip if we already saved this email
                    if (Email::where('message_id', $messageId)->exists()) {
                        continue; 
                    }

                    $from = $message->getFrom()[0] ?? null;
                    $to = $message->getTo()[0] ?? null;

                    $email = Email::create([
                        'message_id' => $messageId,
                        'from_address' => $from ? $from->mail : 'unknown',
                        'from_name' => $from ? $from->personal : null,
                        'to_address' => $to ? $to->mail : null,
                        'subject' => $message->getSubject() ?: '(No Subject)',
                        'body_text' => $message->getTextBody(),
                        'body_html' => $message->getHTMLBody(),
                        'received_at' => Carbon::parse($message->getDate()),
                    ]);

                    // Handle Attachments
                    if ($message->hasAttachments()) {
                        $attachments = $message->getAttachments();
                        $this->info("Found " . $attachments->count() . " attachment(s) for email " . $email->id);
                        
                        foreach ($attachments as $attachment) {
                            try {
                                $filename = $attachment->getName();
                                $extension = pathinfo($filename, PATHINFO_EXTENSION);
                                $safeFilename = str_replace(' ', '_', pathinfo($filename, PATHINFO_FILENAME)) . '_' . time() . '.' . $extension;
                                $path = 'email_attachments/' . $email->id . '/' . $safeFilename;

                                Storage::disk('public')->put($path, $attachment->getContent());

                                EmailAttachment::create([
                                    'email_id' => $email->id,
                                    'file_name' => $filename,
                                    'file_path' => $path,
                                    'mime_type' => $attachment->getMimeType(),
                                    'file_size' => $attachment->getSize()
                                ]);
                                $this->info(" - Saved attachment: " . $filename);
                            } catch (\Exception $attError) {
                                $this->error(" - Failed to save attachment: " . $attError->getMessage());
                            }
                        }
                    } else {
                        $this->info("No attachments found for email " . $email->id);
                    }

                    // Mark the message as Read on the server
                    $message->setFlag(['Seen']);
                    $this->info("Saved and marked as seen: " . $message->getSubject());
                }
            } else {
                $this->line("No new emails found in {$folder->name}.");
            }
        }

            // Disconnect to avoid keeping stale connections in long loops
            $client->disconnect();

        } catch (\Exception $e) {
            $this->error('Error fetching emails: ' . $e->getMessage());
            // If in loop mode, don't crash the whole command, just wait and retry
        }
    }
}