<?php

namespace App\Http\Controllers;

use App\Services\AiService;
use App\Services\TranscriptionException;
use Illuminate\Http\Request;

/** Speech-to-text proxy: the apps send audio here so the OpenAI key never leaves the server. */
class TranscriptionController extends Controller
{
    /** Audio types the transcription API accepts, as detected from the file content. */
    private const MIME_TYPES = [
        'audio/webm', 'video/webm', 'audio/mp4', 'video/mp4', 'audio/x-m4a', 'audio/m4a',
        'audio/mpeg', 'audio/wav', 'audio/x-wav', 'audio/wave', 'audio/vnd.wave',
    ];

    public function status(AiService $ai)
    {
        return response()->json(['available' => $ai->hasApiKey()]);
    }

    public function transcribe(Request $request, AiService $ai)
    {
        $validated = $request->validate([
            'audio' => ['required', 'file', 'max:25000', 'mimetypes:' . implode(',', self::MIME_TYPES)],
            'language' => ['required', 'in:en,fr,nl'],
        ]);

        try {
            return response()->json([
                'text' => $ai->transcribeAudio($request->file('audio'), $validated['language']),
            ]);
        } catch (TranscriptionException $e) {
            return response()->json(['error' => __('Voice transcription failed.')], $e->status);
        }
    }
}
