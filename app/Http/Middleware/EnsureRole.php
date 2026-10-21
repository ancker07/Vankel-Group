<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureRole
{
    /**
     * Allow the request only if the Sanctum-authenticated user has one of the given roles.
     * Usage: ->middleware('role:SUPERADMIN') or ->middleware('role:ADMIN,SUPERADMIN')
     */
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = auth('sanctum')->user();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated.'], 401);
        }

        if (!in_array(strtoupper($user->role), array_map('strtoupper', $roles), true)) {
            return response()->json(['success' => false, 'message' => 'You are not allowed to perform this action.'], 403);
        }

        $request->setUserResolver(fn () => $user);

        return $next($request);
    }
}
