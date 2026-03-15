<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

use App\Models\NotificationLog;

class NotificationController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Send a notification to all users or specific users.
     */
    public function sendBroadcast(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'target' => 'required|string|in:all,specific',
            'user_ids' => 'required_if:target,specific|array',
            'user_ids.*' => 'exists:users,id',
            'data' => 'nullable|array',
        ]);

        $title = $request->title;
        $body = $request->body;
        $data = $request->data ?? [];

        if ($request->target === 'all') {
            $usersWithTokens = User::whereNotNull('fcm_token')->get();
            $tokens = $usersWithTokens->pluck('fcm_token')->toArray();

            Log::info("FCM: Starting broadcast to " . count($tokens) . " tokens.");
            Log::debug("FCM: Tokens list: " . json_encode($tokens));
            if (empty($tokens)) {
                return response()->json(['message' => 'No users with registered devices found.'], 404);
            }

            $results = $this->notificationService->sendToMultiple($tokens, $title, $body, $data);
            
            $successCount = count(array_filter($results));
            $totalCount = count($tokens);

            NotificationLog::create([
                'title' => $title,
                'body' => $body,
                'target' => 'all',
                'total_recipients' => $totalCount,
                'success_count' => $successCount,
                'data' => $data,
            ]);

            return response()->json([
                'message' => "Broadcast sent successfully to $successCount out of $totalCount devices.",
                'results' => $results
            ]);
        } else {
            $user_ids = $request->user_ids;
            $tokens = User::whereIn('id', $user_ids)
                ->whereNotNull('fcm_token')
                ->pluck('fcm_token')
                ->toArray();

            if (empty($tokens)) {
                return response()->json(['message' => 'Selected users have no registered devices.'], 404);
            }

            $results = $this->notificationService->sendToMultiple($tokens, $title, $body, $data);
            $successCount = count(array_filter($results));

            NotificationLog::create([
                'title' => $title,
                'body' => $body,
                'target' => 'specific',
                'total_recipients' => count($tokens),
                'success_count' => $successCount,
                'data' => $data,
            ]);
            
            return response()->json([
                'message' => 'Notifications sent successfully.',
                'results' => $results
            ]);
        }
    }

    /**
     * Send a test notification to a specific raw token.
     */
    public function sendTestNotification(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'title' => 'required|string',
            'body' => 'required|string',
        ]);

        $result = $this->notificationService->sendNotification(
            $request->token,
            $request->title,
            $request->body
        );

        return response()->json([
            'success' => $result,
            'message' => $result ? 'Test notification sent successfully' : 'Failed to send test notification'
        ]);
    }

    /**
     * Get broadcast history.
     */
    public function getHistory()
    {
        $history = NotificationLog::orderBy('created_at', 'desc')->get();
        return response()->json($history);
    }
}
