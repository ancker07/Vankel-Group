<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationLog extends Model
{
    protected $fillable = [
        'title',
        'body',
        'target',
        'total_recipients',
        'success_count',
        'data',
    ];

    protected $casts = [
        'data' => 'array',
    ];
}
