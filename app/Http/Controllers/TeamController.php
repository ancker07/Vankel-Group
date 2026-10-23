<?php

namespace App\Http\Controllers;

use App\Models\Assignment;
use App\Models\User;
use Illuminate\Http\Request;

class TeamController extends Controller
{
    /**
     * List team members (admins + professionals) with their last known position.
     */
    public function index()
    {
        $users = User::staff()
            ->where('status', '!=', 'DEACTIVATED')
            ->orderBy('name')
            ->get(['id', 'name', 'email', 'phone', 'role', 'status', 'image_url', 'latitude', 'longitude', 'location_updated_at']);

        return response()->json($users);
    }

    /**
     * The mobile app sends the current user's position here.
     */
    public function updateLocation(Request $request)
    {
        $validated = $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $request->user()->update([
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'location_updated_at' => now(),
        ]);

        return response()->json(['success' => true]);
    }

    /**
     * Who was assigned to an intervention, and when (most recent first).
     */
    public function interventionAssignments($id)
    {
        $history = Assignment::with(['user:id,name,email,phone', 'assignedBy:id,name'])
            ->where('intervention_id', $id)
            ->orderByDesc('assigned_at')
            ->get();

        return response()->json($history);
    }
}
