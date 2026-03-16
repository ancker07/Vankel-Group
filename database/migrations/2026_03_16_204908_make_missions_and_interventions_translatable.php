<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 0. Change columns to TEXT first to avoid truncation errors
        // since JSON payloads for titles can easily exceed 255 chars.
        Schema::table('missions', function (Blueprint $table) {
            $table->text('title')->change();
            // description is already text, but let's change it to longtext just in case
            $table->longText('description')->change(); 
        });

        Schema::table('interventions', function (Blueprint $table) {
            $table->text('title')->change();
            $table->longText('description')->change();
        });

        // 1. Process missions
        $missions = DB::table('missions')->get();
        foreach ($missions as $mission) {
            // Only convert if it's not already a JSON object string
            if (!str_starts_with(trim($mission->title), '{')) {
                $newTitle = json_encode([
                    'en' => $mission->title,
                    'fr' => $mission->title,
                    'nl' => $mission->title,
                ], JSON_UNESCAPED_UNICODE);
                
                $newDesc = json_encode([
                    'en' => $mission->description,
                    'fr' => $mission->description,
                    'nl' => $mission->description,
                ], JSON_UNESCAPED_UNICODE);
                
                DB::table('missions')->where('id', $mission->id)->update([
                    'title' => $newTitle,
                    'description' => $newDesc,
                ]);
            }
        }

        // 2. Process interventions
        $interventions = DB::table('interventions')->get();
        foreach ($interventions as $intervention) {
            if (!str_starts_with(trim($intervention->title), '{')) {
                $newTitle = json_encode([
                    'en' => $intervention->title,
                    'fr' => $intervention->title,
                    'nl' => $intervention->title,
                ], JSON_UNESCAPED_UNICODE);
                
                $newDesc = json_encode([
                    'en' => $intervention->description,
                    'fr' => $intervention->description,
                    'nl' => $intervention->description,
                ], JSON_UNESCAPED_UNICODE);
                
                DB::table('interventions')->where('id', $intervention->id)->update([
                    'title' => $newTitle,
                    'description' => $newDesc,
                ]);
            }
        }

        // 3. (Optional) change to actual json column type
        try {
            Schema::table('missions', function (Blueprint $table) {
                $table->json('title')->change();
                $table->json('description')->change();
            });
            
            Schema::table('interventions', function (Blueprint $table) {
                $table->json('title')->change();
                $table->json('description')->change();
            });
        } catch (\Exception $e) {
            // Ignore if JSON type is not fully supported for change()
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $missions = DB::table('missions')->get();
        foreach ($missions as $mission) {
            $t = json_decode($mission->title, true);
            $d = json_decode($mission->description, true);
            
            DB::table('missions')->where('id', $mission->id)->update([
                'title' => is_array($t) ? mb_substr($t['fr'] ?? $t['en'] ?? '', 0, 255) : mb_substr($mission->title, 0, 255),
                'description' => is_array($d) ? ($d['fr'] ?? $d['en'] ?? '') : $mission->description,
            ]);
        }

        $interventions = DB::table('interventions')->get();
        foreach ($interventions as $intervention) {
            $t = json_decode($intervention->title, true);
            $d = json_decode($intervention->description, true);
            
            DB::table('interventions')->where('id', $intervention->id)->update([
                'title' => is_array($t) ? mb_substr($t['fr'] ?? $t['en'] ?? '', 0, 255) : mb_substr($intervention->title, 0, 255),
                'description' => is_array($d) ? ($d['fr'] ?? $d['en'] ?? '') : $intervention->description,
            ]);
        }

        try {
            Schema::table('missions', function (Blueprint $table) {
                $table->string('title')->change();
                $table->text('description')->change();
            });
            
            Schema::table('interventions', function (Blueprint $table) {
                $table->string('title')->change();
                $table->text('description')->change();
            });
        } catch (\Exception $e) {}
    }
};
