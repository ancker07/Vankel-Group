<?php

namespace App\Http\Controllers;

use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class SettingController extends Controller
{
    public function getAiSettings()
    {
        $model = Setting::where('key', 'ai_model')->first();
        $apiKey = Setting::where('key', 'ai_api_key')->first();

        return response()->json([
            'model' => $model ? $model->value : 'gemini-3-flash-preview',
            'apiKey' => $apiKey ? $apiKey->value : ''
        ]);
    }

    public function improveNote(Request $request)
    {
        $request->validate(['text' => 'required|string']);
        $text = $request->text;

        $model = Setting::where('key', 'ai_model')->first()?->value ?? 'gemini-3-flash-preview';
        $apiKey = Setting::where('key', 'ai_api_key')->first()?->value;

        if (!$apiKey) {
            return response()->json(['error' => 'AI API Key not configured.'], 400);
        }

        $systemPrompt = "You are a careful grammar and clarity assistant. 
        Rewrite the following text ONLY to improve clarity and correct grammar/spelling.
        STRICT RULES:
        1. Correct grammar, spelling, and minor sentence structure.
        2. Keep the EXACT same technical meaning and terminology.
        3. AUTO-DETECT the language and rewrite in that SAME language. No translation.
        4. DO NOT add new information or decorative/marketing language.
        5. Keep the rewrite minimal, subtle, and conservative.";

        try {
            if (str_starts_with($model, 'gpt')) {
                $response = Http::withToken($apiKey)->post('https://api.openai.com/v1/chat/completions', [
                    'model' => $model,
                    'messages' => [
                        ['role' => 'system', 'content' => $systemPrompt],
                        ['role' => 'user', 'content' => "Original text: \"$text\""]
                    ],
                ]);
                $result = $response->json()['choices'][0]['message']['content'] ?? $text;
            } else {
                // Gemini API
                $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}", [
                    'contents' => [
                        [
                            'parts' => [
                                ['text' => "$systemPrompt\n\nUSER PROMPT: Original text: \"$text\""]
                            ]
                        ]
                    ]
                ]);
                $result = $response->json()['candidates'][0]['content']['parts'][0]['text'] ?? $text;
            }

            return response()->json(['improved_text' => trim($result)]);
        } catch (\Exception $e) {
            return response()->json(['error' => 'AI improvement failed: ' . $e->getMessage()], 500);
        }
    }

    public function updateAiSettings(Request $request)
    {
        $request->validate([
            'model' => 'required|string',
            'apiKey' => 'required|string',
        ]);

        Setting::updateOrCreate(['key' => 'ai_model'], ['value' => $request->model]);
        Setting::updateOrCreate(['key' => 'ai_api_key'], ['value' => $request->apiKey]);

        return response()->json(['message' => 'AI settings updated successfully.']);
    }
}