<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Mission extends Model
{
    //
    protected $guarded = [];

    protected $appends = ['source_details'];

    public function documents()
    {
        return $this->morphMany(Document::class, 'documentable');
    }

    public function syndic()
    {
        return $this->belongsTo(Syndic::class);
    }

    public function email()
    {
        return $this->belongsTo(Email::class, 'source_message_id', 'message_id');
    }

    public function getSourceDetailsAttribute()
    {
        if ($this->source_type === 'EMAIL' && $this->email) {
            return [
                'from' => $this->email->from_address,
                'subject' => $this->email->subject,
                'receivedAt' => $this->email->received_at,
            ];
        }
        return null;
    }
}


