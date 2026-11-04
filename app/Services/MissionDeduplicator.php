<?php

namespace App\Services;

use App\Models\Contact;
use App\Models\Email;
use App\Models\Mission;
use App\Models\MissionUpdate;
use Illuminate\Contracts\Cache\LockTimeoutException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Finds the open mission an incoming email really belongs to, so follow-ups,
 * forwards, reminders and replies are attached to it instead of creating a
 * duplicate mission.
 *
 * Match order (strongest first):
 *   1. same job reference  (AO-1234, INT-1234, QUE-12, O26xxxx)
 *   2. same email thread
 *   3. same building + similar title  (>= AUTO_THRESHOLD auto-attaches,
 *      >= REVIEW_THRESHOLD is only flagged "possible duplicate" for an admin)
 */
class MissionDeduplicator
{
    public const AUTO_THRESHOLD = 85;
    public const REVIEW_THRESHOLD = 70;

    /** Seconds to wait for a lock held by a concurrent ingestion. */
    public int $lockWait = 20;

    /** Max seconds a lock can be held (safety net if a worker dies). */
    public int $lockTtl = 90;

    // ------------------------------------------------------------------
    // Reference / title helpers
    // ------------------------------------------------------------------

    /**
     * Extract normalized job references (AO-3008, INT-12, QUE-29, O261234) from any text.
     *
     * @return string[]
     */
    public function extractReferences(?string ...$texts): array
    {
        $found = [];
        foreach ($texts as $text) {
            if (!$text) {
                continue;
            }
            if (preg_match_all('/\b(AO|INT|QUE)[\s\-_]?(\d{2,6})\b/i', $text, $m, PREG_SET_ORDER)) {
                foreach ($m as $hit) {
                    $found[] = strtoupper($hit[1]) . '-' . ltrim($hit[2], '0');
                }
            }
            if (preg_match_all('/\bO26\d{2,6}\b/i', $text, $m)) {
                foreach ($m[0] as $hit) {
                    $found[] = strtoupper($hit);
                }
            }
        }

        return array_values(array_unique($found));
    }

    public function normalizeTitle(?string $title): string
    {
        $t = Str::lower(Str::ascii((string) $title));
        // strip reply / forward prefixes (Re:, Fwd:, Tr:, Rv:, Fw:, Aw:, Wg:)
        $t = preg_replace('/^(\s*(re|fwd?|tr|rv|aw|wg)\s*:\s*)+/i', '', $t);
        $t = preg_replace('/[^a-z0-9\s]/', ' ', $t);

        return trim(preg_replace('/\s+/', ' ', $t));
    }

    public function titleSimilarity(?string $a, ?string $b): float
    {
        $a = $this->normalizeTitle($a);
        $b = $this->normalizeTitle($b);
        if ($a === '' || $b === '') {
            return 0.0;
        }
        similar_text($a, $b, $percent);

        return round($percent, 1);
    }

    /** References carried by a stored mission (reference column + titles). */
    public function missionReferences(Mission $mission): array
    {
        return $this->extractReferences($mission->reference, $mission->title, $mission->title_fr);
    }

    // ------------------------------------------------------------------
    // Matching
    // ------------------------------------------------------------------

    /**
     * Look for an open mission the new request duplicates.
     *
     * @param  string[]  $refs       references found in the new request
     * @param  string[]  $threadIds  thread ids of the conversation
     * @return array{mission: Mission, reason: string, score: int, auto: bool}|null
     */
    public function findMatch(array $refs, array $threadIds, ?int $buildingId, ?string $title, ?int $excludeMissionId = null): ?array
    {
        // 1. Same job reference
        foreach ($refs as $ref) {
            $mission = $this->findByReference($ref, $excludeMissionId);
            if ($mission) {
                $this->warnOnBuildingMismatch($mission, $buildingId, "reference {$ref}");

                return ['mission' => $mission, 'reason' => 'reference', 'score' => 100, 'auto' => true];
            }
        }

        // 2. Same thread (only when the two do not carry different job references)
        $threadIds = array_values(array_filter(array_unique($threadIds)));
        if ($threadIds) {
            $candidates = Mission::open()->whereIn('thread_id', $threadIds)
                ->when($excludeMissionId, fn ($q) => $q->where('id', '!=', $excludeMissionId))
                ->orderBy('id')->get();
            foreach ($candidates as $mission) {
                $theirs = $this->missionReferences($mission);
                if ($refs && $theirs && !array_intersect($refs, $theirs)) {
                    continue; // same thread but a clearly different job
                }
                $this->warnOnBuildingMismatch($mission, $buildingId, 'thread');

                return ['mission' => $mission, 'reason' => 'thread', 'score' => 100, 'auto' => true];
            }
        }

        // 3. Same building + similar title
        if ($buildingId && $title) {
            $best = null;
            $candidates = Mission::open()->where('building_id', $buildingId)
                ->when($excludeMissionId, fn ($q) => $q->where('id', '!=', $excludeMissionId))
                ->orderBy('id')->get();
            foreach ($candidates as $mission) {
                $score = max(
                    $this->titleSimilarity($title, $mission->title),
                    $this->titleSimilarity($title, $mission->title_fr)
                );
                // oldest wins ties, so only replace on a strictly better score
                if ($score >= self::REVIEW_THRESHOLD && (!$best || $score > $best['score'])) {
                    $best = ['mission' => $mission, 'reason' => 'building_title', 'score' => (int) round($score)];
                }
            }
            if ($best) {
                $best['auto'] = $best['score'] >= self::AUTO_THRESHOLD;

                return $best;
            }
        }

        return null;
    }

    protected function findByReference(string $ref, ?int $excludeMissionId = null): ?Mission
    {
        // narrow in SQL on the numeric part, confirm the normalized reference in PHP
        $digits = preg_replace('/\D/', '', $ref);
        $needle = $digits !== '' ? ltrim($digits, '0') : $ref;

        $candidates = Mission::open()
            ->where(function ($q) use ($needle) {
                $q->where('reference', 'like', "%{$needle}%")
                  ->orWhere('title', 'like', "%{$needle}%")
                  ->orWhere('title_fr', 'like', "%{$needle}%");
            })
            ->when($excludeMissionId, fn ($q) => $q->where('id', '!=', $excludeMissionId))
            ->orderBy('id')->get();

        foreach ($candidates as $mission) {
            if (in_array($ref, $this->missionReferences($mission), true)) {
                return $mission;
            }
        }

        return null;
    }

    protected function warnOnBuildingMismatch(Mission $mission, ?int $buildingId, string $via): void
    {
        if ($buildingId && $mission->building_id && (int) $mission->building_id !== $buildingId) {
            Log::warning("Mission dedup: matched mission #{$mission->id} via {$via} but the AI chose building #{$buildingId} (mission has #{$mission->building_id}); keeping the mission's building.");
        }
    }

    // ------------------------------------------------------------------
    // Attach / merge
    // ------------------------------------------------------------------

    /**
     * Attach a new email (and its thread's attachments) to an existing mission as an update.
     */
    public function attach(Mission $mission, Email $email, iterable $threadEmails, array $aiData, array $match): MissionUpdate
    {
        $missionData = $aiData['mission'] ?? [];
        $summary = $missionData['description']['fr']
            ?? (is_string($missionData['description'] ?? null) ? $missionData['description'] : null)
            ?? $email->body_text;

        $update = MissionUpdate::firstOrCreate(
            ['mission_id' => $mission->id, 'source_message_id' => $email->message_id],
            [
                'email_id' => $email->id,
                'type' => 'EMAIL_UPDATE',
                'match_reason' => $match['reason'],
                'match_score' => $match['score'],
                'subject' => Str::limit((string) $email->subject, 250, ''),
                'summary' => Str::limit(trim((string) $summary), 2000, '…'),
                'data' => ['classification' => $aiData['classification'] ?? null, 'reasons' => $aiData['reasons'] ?? []],
            ]
        );

        $this->copyAttachments($mission, $threadEmails);

        // keep the mission's thread id so later replies resolve straight to it
        if (!$mission->thread_id) {
            $mission->thread_id = $email->thread_id ?: $email->message_id;
        }

        // fill gaps from the follow-up, never overwrite what is already there
        $reference = $missionData['reference'] ?? null;
        if (!$mission->reference && $reference) {
            $mission->reference = $reference;
        }
        $mission->touch();
        $mission->save();

        Log::info("Mission dedup: email #{$email->id} attached to mission #{$mission->id} as update #{$update->id}", [
            'reason' => $match['reason'], 'score' => $match['score'],
        ]);

        return $update;
    }

    protected function copyAttachments(Mission $mission, iterable $emails): void
    {
        $existing = $mission->documents()->pluck('file_path')->all();
        foreach ($emails as $e) {
            foreach ($e->attachments as $attachment) {
                if (in_array($attachment->file_path, $existing, true)) {
                    continue;
                }
                $mission->documents()->create([
                    'file_path' => $attachment->file_path,
                    'file_name' => $attachment->file_name,
                    'file_type' => $attachment->mime_type,
                ]);
                $existing[] = $attachment->file_path;
            }
        }
    }

    /**
     * Merge $duplicate into $keeper, then delete $duplicate.
     * Documents, updates, assignments, contacts and review flags are moved over;
     * a snapshot of the merged mission is kept in mission_updates (type MERGED_DUPLICATE).
     */
    public function merge(Mission $keeper, Mission $duplicate): Mission
    {
        if ($keeper->id === $duplicate->id) {
            return $keeper;
        }

        return DB::transaction(function () use ($keeper, $duplicate) {
            // documents (skip files the keeper already has)
            $have = $keeper->documents()->pluck('file_path')->all();
            foreach ($duplicate->documents()->get() as $doc) {
                if (in_array($doc->file_path, $have, true)) {
                    $doc->delete();
                } else {
                    $doc->update(['documentable_id' => $keeper->id, 'documentable_type' => Mission::class]);
                    $have[] = $doc->file_path;
                }
            }

            // follow-ups the duplicate already collected
            $keeperMessages = $keeper->updates()->pluck('source_message_id')->all();
            foreach ($duplicate->updates()->get() as $u) {
                if (in_array($u->source_message_id, $keeperMessages, true)) {
                    $u->delete();
                } else {
                    $u->update(['mission_id' => $keeper->id]);
                }
            }

            Contact::where('mission_id', $duplicate->id)->update(['mission_id' => $keeper->id]);
            DB::table('assignments')->where('mission_id', $duplicate->id)->update(['mission_id' => $keeper->id]);
            Mission::where('possible_duplicate_of_id', $duplicate->id)->update(['possible_duplicate_of_id' => $keeper->id]);

            // the duplicate's own source email becomes an update of the keeper (history is kept)
            MissionUpdate::firstOrCreate(
                ['mission_id' => $keeper->id, 'source_message_id' => $duplicate->source_message_id],
                [
                    'email_id' => Email::where('message_id', $duplicate->source_message_id)->value('id'),
                    'type' => 'MERGED_DUPLICATE',
                    'match_reason' => 'merge',
                    'match_score' => $duplicate->duplicate_score,
                    'subject' => Str::limit((string) $duplicate->title, 250, ''),
                    'summary' => Str::limit((string) $duplicate->description, 2000, '…'),
                    'data' => ['merged_mission' => $duplicate->getAttributes()],
                ]
            );

            // fill blanks on the keeper
            foreach (['building_id', 'syndic_id', 'assigned_user_id', 'reference', 'extracted_syndic_name', 'extracted_address', 'thread_id',
                      'on_site_contact_name', 'on_site_contact_phone', 'on_site_contact_email'] as $field) {
                if (empty($keeper->{$field}) && !empty($duplicate->getAttributes()[$field] ?? null)) {
                    $keeper->{$field} = $duplicate->getAttributes()[$field];
                }
            }
            if ($keeper->possible_duplicate_of_id === $duplicate->id) {
                $keeper->possible_duplicate_of_id = null;
                $keeper->duplicate_score = null;
            }
            $keeper->save();

            $duplicateId = $duplicate->id;
            $duplicate->delete();

            Log::info("Mission dedup: mission #{$duplicateId} merged into #{$keeper->id}");

            return $keeper->fresh();
        });
    }

    // ------------------------------------------------------------------
    // Locking (prevents concurrent workers creating the same mission)
    // ------------------------------------------------------------------

    /**
     * Run $callback while holding a named lock for every key. Keys are taken in
     * sorted order (no deadlocks) and released only after $callback returns, so a
     * DB transaction opened inside it is already committed when the next worker
     * gets the lock and runs its duplicate check.
     *
     * @param  string[]  $keys
     * @throws LockTimeoutException when another ingestion holds a key for too long
     */
    public function withLocks(array $keys, callable $callback)
    {
        $keys = array_values(array_unique($keys));
        sort($keys);

        $held = [];
        try {
            foreach ($keys as $key) {
                $lock = Cache::lock('mission-ingest:' . $key, $this->lockTtl);
                $lock->block($this->lockWait);
                $held[] = $lock;
            }

            return $callback();
        } finally {
            foreach (array_reverse($held) as $lock) {
                $lock->release();
            }
        }
    }

    public function addressKey(?string $raw): ?string
    {
        $n = $this->normalizeTitle($raw);

        return $n === '' ? null : 'addr:' . md5($n);
    }

    // ------------------------------------------------------------------
    // One-time cleanup support
    // ------------------------------------------------------------------

    /**
     * Group the existing open missions that duplicate each other, using the same
     * rules as ingestion (reference, thread, same building + title >= AUTO_THRESHOLD).
     *
     * @return array<int, int[]> groups of mission ids, each sorted oldest first (groups of 2+ only)
     */
    public function findDuplicateGroups(): array
    {
        $missions = Mission::open()->orderBy('id')->get();

        // resolve each mission's thread through its source email
        $messageIds = $missions->pluck('source_message_id')->filter()->unique()->all();
        $threadByMessage = [];
        foreach (array_chunk($messageIds, 500) as $chunk) {
            foreach (Email::whereIn('message_id', $chunk)->get(['message_id', 'thread_id']) as $e) {
                $threadByMessage[$e->message_id] = $e->thread_id ?: $e->message_id;
            }
        }

        $parent = [];
        $find = function ($x) use (&$parent, &$find) {
            while ($parent[$x] !== $x) {
                $parent[$x] = $parent[$parent[$x]];
                $x = $parent[$x];
            }

            return $x;
        };
        $union = function ($a, $b) use (&$parent, $find) {
            $ra = $find($a);
            $rb = $find($b);
            if ($ra !== $rb) {
                // the oldest id is always the root
                $parent[max($ra, $rb)] = min($ra, $rb);
            }
        };

        $byRef = [];
        $byThread = [];
        $byBuilding = [];
        $refsOf = [];
        foreach ($missions as $m) {
            $parent[$m->id] = $m->id;
            $refsOf[$m->id] = $this->missionReferences($m);
            foreach ($refsOf[$m->id] as $ref) {
                $byRef[$ref][] = $m->id;
            }
            $thread = $m->thread_id ?: ($threadByMessage[$m->source_message_id] ?? null);
            if ($thread) {
                $byThread[$thread][] = $m->id;
            }
            if ($m->building_id) {
                $byBuilding[$m->building_id][] = $m;
            }
        }

        foreach ($byRef as $ids) {
            foreach ($ids as $id) {
                $union($ids[0], $id);
            }
        }
        foreach ($byThread as $ids) {
            // same thread, unless the missions carry clearly different job references
            for ($i = 1; $i < count($ids); $i++) {
                $a = $refsOf[$ids[0]];
                $b = $refsOf[$ids[$i]];
                if ($a && $b && !array_intersect($a, $b)) {
                    continue;
                }
                $union($ids[0], $ids[$i]);
            }
        }
        foreach ($byBuilding as $list) {
            for ($i = 0; $i < count($list); $i++) {
                for ($j = $i + 1; $j < count($list); $j++) {
                    $score = max(
                        $this->titleSimilarity($list[$i]->title, $list[$j]->title),
                        $this->titleSimilarity($list[$i]->title_fr, $list[$j]->title_fr)
                    );
                    if ($score >= self::AUTO_THRESHOLD) {
                        $union($list[$i]->id, $list[$j]->id);
                    }
                }
            }
        }

        $groups = [];
        foreach (array_keys($parent) as $id) {
            $groups[$find($id)][] = $id;
        }

        $groups = array_filter($groups, fn ($g) => count($g) > 1);
        foreach ($groups as &$g) {
            sort($g);
        }
        ksort($groups);

        return array_values($groups);
    }
}
