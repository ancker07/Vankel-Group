<?php

namespace App\Http\Controllers;

use App\Models\Email;
use Illuminate\Http\Request;
use Webklex\IMAP\Facades\Client;
use Illuminate\Support\Facades\Storage;

class EmailController extends Controller
{
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
            $output = \Illuminate\Support\Facades\Artisan::output();
            
            return response()->json([
                'message' => 'Email synchronization completed.',
                'output' => $output
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to sync emails: ' . $e->getMessage()
            ], 500);
        }
    }
}
