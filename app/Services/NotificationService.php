<?php

namespace App\Services;

use App\Models\Mission;
use App\Models\Notification;
use App\Models\User;
use App\Support\MessageText;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class NotificationService
{
    protected string $projectId;
    protected string $serviceAccountPath;

    /** Why the last send failed (for diagnostics, e.g. php artisan push:test). */
    public ?string $lastError = null;

    public function __construct()
    {
        $this->serviceAccountPath = file_exists(base_path('public/vanakelgroup.json'))
            ? base_path('public/vanakelgroup.json')
            : base_path('public/vankelgroup.json');
        
        if (file_exists($this->serviceAccountPath)) {
            $json = json_decode(file_get_contents($this->serviceAccountPath), true);
            $this->projectId = $json['project_id'] ?? 'vanakel-group';
        } else {
            $this->projectId = 'vanakel-group';
        }
    }

    /**
     * Send a push notification to a specific user.
     *
     * @param string $token FCM User Token
     * @param string $title
     * @param string $body
     * @param array $data Additional data
     * @return bool
     */
    public function sendNotification(string $token, string $title, string $body, array $data = [], bool $important = false): bool
    {
        return $this->sendMessage(['token' => $token], $title, $body, $data, $important);
    }

    /**
     * Send a notification to a specific topic (e.g., 'all_users').
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = [], bool $important = false): bool
    {
        return $this->sendMessage(['topic' => $topic], $title, $body, $data, $important);
    }

    /**
     * Send a notification to multiple tokens.
     */
    public function sendToMultiple(array $tokens, string $title, string $body, array $data = [], bool $important = false): array
    {
        $results = [];
        foreach ($tokens as $token) {
            $results[$token] = $this->sendNotification($token, $title, $body, $data, $important);
        }
        return $results;
    }

    /**
     * Push a "new mission" alert to every ADMIN / SUPERADMIN phone and store it in-app.
     * HIGH / URGENT missions are sent as important notifications.
     * Each person gets it in the language they selected (no AI call: it cannot fail).
     */
    public function notifyNewMission(Mission $mission): void
    {
        $important = in_array(strtoupper((string) $mission->urgency), ['HIGH', 'URGENT'], true);
        $data = ['type' => 'mission', 'mission_id' => $mission->id, 'important' => $important ? '1' : '0'];

        // Every staff member whose role can see missions (admins, super admins, …)
        foreach (User::withPermission('missions.view')->staff()->get() as $admin) {
            $this->notifyUser(
                $admin,
                $important ? 'urgent_mission' : 'new_mission',
                fn (string $locale) => [
                    'title' => MessageText::field($mission, 'title', $locale),
                    'urgency' => MessageText::word('urgency', $mission->urgency, $locale),
                    'source' => MessageText::word('source', $mission->source_type === 'EMAIL' ? 'EMAIL' : 'OTHER', $locale),
                ],
                $data,
                'mission',
                $important
            );
        }
    }

    /**
     * Send one fixed message to one user, in THEIR language: a push (if they have a device)
     * and an in-app notification that carries all three languages.
     *
     * @param  array|callable  $params  placeholder values, or fn(string $locale): array
     */
    public function notifyUser(User $user, string $messageKey, array|callable $params, array $data, string $type, bool $important = false): void
    {
        $locale = MessageText::localeFor($user);
        $mine = MessageText::make($messageKey, $locale, $params);

        if ($user->fcm_token) {
            try {
                $this->sendNotification($user->fcm_token, $mine['title'], $mine['body'], $data, $important);
            } catch (\Exception $e) {
                Log::error("FCM: '{$messageKey}' push failed for user {$user->id}: " . $e->getMessage());
            }
        }

        $all = MessageText::all($messageKey, $params);
        Notification::create([
            'user_id' => $user->id,
            'title' => $mine['title'],
            'title_en' => $all['en']['title'],
            'title_fr' => $all['fr']['title'],
            'title_nl' => $all['nl']['title'],
            'body' => $mine['body'],
            'body_en' => $all['en']['body'],
            'body_fr' => $all['fr']['body'],
            'body_nl' => $all['nl']['body'],
            'type' => $type,
            'data' => $data,
        ]);
    }

    /**
     * Pick the translated string for a user's saved locale, falling back to
     * the original (untranslated) string when there is no translation or
     * saved locale.
     *
     * @param array $translated ['en' => ..., 'fr' => ..., 'nl' => ...]
     */
    public static function localize(array $translated, ?string $locale, string $fallback): string
    {
        return $translated[$locale] ?? $fallback;
    }

    /**
     * Shared logic for sending messages.
     * Important messages use max priority on Android and "time-sensitive" on iOS.
     */
    protected function sendMessage(array $target, string $title, string $body, array $data = [], bool $important = false): bool
    {
        $accessToken = $this->getAccessToken();
        if (!$accessToken) {
            $this->lastError = 'Could not get a Google access token (service-account file missing, unreadable or invalid).';
            Log::error('FCM: Could not get access token. Make sure storage/app/firebase-auth.json exists and is valid.');
            return false;
        }

        $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

        $message = [
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'high_importance_channel',
                    'sound' => 'default',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'content-available' => 1,
                        'sound' => 'default',
                    ],
                ],
            ],
        ];

        if ($important) {
            $message['android']['notification']['notification_priority'] = 'PRIORITY_MAX';
            $message['android']['notification']['default_vibrate_timings'] = true;
            $message['apns']['headers'] = ['apns-priority' => '10'];
            $message['apns']['payload']['aps']['interruption-level'] = 'time-sensitive';
            $data['important'] = '1';
        }

        if (!empty($data)) {
            $message['data'] = array_map('strval', $data);
        }

        // Add target (token, topic, or condition)
        $message = array_merge($message, $target);

        $response = Http::withToken($accessToken)
            ->post($url, ['message' => $message]);

        if ($response->successful()) {
            Log::info('FCM: Notification sent successfully to target: ' . json_encode($target));
            return true;
        }

        // Token no longer valid (app uninstalled / reinstalled): stop sending to it
        if (isset($target['token']) && ($response->status() === 404 || str_contains($response->body(), 'UNREGISTERED'))) {
            User::where('fcm_token', $target['token'])->update(['fcm_token' => null]);
        }

        $this->lastError = 'HTTP ' . $response->status() . ' ' . $response->body();
        Log::error('FCM API Error (' . $response->status() . '): ' . $response->body());
        Log::debug('FCM Request Payload: ' . json_encode(['message' => $message]));
        return false;
    }

    /**
     * Get a Google API access token using the service account.
     */
    protected function getAccessToken(): ?string
    {
        if (!file_exists($this->serviceAccountPath)) {
            Log::error('FCM: Service account file not found at ' . $this->serviceAccountPath);
            return null;
        }

        try {
            $serviceAccount = json_decode(file_get_contents($this->serviceAccountPath), true);
            
            $now = time();
            $payload = [
                'iss' => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'exp' => $now + 3600,
                'iat' => $now,
            ];

            $header = ['alg' => 'RS256', 'typ' => 'JWT'];
            
            $base64Header = $this->base64UrlEncode(json_encode($header));
            $base64Payload = $this->base64UrlEncode(json_encode($payload));
            
            $signature = '';
            openssl_sign($base64Header . '.' . $base64Payload, $signature, $serviceAccount['private_key'], 'SHA256');
            $base64Signature = $this->base64UrlEncode($signature);
            
            $jwt = $base64Header . '.' . $base64Payload . '.' . $base64Signature;

            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

            if (!$response->successful()) {
                Log::error('FCM OAuth Token Error (' . $response->status() . '): ' . $response->body());
                return null;
            }

            return $response->json('access_token');
        } catch (\Exception $e) {
            Log::error('FCM Token Exception: ' . $e->getMessage());
            return null;
        }
    }

    protected function base64UrlEncode($data): string
    {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    }
}
