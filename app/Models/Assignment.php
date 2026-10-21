<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Assignment extends Model
{
    protected $guarded = [];

    protected $casts = [
        'assigned_at' => 'datetime',
        'unassigned_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function assignedBy()
    {
        return $this->belongsTo(User::class, 'assigned_by');
    }

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }

    public function intervention()
    {
        return $this->belongsTo(Intervention::class);
    }

    /**
     * Close the current assignment of an intervention and open a new one for $userId.
     */
    public static function record(?int $interventionId, ?int $missionId, ?int $userId, ?int $assignedBy): void
    {
        if ($interventionId) {
            static::where('intervention_id', $interventionId)->whereNull('unassigned_at')->update(['unassigned_at' => now()]);
        }

        if ($userId) {
            static::create([
                'intervention_id' => $interventionId,
                'mission_id' => $missionId,
                'user_id' => $userId,
                'assigned_by' => $assignedBy,
                'assigned_at' => now(),
            ]);
        }
    }
}
