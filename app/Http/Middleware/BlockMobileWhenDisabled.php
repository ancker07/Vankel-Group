<?php

namespace App\Http\Middleware;

use App\Support\MobileAccess;
use Closure;
use Illuminate\Http\Request;

/**
 * Refuses every phone-app request while the super admin has switched mobile access off.
 * The status endpoint stays open so the app can tell when it may work again.
 */
class BlockMobileWhenDisabled
{
    public function handle(Request $request, Closure $next)
    {
        if (!$request->is('api/app-status') && MobileAccess::isMobileRequest($request) && !MobileAccess::enabled()) {
            return response()->json([
                'success' => false,
                'code' => 'MOBILE_DISABLED',
                'message' => __('The mobile app is currently switched off. Please try again later.'),
            ], 503);
        }

        return $next($request);
    }
}
