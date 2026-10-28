<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class SettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        \App\Models\Setting::updateOrCreate(['key' => 'ai_model'], ['value' => \App\Services\AiService::DEFAULT_MODEL]);
        \App\Models\Setting::updateOrCreate(['key' => 'ai_api_key'], ['value' => env('OPENAI_API_KEY', '')]);
    }
}