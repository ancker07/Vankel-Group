<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MaintenancePlan extends Model
{
    protected $fillable = [
        'building_id',
        'syndic_id',
        'title',
        'title_en',
        'title_fr',
        'title_nl',
        'description',
        'description_en',
        'description_fr',
        'description_nl',
        'frequency',
        'interval',
        'start_date',
        'end_date',
        'status',
    ];

    protected $casts = [
        'start_date' => 'datetime',
        'end_date' => 'datetime',
    ];

    public function building()
    {
        return $this->belongsTo(Building::class);
    }

    public function syndic()
    {
        return $this->belongsTo(Syndic::class);
    }

    public function interventions()
    {
        return $this->hasMany(Intervention::class);
    }
}
