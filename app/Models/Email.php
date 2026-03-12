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
        'extracted_data' => 'array',
    ];

    public function thread()
    {
        return $this->hasMany(Email::class, 'thread_id', 'thread_id')
            ->whereNotNull('thread_id')
            ->orderBy('received_at', 'asc');
    }

    /**
     * More aggressive thread discovery for existing data without thread_id
     */
    public function getConversation()
    {
        if ($this->thread_id) {
            return Email::where('thread_id', $this->thread_id)
                ->with('attachments')
                ->orderBy('received_at', 'asc')
                ->get();
        }

        // Fallback for missing thread_id: Find emails that reference this one or that this one references
        return Email::where(function($query) {
            $query->where('message_id', $this->message_id)
                  ->orWhere('in_reply_to', $this->message_id)
                  ->orWhere('thread_id', $this->message_id);
                  
            if ($this->in_reply_to) {
                $query->orWhere('message_id', $this->in_reply_to);
            }
        })->with('attachments')->orderBy('received_at', 'asc')->get();
    }

    public function attachments()
    {
        return $this->hasMany(EmailAttachment::class);
    }
}
