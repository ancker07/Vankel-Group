<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Building extends Model
{
    //
    protected $guarded = [];

    public function interventions()
    {
        return $this->hasMany(Intervention::class);
    }

    public function syndic()
    {
        return $this->belongsTo(Syndic::class);
    }
}

