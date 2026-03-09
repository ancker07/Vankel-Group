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

### Classification Rules:
- "MISSION": Use if the email is a request for repair, maintenance, intervention, or reports a problem (e.g., "leak", "breakage", "not working", "intervention", "fuite", "panne").
- "NON_MISSION": Use for spam, newsletters, or emails unrelated to building issues.
- "NEEDS_REVIEW": Use if it's a mission but keywords or details are ambiguous.

### Extracted Fields:
1. "classification": "MISSION" | "NON_MISSION" | "NEEDS_REVIEW"
2. "reasons": ["short reason why"]
3. "mission":
   - "title": Short descriptive title (e.g., "Water Leak at [Address]")
   - "description": Detailed technical description of the problem.
   - "sector": MUST be one of: ELECTRICITE, CARRELAGE, SANITAIRE, CHAUFFAGE, PLOMBERIE, PEINTURE, MENUISERIE, GENERAL, AUTRE.
   - "urgency": MUST be one of: LOW, MEDIUM, HIGH, CRITICAL.
   - "reference": Reference number if present in email.
   - "address": { "raw": "Full address", "street": "", "number": "", "postalCode": "", "city": "" }
   - "contactOnSite": { "name": "", "phone": "", "email": "" }

### Critical Instructions:
- Heavily favor "MISSION" if keywords like "intervention", "repair", "leak", "broken", or "fuite" are present, even in conversational tone.
- Extract contact persons even if they are described (e.g., "The concierge Edward at 0489...").
- For location, favor Belgian patterns (e.g., "Rue de la Loi 155, 1000 Bruxelles").

Output MUST be a valid JSON object.
PROMPT;
    }
}
