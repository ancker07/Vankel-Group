<?php

namespace App\Support;

use Illuminate\Support\Str;

/**
 * One upload policy for the whole API, so the web app, the mobile app and every
 * endpoint agree on what can be uploaded (a mismatch makes the whole save fail
 * with a 422 after the user already picked the file).
 */
class UploadRules
{
    /** Documents: what the web and mobile pickers offer. */
    public const DOCUMENT_MIMES = 'jpg,jpeg,png,webp,pdf,doc,docx,xls,xlsx,txt';

    /** Max size per file, in kilobytes (10 MB). */
    public const MAX_KB = 10240;

    /** Profile pictures (the apps resize them before upload). */
    public const AVATAR_MAX_KB = 5120;

    /** Extensions we accept from incoming emails; anything else is stored as .bin. */
    public const SAFE_EXTENSIONS = [
        'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp',
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'csv', 'txt', 'rtf',
        'zip', 'eml', 'msg',
    ];

    /** Validation rules for the `files[]` and `photos[]` form fields. */
    public static function fileFields(): array
    {
        return [
            'files' => 'nullable|array',
            'files.*' => 'file|mimes:' . self::DOCUMENT_MIMES . '|max:' . self::MAX_KB,
            'photos' => 'nullable|array',
            'photos.*' => 'file|image|mimes:jpg,jpeg,png,webp|max:' . self::MAX_KB,
        ];
    }

    /**
     * File name that is safe to store and to put in a URL: only letters, digits, dot,
     * dash and underscore, and an extension from the allow-list (an attachment called
     * "invoice.php" or "x.html" must never end up executable / renderable in public storage).
     */
    public static function safeFileName(?string $original, ?string $fallbackBase = 'file'): string
    {
        $original = trim((string) $original);
        $ext = strtolower(pathinfo($original, PATHINFO_EXTENSION));
        $base = pathinfo($original, PATHINFO_FILENAME);

        $base = Str::of(Str::ascii($base))->replaceMatches('/[^A-Za-z0-9._-]+/', '_')->trim('._-')->limit(80, '')->toString();
        if ($base === '') {
            $base = $fallbackBase ?: 'file';
        }
        if (!in_array($ext, self::SAFE_EXTENSIONS, true)) {
            $ext = 'bin';
        }

        return $base . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    }
}
