<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsurePermission
{
    /**
     * Allow the request only if the Sanctum-authenticated user's role has one of the given permissions.
     * Usage: ->middleware('permission:missions.approve') or ->middleware('permission:missions.create,interventions.create')
     * With no permission listed (->middleware('permission')) any logged-in, active user is allowed.
     */
    public function handle(Request $request, Closure $next, string ...$permissions)
    {
        $user = auth('sanctum')->user();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated.'], 401);
        }

        if (!$user->isSuperAdmin() && $user->status === 'DEACTIVATED') {
            return response()->json(['success' => false, 'message' => 'Your account has been deactivated.'], 403);
        }

        if (!empty($permissions) && !$user->hasPermission(...$permissions)) {
            return response()->json(['success' => false, 'message' => 'You are not allowed to perform this action.'], 403);
        }

        $request->setUserResolver(fn () => $user);

        return $next($request);
    }
}
