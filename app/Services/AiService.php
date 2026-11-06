<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiService
{
    /** Cost-efficient, multimodal-capable default: strong at structured extraction, native PDF + image input. */
    public const DEFAULT_MODEL = 'gpt-5-mini';

    public const TRANSCRIPTION_MODELS = ['gpt-transcribe', 'gpt-4o-mini-transcribe', 'whisper-1'];

    /** Trade words the model should recognise; hints only, never echoed when not spoken. */
    private const TRANSCRIPTION_KEYWORDS = [
        'en' => ['syndic', 'boiler', 'leak', 'intervention'],
        'fr' => ['syndic', 'chaudière', 'fuite', 'débouchage', 'carrelage', 'menuiserie', 'intervention', 'GSM'],
        'nl' => ['syndicus', 'verwarmingsketel', 'lekkage', 'ontstopping', 'tegelwerk', 'schrijnwerk', 'interventie', 'gsm'],
    ];

    /** Context sentence in the dictation language: it keeps the model on that language (and Belgian spelling). */
    private const TRANSCRIPTION_PROMPTS = [
        'en' => 'Dictation in English by a building technician. Vocabulary: %s.',
        'fr' => "Dictée en français (Belgique) par un technicien du bâtiment. Ne pas traduire. Vocabulaire : %s.",
        'nl' => 'Dictaat in het Nederlands (Vlaams) door een technicus in de bouw. Niet vertalen. Woordenschat: %s.',
    ];

    /** Common words that belong to ONE of our languages (shared ones like "de", "en", "is" are left out). */
    private const LANGUAGE_WORDS = [
        'en' => ['the', 'and', 'to', 'of', 'you', 'that', 'it', 'for', 'with', 'this', 'are', 'was', 'have', 'we', 'they', 'not', 'but', 'there', 'what', 'please', 'testing', 'hi', 'hello', 'thank', 'should', 'would', 'will'],
        'fr' => ['le', 'la', 'les', 'des', 'et', 'est', 'une', 'du', 'que', 'pour', 'dans', 'pas', 'il', 'sur', 'avec', 'je', 'ce', 'nous', 'vous', 'au', 'aux', 'ne', 'qui', 'sont', 'mais', 'très', 'cette', 'bonjour', 'merci'],
        'nl' => ['het', 'een', 'van', 'dat', 'op', 'niet', 'voor', 'met', 'zijn', 'ik', 'er', 'aan', 'wij', 'maar', 'dit', 'ook', 'wordt', 'naar', 'bij', 'nog', 'deze', 'jullie', 'heeft', 'goedendag', 'dank'],
    ];

    private const LANGUAGE_NAMES = ['en' => 'English', 'fr' => 'French', 'nl' => 'Dutch'];

    /** What speech models invent from silence or noise; never real dictation. */
    private const TRANSCRIPTION_HALLUCINATIONS = [
        'thank you', 'thank you for watching', 'thanks for watching', 'bye', 'you',
        'merci', "merci d'avoir regardé cette vidéo", 'merci davoir regardé', 'sous-titres réalisés par la communauté damara', 'sous-titrage st 501', 'sous-titrage société radio-canada',
        'bedankt', 'bedankt voor het kijken', 'ondertitels ingediend door de amara.org gemeenschap', 'ondertiteling door de amara.org gemeenschap',
    ];

    public function extractEmailData(string $content, array $attachments = [])
    {
        return $this->callOpenAi($content, $attachments, $this->resolveModel(), $this->resolveApiKey(), $this->getSystemPrompt());
    }

    public function hasApiKey(): bool
    {
        return (bool) (Setting::where('key', 'ai_api_key')->value('value') ?: env('OPENAI_API_KEY'));
    }

    /**
     * Transcribes one recorded speech segment.
     *
     * @throws TranscriptionException
     */
    public function transcribeAudio(UploadedFile $audio, string $language): string
    {
        if (!$this->hasApiKey()) {
            throw new TranscriptionException(503, 'AI API Key not configured.');
        }

        // The API recognises the format from the file name, and uploads may arrive without a useful one.
        $extension = match (true) {
            str_contains($audio->getMimeType(), 'webm') => 'webm',
            str_contains($audio->getMimeType(), 'mp4'), str_contains($audio->getMimeType(), 'm4a') => 'm4a',
            str_contains($audio->getMimeType(), 'mpeg') => 'mp3',
            default => 'wav',
        };

        // Best model first. Each older model is tried when the one before it refuses or fails.
        $lastStatus = 502;
        foreach (self::TRANSCRIPTION_MODELS as $model) {
            try {
                $response = Http::withToken($this->resolveApiKey())
                    ->timeout(60)
                    ->asMultipart()
                    ->attach('file', file_get_contents($audio->getRealPath()), "speech.{$extension}")
                    ->post('https://api.openai.com/v1/audio/transcriptions', $this->transcriptionFields($model, $language));
            } catch (ConnectionException $e) {
                Log::warning('Transcription connection failed.', ['model' => $model, 'message' => $e->getMessage()]);
                $lastStatus = 502;
                continue;
            }

            if ($response->successful()) {
                $text = $this->cleanTranscript((string) $response->json('text'));

                // Whatever language was spoken, the text is written in the language the user selected.
                $spoken = $this->detectOtherLanguage($text, $language);
                if ($spoken !== null) {
                    $text = $this->translateTranscript($text, $language, $spoken);
                }

                return $text;
            }

            Log::error("OpenAI transcription error [{$model}, " . $response->status() . ']: ' . $response->body());

            // A bad key fails on every model, so stop there.
            if ($response->status() === 401) {
                throw new TranscriptionException(503, 'Upstream refused the key.');
            }
            $lastStatus = match (true) {
                in_array($response->status(), [403, 404], true) => 503, // model unusable
                $response->status() === 400 => 422,                     // unreadable audio or parameters
                default => 502,                                         // rate limit / outage
            };
        }

        throw new TranscriptionException($lastStatus, 'Upstream error.');
    }

    /** Trims, and drops the stock phrases a model invents from silence or noise. */
    private function cleanTranscript(string $text): string
    {
        $text = trim($text);
        $plain = mb_strtolower(trim(preg_replace('/[\p{P}\s]+/u', ' ', $text)));
        $known = array_map(fn ($p) => mb_strtolower(trim(preg_replace('/[\p{P}\s]+/u', ' ', $p))), self::TRANSCRIPTION_HALLUCINATIONS);

        return in_array($plain, $known, true) ? '' : $text;
    }

    /**
     * The language the text is clearly written in, when that is another of our languages than the selected one
     * (e.g. English spoken while the app is in French). Null when it matches, or when it cannot be told.
     */
    private function detectOtherLanguage(string $text, string $selected): ?string
    {
        $words = preg_split('/[^\p{L}\']+/u', mb_strtolower($text), -1, PREG_SPLIT_NO_EMPTY);
        if (count($words) < 3) {
            return null; // too short to tell
        }
        $score = fn (string $lang) => count(array_filter($words, fn ($w) => in_array($w, self::LANGUAGE_WORDS[$lang], true)));
        $own = $score($selected);

        $best = null;
        $bestScore = 0;
        foreach (array_diff(array_keys(self::LANGUAGE_WORDS), [$selected]) as $other) {
            $points = $score($other);
            if ($points > $bestScore) {
                [$best, $bestScore] = [$other, $points];
            }
        }

        // clearly another language: at least two of its words and more than the selected one, or one of its words
        // with none of the selected language's
        return $best !== null && $bestScore > $own && ($bestScore >= 2 || $own === 0) ? $best : null;
    }

    /** Writes a dictated text in the selected language. If the translation fails the text is kept as spoken. */
    private function translateTranscript(string $text, string $target, string $spoken): string
    {
        try {
            $result = $this->callOpenAi(
                "Dictated text ({$this->languageName($spoken)}):\n{$text}",
                [],
                $this->resolveModel(),
                $this->resolveApiKey(),
                'You translate a short dictated note from a building technician into ' . $this->languageName($target)
                . '. Keep the meaning, numbers, names, addresses and technical terms exactly. Do not add or remove anything. '
                . 'Return JSON: {"text": "<the translation>"}.'
            );
            $translated = trim((string) ($result['text'] ?? ''));

            return $translated !== '' ? $translated : $text;
        } catch (\Throwable $e) {
            Log::warning('Dictation translation failed, keeping the spoken text: ' . $e->getMessage());

            return $text;
        }
    }

    private function languageName(string $code): string
    {
        return self::LANGUAGE_NAMES[$code] ?? $code;
    }

    /** gpt-transcribe takes languages[] and keywords[]; the older models take a single language and a prompt. */
    private function transcriptionFields(string $model, string $language): array
    {
        $keywords = self::TRANSCRIPTION_KEYWORDS[$language] ?? [];
        $fields = [['name' => 'model', 'contents' => $model]];

        if ($model === self::TRANSCRIPTION_MODELS[0]) {
            // the selected language first (the focus), the others after: a technician may speak another one
            foreach (array_merge([$language], array_diff(array_keys(self::LANGUAGE_NAMES), [$language])) as $heard) {
                $fields[] = ['name' => 'languages[]', 'contents' => $heard];
            }
            foreach ($keywords as $keyword) {
                $fields[] = ['name' => 'keywords[]', 'contents' => $keyword];
            }

            return $fields;
        }

        $fields[] = ['name' => 'language', 'contents' => $language];
        $fields[] = ['name' => 'prompt', 'contents' => sprintf(self::TRANSCRIPTION_PROMPTS[$language] ?? '%s', implode(', ', $keywords))];
        $fields[] = ['name' => 'temperature', 'contents' => '0'];

        return $fields;
    }

    protected function resolveModel(): string
    {
        return Setting::where('key', 'ai_model')->value('value') ?: self::DEFAULT_MODEL;
    }

    protected function resolveApiKey(): string
    {
        $apiKey = Setting::where('key', 'ai_api_key')->value('value') ?: env('OPENAI_API_KEY');

        if (!$apiKey) {
            Log::error("AI API Key not configured in settings or environment.");
            throw new \Exception("AI API Key not configured.");
        }

        return $apiKey;
    }

    /**
     * Calls OpenAI's Responses API, which natively accepts text, images, and PDFs
     * in one multimodal request (chat completions does not support PDF input).
     */
    protected function callOpenAi(string $content, array $attachments, string $model, string $apiKey, ?string $systemPrompt = null, ?array $schema = null)
    {
        $userContent = [
            ['type' => 'input_text', 'text' => $content],
        ];

        foreach ($attachments as $att) {
            if (str_starts_with($att['mime_type'], 'image/')) {
                $userContent[] = [
                    'type' => 'input_image',
                    'image_url' => "data:{$att['mime_type']};base64,{$att['data']}",
                ];
            } elseif ($att['mime_type'] === 'application/pdf') {
                $userContent[] = [
                    'type' => 'input_file',
                    'filename' => $att['name'] ?? 'document.pdf',
                    'file_data' => "data:{$att['mime_type']};base64,{$att['data']}",
                ];
            }
        }

        $payload = [
            'model' => $model,
            'input' => [
                [
                    'role' => 'system',
                    'content' => [['type' => 'input_text', 'text' => $systemPrompt ?? $this->getSystemPrompt()]],
                ],
                [
                    'role' => 'user',
                    'content' => $userContent,
                ],
            ],
            'text' => ['format' => $schema ? [
                'type' => 'json_schema',
                'name' => 'coordinates',
                'schema' => $schema,
                'strict' => true,
            ] : ['type' => 'json_object']],
        ];

        // Reasoning-capable models: keep effort low for extraction/translation tasks.
        // This is a structured, well-specified task, not an open-ended problem — a high
        // reasoning budget here just burns tokens without improving the output.
        if (str_starts_with($model, 'gpt-5') || str_starts_with($model, 'o')) {
            $payload['reasoning'] = ['effort' => 'low'];
        }

        $response = Http::withToken($apiKey)->timeout(120)->post('https://api.openai.com/v1/responses', $payload);

        if ($response->failed()) {
            $errorMsg = $response->json('error.message') ?? 'Unknown error';
            Log::error("OpenAI API Error [{$model}]: " . $response->body());
            throw new \Exception("AI Extraction failed (OpenAI: {$errorMsg})");
        }

        $resultText = $response->json('output_text');

        if (!$resultText) {
            // Fallback: walk the raw output array (some SDKs/models omit the output_text convenience field)
            foreach ($response->json('output', []) as $item) {
                foreach ($item['content'] ?? [] as $contentItem) {
                    if (($contentItem['type'] ?? null) === 'output_text' && !empty($contentItem['text'])) {
                        $resultText = $contentItem['text'];
                        break 2;
                    }
                }
            }
        }

        if (!$resultText) {
            $status = $response->json('status');
            Log::error("OpenAI Empty Response. Status: {$status}. Body: " . $response->body());
            throw new \Exception("AI Extraction failed (OpenAI returned an empty response: {$status}).");
        }

        $data = json_decode($resultText, true);
        if (!$data) {
            Log::error("OpenAI JSON parse failed: " . $resultText);
            throw new \Exception("AI Extraction failed (Invalid JSON output).");
        }

        return $data;
    }

    public function resolveCoordinates(string $address): ?array
    {
        $schema = [
            'type' => 'object',
            'properties' => [
                'latitude' => ['type' => ['number', 'null']],
                'longitude' => ['type' => ['number', 'null']],
            ],
            'required' => ['latitude', 'longitude'],
            'additionalProperties' => false,
        ];

        $systemPrompt = 'You resolve Belgian street addresses to map coordinates. Return JSON matching the schema. Only return coordinates when the address uniquely identifies a real location. Never invent, estimate, or use the centre of a city. Return null for both values when uncertain.';

        try {
            $result = $this->callOpenAi(
                "Address to resolve:\n{$address}",
                [],
                $this->resolveModel(),
                $this->resolveApiKey(),
                $systemPrompt,
                $schema,
            );
        } catch (\Throwable $exception) {
            Log::warning('AI coordinate fallback failed.', ['message' => $exception->getMessage()]);
            return null;
        }

        $latitude = $result['latitude'] ?? null;
        $longitude = $result['longitude'] ?? null;

        if (!is_numeric($latitude) || !is_numeric($longitude)) {
            return null;
        }

        $latitude = (float) $latitude;
        $longitude = (float) $longitude;

        return $latitude >= -90 && $latitude <= 90 && $longitude >= -180 && $longitude <= 180
            ? ['latitude' => $latitude, 'longitude' => $longitude]
            : null;
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

        $apiKey = Setting::where('key', 'ai_api_key')->value('value') ?: env('OPENAI_API_KEY');

        if (!$apiKey) {
            Log::warning("Translation AI fallback: API Key missing.");
            // Fallback strategy if AI is offline: use the same string for all languages.
            return [
                'title' => ['en' => $title, 'fr' => $title, 'nl' => $title],
                'description' => ['en' => $description, 'fr' => $description, 'nl' => $description]
            ];
        }

        $translationSystemPrompt = "You are a professional translator for a building management system. Return ONLY valid JSON.";

        try {
            return $this->callOpenAi($prompt, [], $this->resolveModel(), $apiKey, $translationSystemPrompt);
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

### ⚠️ EMAIL THREAD / CONVERSATION HANDLING
- The content may contain a **CONVERSATION THREAD** with multiple messages presented in chronological order.
- If it does, you MUST read **ALL messages** sequentially to understand the full context.
- Later messages in a thread may **UPDATE**, **CANCEL**, or **CLARIFY** earlier requests.
- If a later message explicitly cancels a request (e.g., "never mind", "c'est résolu", "already fixed"), classify as "NON_MISSION".
- If messages discuss back-and-forth about a problem, synthesize everything into ONE coherent mission.
- Extract data (address, contact, syndic) from the **MOST SPECIFIC or MOST RECENT** message, but consider all context.
- The final mission title and description should reflect the **COMPLETE understanding** of the conversation, not just one message.
- Pay attention to who is requesting what — the syndic/manager requesting work is usually in the earliest messages, while later messages may contain confirmations or additional details.
- For conversations: only classify as "MISSION" when the thread has enough info to act. If the conversation is still discussing/negotiating, use "AWAITING_CONTEXT".

### ⚠️ SINGLE EMAIL INTELLIGENCE (No Thread Yet)
When processing a SINGLE email (not part of a thread), determine whether it is a **direct task** or a **conversational email** that implies more messages are expected:

**DIRECT TASK → Classify as "MISSION" immediately:**
- Contains a clear, specific work request (e.g., "Please fix the leak at Rue de Namur 45")
- Has an attached formal intervention/request form (PDF)
- Contains explicit instructions with address, problem description, and contact info
- Uses imperative language: "Veuillez intervenir", "Please send a technician", "Merci d'intervenir"
- Includes a reference number or formal request structure

**CONVERSATIONAL / INCOMPLETE → Classify as "AWAITING_CONTEXT":**
- References a previous conversation: "comme discuté", "as discussed", "suite à notre conversation"
- Asks questions without giving instructions: "Quand pouvez-vous passer?", "Is this covered?"
- Uses phrases implying ongoing exchange: "pour donner suite", "following up", "en attendant votre retour"
- Contains only partial information (e.g., describes a problem but no address)
- Forwards another email without clear instructions
- Feels like the START of a conversation rather than a complete request

**Set `isDirectTask` to true** if the email is a clear standalone task that needs immediate action.
**Set `isDirectTask` to false** if the email seems conversational or implies further discussion.

### DATA EXTRACTION PRIORITIES (from attachments AND email body):
1. **Syndic / Manager Name**: Look for "Syndic:", "Expéditeur:", "Gestionnaire:", "Manager:" in both email body and attachments. Extract this separately for the body and for each attachment.
2. **Address**: Look for "Adresse d'intervention:", "Adresse:", address tables, or Belgian format addresses (street + number, postal code + city).
3. **Contact Person**: Look for "Personne de contact:", "Contact sur place:", or names near phone numbers.
4. **Phone / GSM**: Look for "Numéro de GSM:", "GSM:", "Tél:", phone numbers starting with 04xx or +32.
5. **Problem Description**: Read the full body text of the document. Merge information from email body AND attachment for a complete description.
6. **Urgency**: "urgente", "dans les plus brefs délais", "dringend" = HIGH or CRITICAL. Normal requests = MEDIUM.

### Classification Rules:
- "MISSION": A genuine, actionable request for repair, maintenance, or intervention with enough information to act on. Standalone direct tasks with clear instructions.
- "AWAITING_CONTEXT": The email appears to be part of an ongoing or expected conversation. It may contain a real issue but lacks enough context or information to create a mission yet. The system will defer and re-process when more messages arrive.
- "NON_MISSION": Spam, newsletters, personal conversations, test messages ("test", "fff", "abc"), marketing emails, auto-replies.
- "NEEDS_REVIEW": Likely a real mission but missing key information (no address, vague problem). Has enough intent to be actionable but needs human verification.

### Output Schema (JSON):
{
  "classification": "MISSION" | "NON_MISSION" | "NEEDS_REVIEW" | "AWAITING_CONTEXT",
  "isDirectTask": true | false,
  "confidence": 0.0-1.0,
  "reasons": ["A single concise string (1-2 sentences max) explaining why this classification was chosen."],
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
- "MISSION" REQUIRES a specific, actionable building issue with enough detail to act.
- Very short emails (just "fff", "hello", "test") are NEVER a "MISSION".
- If an email with a formal attached request form (PDF) is received, ALWAYS classify as "MISSION" regardless of email body content — the form IS the request.
- Extract contact persons even from descriptive text (e.g., "The concierge Edward at 0489...").
- For location, favor Belgian patterns (e.g., "Brusselbaan 98, 1600 Sint-Pieters-Leeuw").
- The syndicName field is CRITICAL — always try to extract it from any mention of "Syndic" in the document.
- When in doubt between "MISSION" and "AWAITING_CONTEXT", prefer "AWAITING_CONTEXT" for single emails without attachments. Prefer "MISSION" if formal documents are attached.
- Keep "reasons" and all free-text fields concise and to the point — this is a structured data extraction task, not a narrative report.

Output MUST be a valid JSON object.
PROMPT;
    }
}
