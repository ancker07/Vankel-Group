<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Mission extends Model
{
    //
    protected $guarded = [];

    protected $appends = ['source_details', 'timestamp', 'buildingId', 'syndicId'];

    public function documents()
    {
        return $this->morphMany(Document::class, 'documentable');
    }

    public function building()
    {
        return $this->belongsTo(Building::class);
    }

    public function syndic()
    {
        return $this->belongsTo(Syndic::class);
    }

    public function email()
    {
        return $this->belongsTo(Email::class, 'source_message_id', 'message_id');
    }

    public function contact()
    {
        return $this->belongsTo(Contact::class, 'source_message_id');
    }

    public function getTimestampAttribute()
    {
        return $this->created_at->toIso8601String();
    }

    public function getBuildingIdAttribute()
    {
        return $this->attributes['building_id'] ?? null;
    }

    public function getSyndicIdAttribute()
    {
        return $this->attributes['syndic_id'] ?? null;
    }

    public function getSourceDetailsAttribute()
    {
        // Avoid relationship loading if source_type doesn't match
        if ($this->source_type === 'EMAIL') {
            $email = $this->email;
            if ($email) {
                return [
                    'from' => $email->from_address,
                    'subject' => $email->subject,
                    'receivedAt' => $email->received_at ? $email->received_at->toIso8601String() : null,
                ];
            }
        }

        if ($this->source_type === 'CONTACT_FORM') {
            $contact = $this->contact;
            if ($contact) {
                return [
                    'from' => $contact->name . ' (' . $contact->email . ')',
                    'subject' => $contact->subject,
                    'receivedAt' => $contact->created_at ? $contact->created_at->toIso8601String() : null,
                ];
            }
        }

        return null;
    }
}


