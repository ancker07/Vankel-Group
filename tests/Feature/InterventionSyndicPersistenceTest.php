<?php

namespace Tests\Feature;

use App\Models\Building;
use App\Models\Mission;
use App\Models\Intervention;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InterventionSyndicPersistenceTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_copies_extracted_syndic_name_from_mission_to_intervention()
    {
        // 1. Setup - Create an admin user, a building, and a mission with extracted syndic
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'role' => 'ADMIN',
            'status' => 'APPROVED'
        ]);
        $building = Building::create([
            'address' => '123 Test St',
            'city' => 'Test City',
        ]);
        
        $mission = Mission::create([
            'building_id' => $building->id,
            'title' => 'Test Mission',
            'description' => 'Test Description',
            'status' => 'PENDING',
            'urgency' => 'MEDIUM',
            'extracted_syndic_name' => 'Syndic Example Inc.',
            'category' => 'Repair',
            'sector' => 'GENERAL',
            'requested_by' => 'Tenant'
        ]);

        // 2. Act - Call approve mission endpoint (InterventionController@approveMission)
        $pro = User::create([
            'name' => 'Pro User',
            'email' => 'pro@example.com',
            'password' => bcrypt('password'),
            'role' => 'PROFESSIONAL',
            'status' => 'APPROVED'
        ]);

        $response = $this->actingAs($admin)->postJson("/api/missions/{$mission->id}/approve", [
            'scheduled_date' => now()->addDay()->toDateTimeString(),
            'pro_id' => $pro->id
        ]);

        // 3. Assert - Check if intervention was created and has the same syndic name
        $response->assertStatus(200);
        
        $intervention = Intervention::where('building_id', $building->id)->first();
        $this->assertNotNull($intervention);
        $this->assertEquals('Syndic Example Inc.', $intervention->extracted_syndic_name);
        
        // Also check if Mission still has it
        $this->assertEquals('Syndic Example Inc.', $mission->fresh()->extracted_syndic_name);
    }
}
