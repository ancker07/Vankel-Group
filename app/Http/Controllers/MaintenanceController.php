<?php

namespace App\Http\Controllers;

use App\Models\MaintenancePlan;
use App\Models\Syndic;
use Illuminate\Http\Request;

class MaintenanceController extends Controller
{
    public function index(Request $request)
    {
        $query = MaintenancePlan::with(['building', 'syndic']);

        // Check for role-based filtering via headers (common in this project's style)
        $role = $request->header('X-User-Role');
        $email = $request->header('X-User-Email');

        if ($role === 'SYNDIC' && $email) {
            $syndic = Syndic::where('email', $email)->first();
            if ($syndic) {
                $query->where('syndic_id', $syndic->id);
            }
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'buildingId' => 'required|exists:buildings,id',
            'title' => 'required|string',
            'description' => 'nullable|string',
            'recurrence.frequency' => 'required|in:YEARLY,QUARTERLY,MONTHLY',
            'recurrence.interval' => 'required',
            'recurrence.startDate' => 'required',
            'recurrence.endDate' => 'required',
            'syndicId' => 'nullable'
        ]);

        $plan = MaintenancePlan::create([
            'building_id' => $validated['buildingId'],
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'frequency' => $validated['recurrence']['frequency'],
            'interval' => $validated['recurrence']['interval'] ?? 1,
            'start_date' => $validated['recurrence']['startDate'],
            'end_date' => $validated['recurrence']['endDate'],
            'syndic_id' => $validated['syndicId'] ?? null,
            'status' => 'ACTIVE',
        ]);

        return response()->json($plan, 201);
    }

    public function update(Request $request, $id)
    {
        $plan = MaintenancePlan::findOrFail($id);
        
        $data = $request->all();
        
        // Handle nested recurrence mapping
        if (isset($data['recurrence'])) {
            if (isset($data['recurrence']['frequency'])) $data['frequency'] = $data['recurrence']['frequency'];
            if (isset($data['recurrence']['interval'])) $data['interval'] = $data['recurrence']['interval'];
            if (isset($data['recurrence']['startDate'])) $data['start_date'] = $data['recurrence']['startDate'];
            if (isset($data['recurrence']['endDate'])) $data['end_date'] = $data['recurrence']['endDate'];
            unset($data['recurrence']);
        }
        
        // Map camelCase to snake_case
        if (isset($data['buildingId'])) $data['building_id'] = $data['buildingId'];
        if (isset($data['syndicId'])) $data['syndic_id'] = $data['syndicId'];

        $plan->update($data);
        return response()->json($plan);
    }

    public function destroy($id)
    {
        $plan = MaintenancePlan::findOrFail($id);
        $plan->delete();
        return response()->json(null, 204);
    }
}
