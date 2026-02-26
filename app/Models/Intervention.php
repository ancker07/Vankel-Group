<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Intervention extends Model
{
    //
    protected $guarded = [];

    public function documents()
    {
        return $this->morphMany(Document::class, 'documentable');
    }
}


