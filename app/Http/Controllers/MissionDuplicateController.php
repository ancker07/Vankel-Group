<?php

namespace App\Http\Controllers;

use App\Models\Mission;
use App\Services\MissionDeduplicator;
use Illuminate\Support\Facades\Log;

/**
 * Admin review of missions flagged "possible duplicate of mission #X".
 */
class MissionDuplicateController extends Controller
{
    /** Not a duplicate: clear the flag and keep both missions. */
    public function dismiss($id)
    {
        $mission = Mission::findOrFail($id);
        $mission->update(['possible_duplicate_of_id' => null, 'duplicate_score' => null]);
        Log::info("Mission dedup: possible-duplicate flag dismissed on mission #{$mission->id}");

        return response()->json($mission->fresh());
    }

    /** Confirmed duplicate: merge this mission into the one it was flagged against. */
    public function merge($id)
    {
        $mission = Mission::findOrFail($id);
        $target = $mission->possible_duplicate_of_id ? Mission::find($mission->possible_duplicate_of_id) : null;
        if (!$target) {
            return response()->json(['message' => 'This mission is not flagged as a duplicate of an existing mission.'], 422);
        }

        // the oldest mission is the one that survives
        [$keeper, $duplicate] = $target->id < $mission->id ? [$target, $mission] : [$mission, $target];
        $merged = app(MissionDeduplicator::class)->merge($keeper, $duplicate);

        return response()->json($merged);
    }
}
