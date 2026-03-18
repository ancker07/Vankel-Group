<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Email;
use App\Services\EmailIngestionService;
use Illuminate\Http\Request;
use Webklex\IMAP\Facades\Client;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\DB;
use App\Mail\ReplyEmail;
use Carbon\Carbon;

class EmailController extends Controller
{
    protected $ingestionService;

    public function __construct(EmailIngestionService $ingestionService)
    {
        $this->ingestionService = $ingestionService;
    }

    public function index()
    {
        $user = auth('sanctum')->user();

        // Group by thread_id, falling back to message_id for unique emails
        // Then take the latest message from each group
        $query = Email::with('attachments')
            ->select('emails.*')
            ->join(DB::raw('(SELECT MAX(id) as max_id FROM emails GROUP BY COALESCE(thread_id, message_id)) as latest_emails'), 'emails.id', '=', 'latest_emails.max_id')
            ->orderBy('received_at', 'desc');

        if ($user && $user->role === 'SYNDIC') {
            $query->where(function ($q) use ($user) {
                $q->where('from_address', $user->email)
                  ->orWhere('to_address', 'like', '%' . $user->email . '%');
            });
        }

        $emails = $query->get();

        return response()->json([
            'emails' => $emails
        ]);
    }

    public function show($id)
    {
        $email = Email::with('attachments')->findOrFail($id);
        
        // Use the smarter conversation discovery
        $conversation = $email->getConversation();
        
        // Add the conversation to the email object for the frontend
        $email->thread = $conversation;
        
        return response()->json($email);
    }

    public function getThread($threadId)
    {
        $user = auth('sanctum')->user();

        // First try finding an email that matches this thread_id or message_id
        $query = Email::where(function($q) use ($threadId) {
            $q->where('thread_id', $threadId)
              ->orWhere('message_id', $threadId);
        });

        if ($user && $user->role === 'SYNDIC') {
            $query->where(function ($q) use ($user) {
                $q->where('from_address', $user->email)
                  ->orWhere('to_address', 'like', '%' . $user->email . '%');
            });
        }

        $email = $query->first();

        if (!$email) {
            return response()->json(['emails' => []]);
        }

        $emails = $email->getConversation();
            
        return response()->json([
            'emails' => $emails
        ]);
    }

    public function destroy($id)
    {
        $email = Email::with('attachments')->findOrFail($id);

        try {
            // 1. Delete from IMAP server
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

            if ($inbox) {
                // Search for the message by Message-ID
                $message = $inbox->query()->whereMessageId($email->message_id)->get()->first();
                
                if ($message) {
                    $message->delete(); // This deletes the message on the server
                }
            }
            $client->disconnect();

            // 2. Delete local attachments and files
            foreach ($email->attachments as $attachment) {
                Storage::disk('public')->delete($attachment->file_path);
                $attachment->delete();
            }

            // 3. Delete the email record from DB
            $email->delete();

            return response()->json(['message' => 'Email deleted successfully from local system and server.']);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to delete email: ' . $e->getMessage()
            ], 500);
        }
    }

    public function sync()
    {
        try {
            \Illuminate\Support\Facades\Artisan::call('emails:fetch');
            $this->ingestAll(); // Automatically ingest after fetching
            
            return response()->json([
                'message' => 'Email synchronization and ingestion completed.',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to sync emails: ' . $e->getMessage()
            ], 500);
        }
    }

    public function ingest($id)
    {
        $email = Email::with('attachments')->findOrFail($id);
        $result = $this->ingestionService->ingest($email);

        if (!$result['success']) {
            return response()->json($result, 500);
        }

        return response()->json($result);
    }

    public function ingestAll()
    {
        // Include both un-ingested AND deferred emails
        $emails = Email::where(function ($query) {
            $query->whereNull('ingested_at')
                  ->orWhere('ingestion_status', 'DEFERRED');
        })->with('attachments')->get();
        $results = [];

        foreach ($emails as $email) {
            // Reload to check if this email was already marked by a thread-mate
            $email->refresh();
            if ($email->ingested_at && $email->ingestion_status !== 'DEFERRED') {
                $results[] = [
                    'email_id' => $email->id,
                    'result' => ['success' => true, 'status' => 'SKIPPED', 'message' => 'Already ingested by thread processing']
                ];
                continue;
            }

            $results[] = [
                'email_id' => $email->id,
                'result' => $this->ingestionService->ingest($email)
            ];
        }

        return response()->json([
            'message' => 'Bulk ingestion processed.',
            'results' => $results
        ]);
    }

    public function reply(Request $request, $id)
    {
        $request->validate([
            'body' => 'required|string',
            'account' => 'required|in:no-reply,redirection',
            'attachments.*' => 'nullable|file|max:10240', // 10MB limit
        ]);

        $email = Email::findOrFail($id);
        
        $subject = str_starts_with(strtolower($email->subject), 're:') 
            ? $email->subject 
            : 'Re: ' . $email->subject;

        // Determine which mailer to use
        $mailerName = ($request->account === 'redirection') ? 'redirection' : 'smtp';
        $fromAddress = ($request->account === 'redirection') 
            ? 'Redirection@vanakelgroup.com' 
            : env('MAIL_FROM_ADDRESS', 'no-reply@vanakelgroup.com');

        try {
            // Build references list (Parent message id + its own references)
            $references = ($email->references ? $email->references . ' ' : '') . '<' . $email->message_id . '>';
            
            // Generate a unique Message-ID for our record
            $sentMessageId = bin2hex(random_bytes(16)) . '@vanakelgroup.com';

            // Handle Attachments
            $attachmentPaths = [];
            $savedAttachments = [];
            if ($request->hasFile('attachments')) {
                foreach ($request->file('attachments') as $file) {
                    $path = $file->store('attachments', 'public');
                    $fullPath = storage_path('app/public/' . $path);
                    $attachmentPaths[] = $fullPath;
                    $savedAttachments[] = [
                        'file_path' => $path,
                        'file_name' => $file->getClientOriginalName(),
                        'file_type' => $file->getClientMimeType(),
                        'file_size' => $file->getSize(),
                    ];
                }
            }

            Mail::mailer($mailerName)->to($email->from_address)->send(
                new ReplyEmail(
                    $request->body, 
                    $subject, 
                    $email->message_id, 
                    $references,
                    $attachmentPaths
                )
            );

            // Save the sent email to our local database so it appears in the thread immediately
            $sentEmail = Email::create([
                'message_id' => $sentMessageId,
                'thread_id' => $email->thread_id ?: $email->message_id,
                'in_reply_to' => $email->message_id,
                'references' => $references,
                'from_address' => $fromAddress,
                'from_name' => 'Vankel Group',
                'to_address' => $email->from_address,
                'subject' => $subject,
                'body_text' => $request->body,
                'body_html' => nl2br(e($request->body)),
                'received_at' => now(),
                'is_read' => true,
                'ingested_at' => now(), // Manual replies are already "processed"
            ]);

            // Save attachments to DB
            foreach ($savedAttachments as $attData) {
                $sentEmail->attachments()->create($attData);
            }

            return response()->json([
                'message' => 'Reply sent successfully from ' . $fromAddress
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to send reply: ' . $e->getMessage()
            ], 500);
        }
    }
}
