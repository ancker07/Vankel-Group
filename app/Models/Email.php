<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Email extends Model
{
    use HasFactory;

    protected $guarded = ['id'];

    protected $casts = [
        'received_at' => 'datetime',
        'ingested_at' => 'datetime',
        'is_read' => 'boolean',
    ];

    public function attachments()
    {
        return $this->hasMany(EmailAttachment::class);
    }
}
