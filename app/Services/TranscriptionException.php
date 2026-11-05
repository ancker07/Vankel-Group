<?php

namespace App\Services;

/**
 * $status tells the apps what to do: 503 = not usable here (switch to the device's recognition),
 * 422 = this audio cannot be read (skip it), 502 = temporary (try again).
 */
class TranscriptionException extends \RuntimeException
{
    public function __construct(public readonly int $status, string $message = '')
    {
        parent::__construct($message);
    }
}
