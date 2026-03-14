<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class NotificationService
{
    protected string $projectId;
    protected string $serviceAccountPath;

    public function __construct()
    {
        $this->serviceAccountPath = base_path('public/vankelgroup.json');
        
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
    public function sendNotification(string $token, string $title, string $body, array $data = []): bool
    {
        return $this->sendMessage(['token' => $token], $title, $body, $data);
    }

    /**
     * Send a notification to a specific topic (e.g., 'all_users').
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = []): bool
    {
        return $this->sendMessage(['topic' => $topic], $title, $body, $data);
    }

    /**
     * Send a notification to multiple tokens.
     */
    public function sendToMultiple(array $tokens, string $title, string $body, array $data = []): array
    {
        $results = [];
        foreach ($tokens as $token) {
            $results[$token] = $this->sendNotification($token, $title, $body, $data);
        }
        return $results;
    }

    /**
     * Shared logic for sending messages.
     */
    protected function sendMessage(array $target, string $title, string $body, array $data = []): bool
    {
        $accessToken = $this->getAccessToken();
        if (!$accessToken) {
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

        if (!empty($data)) {
            $message['data'] = array_map('strval', $data);
        }

        // Add target (token, topic, or condition)
        $message = array_merge($message, $target);

        $response = Http::withToken($accessToken)
            ->post($url, ['message' => $message]);

        if ($response->successful()) {
            return true;
        }

        Log::error('FCM API Error (' . $response->status() . '): ' . $response->body());
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

            return $response->json('access_token');
        } catch (\Exception $e) {
            Log::error('FCM Token error: ' . $e->getMessage());
            return null;
        }
    }

    protected function base64UrlEncode($data): string
    {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    }
}
