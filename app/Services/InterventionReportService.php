<?php

namespace App\Services;

use App\Mail\InterventionReportMail;
use App\Models\Assignment;
use App\Models\Email;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\Syndic;
use App\Models\User;
use App\Support\MessageText;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Sends the intervention report e-mail.
 *
 * Who gets it: the office, the on-site contact, the syndic (company and account), the building's
 * syndic, the assigned technician, and the person who asked for the work (the sender of the
 * original e-mail / the requester of the mission this intervention came from).
 *
 * Every recipient gets their own e-mail, in their own language. One address that the mail server
 * rejects never stops the others: the result lists who received it and who did not, and why.
 */
class InterventionReportService
{
    public const OFFICE_ADDRESS = 'admin@vanakelgroup.com';

    /**
     * @return array<string, string> e-mail address => why this person gets the report
     */
    public function recipients(Intervention $intervention): array
    {
        $intervention->loadMissing(['building.syndic', 'syndic', 'professional']);

        $found = [];
        $add = function (?string $email, string $reason) use (&$found) {
            $email = trim((string) $email);
            if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                return;
            }
            $found[strtolower($email)] ??= ['email' => $email, 'reason' => $reason];
        };

        $add(self::OFFICE_ADDRESS, 'office');
        $add($intervention->on_site_contact_email, 'on_site_contact');

        // the assigned technician
        $add($intervention->professional?->email, 'technician');

        // the requesting syndic: company record and/or account (syndic_id is shared by both)
        $add($intervention->syndic?->email, 'syndic');
        if ($intervention->syndic_id) {
            $add(User::find($intervention->syndic_id)?->email, 'syndic');
        }
        $add($intervention->building?->syndic?->email, 'building_syndic');

        // the person who asked for the work: via the mission this intervention was created from
        $missionId = Assignment::where('intervention_id', $intervention->id)->whereNotNull('mission_id')->value('mission_id');
        $mission = $missionId ? Mission::find($missionId) : null;
        if ($mission) {
            $add($mission->on_site_contact_email, 'on_site_contact');
            if ($mission->syndic_id) {
                $add(Syndic::find($mission->syndic_id)?->email, 'requester');
                $add(User::find($mission->syndic_id)?->email, 'requester');
            }
            if ($mission->source_type === 'EMAIL' && $mission->source_message_id) {
                $add(Email::where('message_id', $mission->source_message_id)->value('from_address'), 'requester');
            }
        }

        return collect($found)->mapWithKeys(fn ($row) => [$row['email'] => $row['reason']])->all();
    }

    /**
     * @param  callable|null  $sender  fn (string $email, InterventionReportMail $mail): void (tests)
     * @return array{sent: string[], failed: array<int, array{email: string, error: string}>}
     */
    public function send(Intervention $intervention, ?callable $sender = null): array
    {
        $intervention->loadMissing(['building.syndic', 'syndic', 'professional', 'documents']);
        $recipients = $this->recipients($intervention);

        // saved languages of the people who have an account; others get the requesting syndic's, else French
        $locales = User::whereIn('email', array_keys($recipients))->pluck('locale', 'email')
            ->mapWithKeys(fn ($locale, $email) => [strtolower($email) => $locale])->all();
        $fallback = ($intervention->syndic_id ? User::find($intervention->syndic_id)?->locale : null) ?: 'fr';

        $sender ??= fn (string $email, InterventionReportMail $mail) => Mail::to($email)->send($mail);

        $sent = [];
        $failed = [];
        foreach (array_keys($recipients) as $email) {
            try {
                $locale = MessageText::normalize($locales[strtolower($email)] ?? $fallback);
                $sender($email, new InterventionReportMail($intervention, $locale));
                $sent[] = $email;
            } catch (\Throwable $e) {
                Log::error("Intervention report #{$intervention->id}: could not send to {$email}: " . $e->getMessage());
                $failed[] = ['email' => $email, 'error' => $e->getMessage()];
            }
        }

        Log::info("Intervention report #{$intervention->id}: sent to " . count($sent) . ', failed for ' . count($failed));

        return ['sent' => $sent, 'failed' => $failed];
    }
}
