<?php

namespace App\Http\Controllers;

use App\Models\Setting;
use Illuminate\Http\Request;

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