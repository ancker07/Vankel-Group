<?php

namespace Tests\Feature;

use App\Models\Assignment;
use App\Models\Building;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AssignedWorkVisibilityTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role, array $attrs = []): User
    {
        return User::create(array_merge([
            'name' => $role.' user',
            'email' => strtolower($role).uniqid().'@test.com',
            'password' => 'password123',
            'role' => $role,
            'status' => 'APPROVED',
        ], $attrs));
    }

    private function makeMission(array $attrs = []): Mission
    {
        return Mission::create(array_merge([
            'title' => 'Leaking roof',
            'description' => 'Water is coming through the ceiling.',
            'requested_by' => 'SYNDIC',
            'urgency' => 'MEDIUM',
            'status' => 'APPROVED',
            'category' => 'GENERAL',
            'sector' => 'GENERAL',
        ], $attrs));
    }

    private function makeIntervention(array $attrs = []): Intervention
    {
        return Intervention::create(array_merge([
            'title' => 'Fix the leak',
            'description' => 'Repair the roof.',
            'urgency' => 'MEDIUM',
            'status' => 'PENDING',
            'category' => 'GENERAL',
            'sector' => 'GENERAL',
        ], $attrs));
    }

    public function test_professional_has_no_missions_section_at_all(): void
    {
        $professional = $this->makeUser('PROFESSIONAL');
        $mine = $this->makeMission(['assigned_user_id' => $professional->id]);

        Sanctum::actingAs($professional);

        // the Technician role is fixed and has no mission permission: not even his own missions
        $this->getJson('/api/missions')->assertForbidden();
        $this->getJson("/api/missions/{$mine->id}")->assertForbidden();
    }

    public function test_professional_only_gets_interventions_assigned_to_them(): void
    {
        $building = Building::create(['address' => 'Street 1']);

        $professional = $this->makeUser('PROFESSIONAL');
        $otherProfessional = $this->makeUser('PROFESSIONAL');

        $mine = $this->makeIntervention([
            'building_id' => $building->id,
            'pro_id' => $professional->id,
        ]);
        $theirs = $this->makeIntervention([
            'building_id' => $building->id,
            'pro_id' => $otherProfessional->id,
        ]);
        $unassigned = $this->makeIntervention(['building_id' => $building->id]);

        // An intervention can also be "mine" through the active assignment record.
        $viaAssignment = $this->makeIntervention(['building_id' => $building->id]);
        Assignment::record($viaAssignment->id, null, $professional->id, null);

        Sanctum::actingAs($professional);

        $this->getJson('/api/interventions')
            ->assertOk()
            ->assertJsonCount(2)
            ->assertJsonFragment(['id' => $mine->id])
            ->assertJsonFragment(['id' => $viaAssignment->id]);

        $this->getJson("/api/interventions/{$mine->id}")->assertOk();
        $this->getJson("/api/interventions/{$viaAssignment->id}")->assertOk();
        $this->getJson("/api/interventions/{$theirs->id}")->assertNotFound();
        $this->getJson("/api/interventions/{$unassigned->id}")->assertNotFound();

        $this->putJson("/api/interventions/{$theirs->id}", ['status' => 'DELAYED'])->assertForbidden();
        $this->putJson("/api/interventions/{$mine->id}", ['status' => 'DELAYED'])->assertOk();
    }

    public function test_admins_still_see_all_missions_and_interventions(): void
    {
        $admin = $this->makeUser('ADMIN');
        $professional = $this->makeUser('PROFESSIONAL');
        $building = Building::create(['address' => 'Street 1']);

        $this->makeMission(['assigned_user_id' => $professional->id]);
        $this->makeMission();
        $this->makeIntervention(['building_id' => $building->id, 'pro_id' => $professional->id]);
        $this->makeIntervention(['building_id' => $building->id]);

        Sanctum::actingAs($admin);

        $this->getJson('/api/missions')->assertOk()->assertJsonCount(2);
        $this->getJson('/api/interventions')->assertOk()->assertJsonCount(2);
    }

    public function test_an_admin_approves_a_mission_for_a_technician_who_then_sees_and_is_told_about_it(): void
    {
        $admin = $this->makeUser('ADMIN');
        $technician = $this->makeUser('PROFESSIONAL');
        $other = $this->makeUser('PROFESSIONAL');
        $building = Building::create(['address' => 'Street 1']);
        $mission = $this->makeMission(['building_id' => $building->id, 'status' => 'PENDING']);

        Sanctum::actingAs($admin);
        $this->postJson("/api/missions/{$mission->id}/approve", ['assigned_user_id' => $technician->id])->assertOk();

        $intervention = Intervention::where('building_id', $building->id)->firstOrFail();
        $this->assertSame($technician->id, (int) $intervention->pro_id);
        $this->assertSame(1, \App\Models\Notification::where('user_id', $technician->id)->count(), 'the technician is told');

        Sanctum::actingAs($technician);
        $this->getJson('/api/interventions')->assertOk()->assertJsonCount(1);

        Sanctum::actingAs($other);
        $this->getJson('/api/interventions')->assertOk()->assertJsonCount(0);
    }
}
