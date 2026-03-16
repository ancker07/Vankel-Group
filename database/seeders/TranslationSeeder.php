<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\MaintenancePlan;
use App\Models\Notification;
use App\Models\NotificationLog;
use App\Services\AiService;
use Illuminate\Support\Facades\Log;

class TranslationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(AiService $aiService): void
    {
        $this->command->info('Starting Translation Seeder...');

        $this->translateModel(Intervention::class, 'title', 'description', $aiService);
        $this->translateModel(Mission::class, 'title', 'description', $aiService);
        $this->translateModel(MaintenancePlan::class, 'title', 'description', $aiService);
        
        // Notifications use 'body' instead of 'description'
        $this->translateModel(Notification::class, 'title', 'body', $aiService);
        $this->translateModel(NotificationLog::class, 'title', 'body', $aiService);

        $this->command->info('Translation Seeder completed!');
    }

    /**
     * Translates records for a given model that are missing English translations.
     */
    private function translateModel($modelClass, $titleField, $descField, AiService $aiService)
    {
        $this->command->info("Processing {$modelClass}...");

        $records = $modelClass::whereNull("{$titleField}_en")
            ->orWhereNull("{$descField}_en")
            ->get();

        $count = $records->count();
        $this->command->info("Found {$count} records to translate for {$modelClass}.");

        $bar = $this->command->getOutput()->createProgressBar($count);
        $bar->start();

        foreach ($records as $record) {
            try {
                $translated = $aiService->translateToFill(
                    $record->$titleField,
                    $record->$descField ?? ''
                );

                if ($translated) {
                    $record->update([
                        "{$titleField}_en" => $translated['title_en'] ?? $record->$titleField,
                        "{$titleField}_fr" => $translated['title_fr'] ?? $record->$titleField,
                        "{$titleField}_nl" => $translated['title_nl'] ?? $record->$titleField,
                        "{$descField}_en" => $translated['description_en'] ?? $record->$descField,
                        "{$descField}_fr" => $translated['description_fr'] ?? $record->$descField,
                        "{$descField}_nl" => $translated['description_nl'] ?? $record->$descField,
                    ]);
                }
            } catch (\Exception $e) {
                Log::error("Failed to translate {$modelClass} ID {$record->id}: " . $e->getMessage());
                $this->command->error("\nFailed to translate ID {$record->id}. See logs for details.");
            }

            $bar->advance();
            // Sleep to avoid rate limiting on the AI API
            usleep(500000); // 0.5 seconds
        }

        $bar->finish();
        $this->command->newLine();
    }
}

