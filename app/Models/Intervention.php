<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Intervention extends Model
{
    //
    protected $guarded = [];
    
    protected $appends = ['extractedSyndicName'];

    public function building()
    {
        return $this->belongsTo(Building::class);
    }

    public function documents()
    {
        return $this->morphMany(Document::class, 'documentable');
    }

    public function professional()
    {
        return $this->belongsTo(User::class, 'pro_id');
    }

    public function syndic()
    {
        return $this->belongsTo(Syndic::class);
    }

    public function maintenancePlan()
    {
        return $this->belongsTo(MaintenancePlan::class);
    }

    public function getExtractedSyndicNameAttribute()
    {
        return $this->attributes['extracted_syndic_name'] ?? null;
    }
}

