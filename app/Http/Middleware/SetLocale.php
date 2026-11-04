<?php

namespace App\Http\Middleware;

use App\Support\MessageText;
use Closure;
use Illuminate\Http\Request;

/**
 * Answers every API request in the language the user selected, so validation errors and the
 * messages the server returns follow the app language (mobile app and website).
 *
 * Order: the language the app is showing right now (Accept-Language header), then the language
 * saved on the user's account, then the application default.
 */
class SetLocale
{
    public function handle(Request $request, Closure $next)
    {
        app()->setLocale(self::resolve($request));

        return $next($request);
    }

    public static function resolve(Request $request): string
    {
        $header = strtolower(substr((string) $request->header('Accept-Language'), 0, 2));
        if (in_array($header, MessageText::LOCALES, true)) {
            return $header;
        }

        $saved = $request->user('sanctum')?->locale;

        return MessageText::normalize($saved);
    }
}
