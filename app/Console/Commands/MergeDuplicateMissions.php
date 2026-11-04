<?php

namespace App\Console\Commands;

use App\Models\Mission;
use App\Services\MissionDeduplicator;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

/**
 * One-time cleanup: merge duplicate missions into the oldest mission of each group.
 *
 *   php artisan missions:merge-duplicates                 # dry run, lists the groups
 *   php artisan missions:merge-duplicates --execute       # merge them
 *   php artisan missions:merge-duplicates --file=groups.csv --execute
 *
 * --file: CSV/text, one group per line, mission ids separated by commas, semicolons or spaces
 * (export the duplicate_missions.xlsx sheet to CSV). Without it, groups are detected with the
 * same rules ingestion uses (reference, thread, same building + title >= 85%).
 */
class MergeDuplicateMissions extends Command
{
    protected $signature = 'missions:merge-duplicates {--execute : Actually merge (default is a dry run)} {--file= : CSV file of mission-id groups}';
    protected $description = 'Merge duplicate missions into the oldest mission of each group';

    public function handle(MissionDeduplicator $deduper): int
    {
        $groups = $this->option('file') ? $this->readGroups($this->option('file')) : $deduper->findDuplicateGroups();
        if ($groups === null) {
            return self::FAILURE;
        }

        if (!$groups) {
            $this->info('No duplicate groups found.');

            return self::SUCCESS;
        }

        $execute = (bool) $this->option('execute');
        $extra = 0;
        foreach ($groups as $n => $ids) {
            $missions = Mission::whereIn('id', $ids)->orderBy('id')->get();
            if ($missions->count() < 2) {
                continue;
            }
            $keeper = $missions->first();
            $dupes = $missions->slice(1);
            $extra += $dupes->count();

            $statuses = $missions->pluck('status')->unique()->implode('/');
            $this->line(sprintf('Group %d: keep #%d (%s) <- merge %s  [statuses: %s]', $n + 1, $keeper->id, $keeper->title, $dupes->pluck('id')->map(fn ($i) => "#$i")->implode(', '), $statuses));
            if ($missions->pluck('assigned_user_id')->filter()->unique()->count() > 1) {
                $this->warn('   ! missions assigned to different users, the keeper\'s assignee is kept');
            }

            if ($execute) {
                foreach ($dupes as $dupe) {
                    $deduper->merge($keeper->fresh(), $dupe);
                }
                Log::info("Mission cleanup: group merged into #{$keeper->id}", ['merged' => $dupes->pluck('id')->all()]);
            }
        }

        $this->info(sprintf('%d group(s), %d extra mission(s) %s.', count($groups), $extra, $execute ? 'merged' : 'would be merged (dry run, add --execute)'));

        return self::SUCCESS;
    }

    protected function readGroups(string $path): ?array
    {
        if (!is_file($path)) {
            $this->error("File not found: {$path}");

            return null;
        }
        $groups = [];
        foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            preg_match_all('/\d+/', $line, $m);
            $ids = array_values(array_unique(array_map('intval', $m[0])));
            if (count($ids) > 1) {
                $groups[] = $ids;
            }
        }

        return $groups;
    }
}
