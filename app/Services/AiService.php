<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiService
{
    public function extractEmailData(string $content)
    {
        $model = Setting::where('key', 'ai_model')->value('value') ?? 'gemini-1.5-flash-latest';
        $apiKey = Setting::where('key', 'ai_api_key')->value('value');

        if (!$apiKey) {
            throw new \Exception("AI API Key not configured.");
        }

        if (str_contains($model, 'gpt')) {
            return $this->callOpenAi($content, $model, $apiKey);
        } else {
            return $this->callGemini($content, $model, $apiKey);
        }
    }

    protected function callOpenAi(string $content, string $model, string $apiKey)
    {
        $response = Http::withToken($apiKey)->post('https://api.openai.com/v1/chat/completions', [
            'model' => $model,
            'messages' => [
                ['role' => 'system', 'content' => $this->getSystemPrompt()],
                ['role' => 'user', 'content' => $content],
            ],
            'response_format' => ['type' => 'json_object'],
        ]);

        if ($response->failed()) {
            Log::error("OpenAI API Error: " . $response->body());
            throw new \Exception("AI Extraction failed (OpenAI: " . ($response->json('error.message') ?? 'Unknown error') . ")");
        }

        return json_decode($response->json('choices.0.message.content'), true);
    }

    protected function callGemini(string $content, string $model, string $apiKey)
    {
        // Use v1 for more stability if available, but v1beta allows recent models
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . $apiKey;

        $response = Http::post($url, [
            'contents' => [
                [
                    'role' => 'user',
                    'parts' => [
                        ['text' => $this->getSystemPrompt() . "\n\nEmail Content:\n" . $content]
                    ]
                ]
            ],
            'generationConfig' => [
                'response_mime_type' => 'application/json',
            ]
        ]);

        if ($response->failed()) {
            $errorMsg = $response->json('error.message') ?? 'Unknown Gemini Error';
            Log::error("Gemini API Error [" . $model . "]: " . $response->body());
            throw new \Exception("AI Extraction failed (Gemini: " . $errorMsg . ")");
        }

        $resultText = $response->json('candidates.0.content.parts.0.text');
        
        if (!$resultText) {
             Log::error("Gemini Empty Response: " . $response->body());
             throw new \Exception("AI Extraction failed (Gemini returned empty response).");
        }

        $data = json_decode($resultText, true);
        if (!$data) {
            Log::error("Gemini JSON parse failed: " . $resultText);
            throw new \Exception("AI Extraction failed (Invalid JSON output).");
        }

        return $data;
    }

    protected function getSystemPrompt()
    {
        return <<<PROMPT
You are an AI assistant for a building management company called Vanakel Group.
Extract mission-critical details from the following email content.
Output MUST be a valid JSON object with the following structure:
{
  "classification": "MISSION" | "NON_MISSION" | "NEEDS_REVIEW",
  "reasons": ["short reason why"],
  "mission": {
    "title": "Short title",
    "description": "Detailed description of the issue",
    "reference": "Reference number from email if any",
    "address": {
      "raw": "Full address mentioned",
      "street": "Street name",
      "number": "House/Building number",
      "postalCode": "Zip code",
      "city": "City"
    },
    "contactOnSite": {
      "name": "Contact name",
      "phone": "Contact phone",
      "email": "Contact email"
    }
  }
}
PROMPT;
    }
}
