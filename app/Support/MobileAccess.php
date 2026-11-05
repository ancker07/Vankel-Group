<?php

namespace App\Support;

use App\Models\Setting;
use Illuminate\Http\Request;

/**
 * The super admin's master switch for the mobile app. While it is off, every API request that comes
 * from the phone app is refused (the website is not affected).
 */
class MobileAccess
{
    public const KEY = 'mobile_access_enabled';

    public static function enabled(): bool
    {
        return Setting::where('key', self::KEY)->value('value') !== '0'; // on unless switched off
    }

    public static function set(bool $enabled): void
    {
        Setting::updateOrCreate(['key' => self::KEY], ['value' => $enabled ? '1' : '0']);
    }

    /** True for requests made by the phone app (it sends X-App: mobile; Dart's HTTP client is also recognised). */
    public static function isMobileRequest(Request $request): bool
    {
        return strtolower((string) $request->header('X-App')) === 'mobile'
            || strtolower((string) $request->input('app')) === 'mobile'
            || str_contains((string) $request->userAgent(), 'Dart/');
    }
}
