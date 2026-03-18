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
        \App\Models\Setting::updateOrCreate(['key' => 'ai_model'], ['value' => 'gemini-3-flash-preview']);
        \App\Models\Setting::updateOrCreate(['key' => 'ai_api_key'], ['value' => env('API_KEY', 'AIzaSyDod89apjaPOhG3dM9BeL36m2WtXNkywgU')]);

        // AIzaSyDp_TF6kil6J-7KaKeW_pVhOEBZcSTAefo
        // AIzaSyDod89apjaPOhG3dM9BeL36m2WtXNkywgU
    }
}