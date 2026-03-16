<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiService
{
    public function extractEmailData(string $content, array $attachments = [])
    {
        $model = Setting::where('key', 'ai_model')->value('value') ?? 'gemini-1.5-flash-latest';
        $apiKey = Setting::where('key', 'ai_api_key')->value('value');

        if (!$apiKey) {
            throw new \Exception("AI API Key not configured.");
        }

        if (str_contains($model, 'gpt')) {
            return $this->callOpenAi($content, $attachments, $model, $apiKey);
        } else {
            return $this->callGemini($content, $attachments, $model, $apiKey);
        }
    }

    protected function callOpenAi(string $content, array $attachments, string $model, string $apiKey)
    {
        $messages = [
            ['role' => 'system', 'content' => $this->getSystemPrompt()],
            ['role' => 'user', 'content' => $content],
        ];

        // Basic support for vision if model supports it (optional, focusing on Gemini as primary)
        foreach ($attachments as $att) {
            if (str_starts_with($att['mime_type'], 'image/')) {
                 $messages[] = [
                     'role' => 'user',
                     'content' => [
                         ['type' => 'text', 'text' => "Attachment: {$att['name']}"],
                         ['type' => 'image_url', 'image_url' => ['url' => "data:{$att['mime_type']};base64,{$att['data']}"]]
                     ]
                 ];
            }
        }

        $response = Http::withToken($apiKey)->post('https://api.openai.com/v1/chat/completions', [
            'model' => $model,
            'messages' => $messages,
            'response_format' => ['type' => 'json_object'],
        ]);

        if ($response->failed()) {
            Log::error("OpenAI API Error: " . $response->body());
            throw new \Exception("AI Extraction failed (OpenAI: " . ($response->json('error.message') ?? 'Unknown error') . ")");
        }

        return json_decode($response->json('choices.0.message.content'), true);
    }

    protected function callGemini(string $content, array $attachments, string $model, string $apiKey)
    {
        // Use v1 for more stability if available, but v1beta allows recent models
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . $apiKey;

        $parts = [
            ['text' => $this->getSystemPrompt() . "\n\nEmail Content:\n" . $content]
        ];

        foreach ($attachments as $att) {
            // Gemini supports images and PDF in multimodal
            if (str_starts_with($att['mime_type'], 'image/') || $att['mime_type'] === 'application/pdf') {
                $parts[] = [
                    'inline_data' => [
                        'mime_type' => $att['mime_type'],
                        'data' => $att['data']
                    ]
                ];
                $parts[] = ['text' => "Enclosed attachment: " . $att['name']];
            }
        }

        $response = Http::post($url, [
            'contents' => [
                [
                    'role' => 'user',
                    'parts' => $parts
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

    /**
     * Translates manual inputs into the required EN, FR, and NL structure.
     */
    public function translateToFill(string $title, string $description)
    {
        $prompt = <<<PROMPT
You are a professional translator for a building management system.
Translate the provided title and technical description into Dutch and English. 
The input should be considered the primary language (often French, but detect if it's Dutch/English).

Return a valid JSON object with EXACTLY this structure:
{
  "title": {
    "en": "Translated title in English",
    "fr": "Translated title in French",
    "nl": "Translated title in Dutch"
  },
  "description": {
    "en": "Translated description in English",
    "fr": "Translated description in French",
    "nl": "Translated description in Dutch"
  }
}

Title Payload:
{$title}

Description Payload:
{$description}
PROMPT;

        $model = Setting::where('key', 'ai_model')->value('value') ?? 'gemini-1.5-flash-latest';
        $apiKey = Setting::where('key', 'ai_api_key')->value('value');
        
        if (!$apiKey) {
            // Fallback strategy if AI is offline: use the same string for all languages.
            return [
                'title' => ['en' => $title, 'fr' => $title, 'nl' => $title],
                'description' => ['en' => $description, 'fr' => $description, 'nl' => $description]
            ];
        }

        try {
            if (str_contains($model, 'gpt')) {
                return $this->callOpenAi($prompt, [], $model, $apiKey);
            } else {
                return $this->callGemini($prompt, [], $model, $apiKey);
            }
        } catch (\Exception $e) {
            Log::error("Translation AI Error: " . $e->getMessage());
            return [
                'title' => ['en' => $title, 'fr' => $title, 'nl' => $title],
                'description' => ['en' => $description, 'fr' => $description, 'nl' => $description]
            ];
        }
    }

    protected function getSystemPrompt()
    {
        return <<<PROMPT
You are an expert AI extraction engine for Vanakel Group, a Belgian building management company.
Your task is to extract ALL mission-critical details from the email content AND any attached documents (PDFs, images).

### ⚠️ CRITICAL: ATTACHMENT READING RULES
- You will receive email body text AND attached files (PDFs, images) as inline data.
- **ATTACHMENTS ARE THE PRIMARY DATA SOURCE.** They often contain formal intervention request forms with structured tables.
- Read EVERY piece of text in attachments: titles, headers, table rows, footers, handwritten notes, stamps.
- If the email body is vague but the attachment contains a formal request document, classify as "MISSION" based on the attachment.
- If there is a conflict between email body and attachment, **TRUST THE ATTACHMENT** (it's the formal document).

### DATA EXTRACTION PRIORITIES (from attachments AND email body):
1. **Syndic / Manager Name**: Look for "Syndic:", "Expéditeur:", "Gestionnaire:", "Manager:" in both email body and attachments. Extract this separately for the body and for each attachment.
2. **Address**: Look for "Adresse d'intervention:", "Adresse:", address tables, or Belgian format addresses (street + number, postal code + city).
3. **Contact Person**: Look for "Personne de contact:", "Contact sur place:", or names near phone numbers.
4. **Phone / GSM**: Look for "Numéro de GSM:", "GSM:", "Tél:", phone numbers starting with 04xx or +32.
5. **Problem Description**: Read the full body text of the document. Merge information from email body AND attachment for a complete description.
6. **Urgency**: "urgente", "dans les plus brefs délais", "dringend" = HIGH or CRITICAL. Normal requests = MEDIUM.

### Classification Rules:
- "MISSION": A genuine request for repair, maintenance, intervention. Can come from email body OR an attached PDF/image that is a formal request form.
- "NON_MISSION": Spam, newsletters, personal conversations, test messages ("test", "fff", "abc"), marketing emails.
- "NEEDS_REVIEW": Likely a real mission but missing key information (no address, vague problem).

### Output Schema (JSON):
{
  "classification": "MISSION" | "NON_MISSION" | "NEEDS_REVIEW",
  "confidence": 0.0-1.0,
  "reasons": ["short reason why"],
  "mission": {
    "title": {
      "en": "Short descriptive title in English",
      "fr": "Short descriptive title in French",
      "nl": "Short descriptive title in Dutch"
    },
    "description": {
      "en": "Full technical description in English",
      "fr": "Full technical description in French",
      "nl": "Full technical description in Dutch"
    },
    "sector": "ELECTRICITE | CARRELAGE | SANITAIRE | CHAUFFAGE | PLOMBERIE | PEINTURE | MENUISERIE | GENERAL | AUTRE",
    "urgency": "LOW | MEDIUM | HIGH | CRITICAL",
    "reference": "Reference number if found",
    "address": {
      "raw": "Full address as written",
      "street": "Street name",
      "number": "House/building number",
      "postalCode": "Postal code",
      "city": "City name"
    },
    "contactOnSite": {
      "name": "Contact person name",
      "phone": "Phone/GSM number",
      "email": "Email if found"
    },
    "syndicFromBody": "Name of the syndic/manager company extracted specifically from the email body.",
    "syndicFromAttachments": "Name of the syndic/manager company extracted specifically from the attached documents. If multiple documents have different names, prioritize the most recent or formal looking one.",
    "senderEmail": "Email sender address"
  },
  "extractionWarnings": ["any issues encountered during extraction"]
}

### Sector Mapping Guide:
- Leak, fuite, water damage, dégât des eaux, plumbing → PLOMBERIE or SANITAIRE
- Clogged sewer, égout bouché, débouchage → PLOMBERIE
- Heating, chauffage, boiler, chaudière → CHAUFFAGE
- Electrical, électricité, panne courant → ELECTRICITE
- Painting, peinture → PEINTURE
- Carpentry, menuiserie, door, porte, window, fenêtre → MENUISERIE
- Tiles, carrelage → CARRELAGE
- If unclear → GENERAL

### Critical Instructions:
- "MISSION" REQUIRES a specific, actionable building issue.
- Very short emails (just "fff", "hello", "test") are NEVER a "MISSION".
- Extract contact persons even from descriptive text (e.g., "The concierge Edward at 0489...").
- For location, favor Belgian patterns (e.g., "Brusselbaan 98, 1600 Sint-Pieters-Leeuw").
- The syndicName field is CRITICAL — always try to extract it from any mention of "Syndic" in the document.

Output MUST be a valid JSON object.
PROMPT;
    }
}
