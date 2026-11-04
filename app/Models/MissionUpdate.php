<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * A follow-up (reply, forward, reminder...) attached to an existing mission
 * instead of creating a duplicate mission.
 */
class MissionUpdate extends Model
{
    protected $guarded = [];

    protected $casts = ['data' => 'array'];

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }

    public function email()
    {
        return $this->belongsTo(Email::class);
    }
}
