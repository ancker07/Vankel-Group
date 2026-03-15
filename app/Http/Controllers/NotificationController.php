<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

use App\Models\NotificationLog;
use App\Models\Notification;

class NotificationController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Get notifications for the authenticated user.
     */
    public function getUserNotifications(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            // If they are calling by email in some cases (mobile app sometimes does this if not using sanctum properly yet)
            if ($request->has('email')) {
                $user = User::where('email', $request->email)->first();
            }
        }

        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        // Get notifications specific to user OR to their role
        $notifications = Notification::where(function($query) use ($user) {
                $query->where('user_id', $user->id)
                      ->orWhere('role', $user->role)
                      ->orWhereNull('user_id')->whereNull('role'); // Global ones
            })
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        return response()->json($notifications);
    }

    /**
     * Mark a notification as read.
     */
    public function markAsRead($id)
    {
        $notification = Notification::findOrFail($id);
        $notification->update(['is_read' => true]);
        return response()->json(['success' => true]);
    }

    /**
     * Mark all notifications as read for the user.
     */
    public function markAllAsRead(Request $request)
    {
        $user = $request->user();
        if (!$user && $request->has('email')) {
            $user = User::where('email', $request->email)->first();
        }

        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        Notification::where('user_id', $user->id)
            ->orWhere('role', $user->role)
            ->update(['is_read' => true]);

        return response()->json(['success' => true]);
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
            $tokens = User::whereNotNull('fcm_token')
                ->where('fcm_token', '!=', '')
                ->pluck('fcm_token')
                ->unique()
                ->toArray();

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

            // Save for dynamic display in app
            Notification::create([
                'title' => $title,
                'body' => $body,
                'type' => 'broadcast',
                'data' => $data,
                'user_id' => null,
                'role' => null, // Global
            ]);

            return response()->json([
                'message' => "Broadcast sent successfully to $successCount out of $totalCount devices.",
                'results' => $results
            ]);
        } else {
            $user_ids = $request->user_ids;
            $tokens = User::whereIn('id', $user_ids)
                ->whereNotNull('fcm_token')
                ->where('fcm_token', '!=', '')
                ->pluck('fcm_token')
                ->unique()
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

            // Save for each user for dynamic display
            foreach ($user_ids as $uid) {
                Notification::create([
                    'user_id' => $uid,
                    'title' => $title,
                    'body' => $body,
                    'type' => 'direct',
                    'data' => $data,
                ]);
            }
            
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
        Log::info("FCM Test Tool: Request received", [
            'token_snippet' => substr($request->token, 0, 15) . '...',
            'title' => $request->title,
            'body' => $request->body
        ]);

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
