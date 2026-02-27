<?php

namespace App\Mail;

use App\Models\Intervention;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Attachment;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;

class InterventionReportMail extends Mailable
{
    use Queueable, SerializesModels;

    public $intervention;
    public $building;
    public $syndic;
    public $professional;

    /**
     * Create a new message instance.
     */
    public function __construct(Intervention $intervention)
    {
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
            subject: "Rapport d'intervention : " . $this->intervention->title . " - " . $this->building->address,
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
