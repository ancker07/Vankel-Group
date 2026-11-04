<?php

namespace App\Mail;

use App\Models\Intervention;
use App\Support\MessageText;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Mail\Mailables\Attachment;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;

class InterventionReportMail extends Mailable
{
    use SerializesModels;

    public $intervention;
    public $building;
    public $syndic;
    public $professional;
    public string $lang = 'fr';
    public array $t = [];

    /**
     * Create a new message instance.
     */
    public function __construct(Intervention $intervention, string $locale = 'fr')
    {
        $this->lang = MessageText::normalize($locale);
        $this->t = MessageText::report($this->lang);
        $this->intervention = $intervention;
        $this->building = $intervention->building;
        $this->syndic = $this->building->syndic ?? null;
        $this->professional = $intervention->professional ?? null;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            from: new Address(config('mail.from.address'), config('mail.from.name')),
            subject: strtr($this->t['subject'], [
                '{title}' => MessageText::field($this->intervention, 'title', $this->lang),
                '{address}' => $this->building->address,
            ]),
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.reports.intervention',
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        $attachments = [];

        foreach ($this->intervention->documents as $doc) {
            if (Storage::disk('public')->exists($doc->file_path)) {
                $attachments[] = Attachment::fromPath(Storage::disk('public')->path($doc->file_path))
                    ->as($doc->file_name);
            }
        }

        return $attachments;
    }
}
