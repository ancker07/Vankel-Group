<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Contact extends Model
{
    protected $guarded = [];

    protected $casts = [
        'extracted_data' => 'array',
    ];

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }
}
