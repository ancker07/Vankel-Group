<?php

namespace App\Http\Controllers;

use App\Models\Assignment;
use App\Models\Intervention;
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
     * The team member currently on an intervention, who assigned them, and their live position.
     */
    public function interventionTracking($id)
    {
        $intervention = Intervention::findOrFail($id);

        $current = Assignment::with('assignedBy:id,name')
            ->where('intervention_id', $intervention->id)
            ->whereNull('unassigned_at')
            ->latest('assigned_at')
            ->first();

        $userId = $current?->user_id ?? $intervention->pro_id;
        $member = $userId
            ? User::find($userId, ['id', 'name', 'phone', 'email', 'role', 'latitude', 'longitude', 'location_updated_at'])
            : null;

        return response()->json([
            'member' => $member,
            'assigned_by' => $current?->assignedBy?->only(['id', 'name']),
            'assigned_at' => $current?->assigned_at,
        ]);
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
