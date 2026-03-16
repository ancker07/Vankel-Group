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
        Schema::table('missions', function (Blueprint $table) {
            // First drop JSON constraint by making them text
            $table->text('title')->change();
            $table->longText('description')->change();
            
            if (!Schema::hasColumn('missions', 'title_en')) {
                $table->text('title_en')->nullable();
                $table->text('title_fr')->nullable();
                $table->text('title_nl')->nullable();
                $table->longText('description_en')->nullable();
                $table->longText('description_fr')->nullable();
                $table->longText('description_nl')->nullable();
            }
        });

        Schema::table('interventions', function (Blueprint $table) {
            $table->text('title')->change();
            $table->longText('description')->change();
            
            if (!Schema::hasColumn('interventions', 'title_en')) {
                $table->text('title_en')->nullable();
                $table->text('title_fr')->nullable();
                $table->text('title_nl')->nullable();
                $table->longText('description_en')->nullable();
                $table->longText('description_fr')->nullable();
                $table->longText('description_nl')->nullable();
            }
        });

        // Migrate existing JSON data or raw strings to the new columns
        $this->migrateData('missions');
        $this->migrateData('interventions');
    }

    protected function migrateData($table)
    {
        $records = DB::table($table)->get();
        foreach ($records as $record) {
            // Check if title is JSON from the previous attempt
            $titleData = json_decode($record->title, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($titleData)) {
                $t_en = $titleData['en'] ?? $titleData['fr'] ?? '';
                $t_fr = $titleData['fr'] ?? $titleData['en'] ?? '';
                $t_nl = $titleData['nl'] ?? $titleData['fr'] ?? '';
            } else {
                $t_en = $record->title;
                $t_fr = $record->title;
                $t_nl = $record->title;
            }

            // check description
            $descData = json_decode($record->description, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($descData)) {
                $d_en = $descData['en'] ?? $descData['fr'] ?? '';
                $d_fr = $descData['fr'] ?? $descData['en'] ?? '';
                $d_nl = $descData['nl'] ?? $descData['fr'] ?? '';
            } else {
                $d_en = $record->description;
                $d_fr = $record->description;
                $d_nl = $record->description;
            }

            DB::table($table)->where('id', $record->id)->update([
                'title_en' => $t_en,
                'title_fr' => $t_fr,
                'title_nl' => $t_nl,
                'description_en' => $d_en,
                'description_fr' => $d_fr,
                'description_nl' => $d_nl,
                // Optional: restore title and description back to generic fallback
                'title' => mb_substr($t_fr, 0, 255),
                'description' => $d_fr,
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->dropColumn(['title_en', 'title_fr', 'title_nl', 'description_en', 'description_fr', 'description_nl']);
        });

        Schema::table('interventions', function (Blueprint $table) {
            $table->dropColumn(['title_en', 'title_fr', 'title_nl', 'description_en', 'description_fr', 'description_nl']);
        });
    }
};
