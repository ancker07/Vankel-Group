<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ReplyEmail extends Mailable
{
    public $replyBody;
    public $replySubject;
    public $messageId;
    public $references;
    public $fromAddress;
    public $attachmentsList;

    /**
     * Create a new message instance.
     */
    public function __construct($replyBody, $replySubject, $messageId = null, $references = null, $attachments = [], $fromAddress = null)
    {
        $this->replyBody = $replyBody;
        $this->replySubject = $replySubject;
        $this->messageId = $messageId;
        $this->references = $references;
        $this->attachmentsList = $attachments;
        $this->fromAddress = $fromAddress;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            from: $this->fromAddress,
            subject: $this->replySubject,
            tags: ['reply'],
        );
    }

    /**
     * Get the message headers.
     */
    public function headers(): \Illuminate\Mail\Mailables\Headers
    {
        return new \Illuminate\Mail\Mailables\Headers(
            messageId: null,
            references: $this->references ? [$this->references] : [],
            text: [
                'In-Reply-To' => $this->messageId,
            ],
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.reply',
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        $mailAttachments = [];
        foreach ($this->attachmentsList as $filePath) {
            $mailAttachments[] = \Illuminate\Mail\Mailables\Attachment::fromPath($filePath);
        }
        return $mailAttachments;
    }
}
