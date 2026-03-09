<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Email;
use App\Services\EmailIngestionService;
use Illuminate\Http\Request;
use Webklex\IMAP\Facades\Client;
use Illuminate\Support\Facades\Storage;

class EmailController extends Controller
{
    protected $ingestionService;

    public function __construct(EmailIngestionService $ingestionService)
    {
        $this->ingestionService = $ingestionService;
    }

    public function index()
    {
        return response()->json([
            'emails' => Email::with('attachments')->orderBy('received_at', 'desc')->get()
        ]);
    }

    public function show($id)
    {
        $email = Email::with('attachments')->findOrFail($id);
        return response()->json($email);
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
        $emails = Email::whereNull('ingested_at')->with('attachments')->get();
        $results = [];

        foreach ($emails as $email) {
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
}
