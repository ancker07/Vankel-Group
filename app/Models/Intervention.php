<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Intervention extends Model
{
    //
    protected $guarded = [];

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
}


