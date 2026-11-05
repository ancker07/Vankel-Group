<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Intervention extends Model
{
    //
    protected $guarded = [];
    
    protected $appends = ['extractedSyndicName', 'contact_fallback'];

    protected $casts = ['submitted_at' => 'datetime'];

    /** The technician who sent this work to the admin for review. */
    public function submitter()
    {
        return $this->belongsTo(User::class, 'submitted_by');
    }

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

    public function assignments()
    {
        return $this->hasMany(Assignment::class)->orderByDesc('assigned_at');
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

    /**
     * Phone / e-mail to reach the customer when the intervention's own on-site contact is incomplete: the original
     * mission's contact, the sender of the customer's e-mail, then the syndic. Never throws.
     *
     * @return array{phone: ?string, email: ?string}
     */
    public function getContactFallbackAttribute(): array
    {
        $phone = $this->on_site_contact_phone ?: null;
        $email = $this->on_site_contact_email ?: null;
        if ($phone && $email) {
            return ['phone' => $phone, 'email' => $email];
        }

        try {
            $missionId = Assignment::where('intervention_id', $this->id)->whereNotNull('mission_id')->value('mission_id');
            $mission = $missionId ? Mission::find($missionId) : null;
            $syndics = array_filter([$this->syndic, $this->building?->syndic]);

            $phone ??= $mission?->on_site_contact_phone ?: null;
            $email ??= $mission?->on_site_contact_email ?: null;
            if (!$email && $mission?->source_type === 'EMAIL' && $mission->source_message_id) {
                $email = Email::where('message_id', $mission->source_message_id)->value('from_address') ?: null;
            }
            foreach ($syndics as $syndic) {
                $phone ??= $syndic->phone ?: null;
                $email ??= $syndic->email ?: null;
            }
        } catch (\Throwable $e) {
            // a missing link must never break the intervention list
        }

        return ['phone' => $phone, 'email' => $email];
    }
}
