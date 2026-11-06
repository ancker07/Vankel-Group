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

class AdminDoesTaskTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role): User
    {
        return User::create([
            'name' => $role.' user', 'email' => strtolower($role).uniqid().'@test.com',
            'password' => 'password123', 'role' => $role, 'status' => 'APPROVED',
        ]);
    }

    private function pendingMission(): Mission
    {
        $building = Building::create(['address' => 'Street 1']);

        return Mission::create([
            'title' => 'Leak', 'description' => 'Water.', 'requested_by' => 'SYNDIC', 'urgency' => 'MEDIUM',
            'status' => 'PENDING', 'category' => 'GENERAL', 'sector' => 'GENERAL', 'building_id' => $building->id,
        ]);
    }

    public function test_admin_approves_a_mission_and_takes_it_themselves(): void
    {
        $admin = $this->makeUser('ADMIN');
        $mission = $this->pendingMission();
        Sanctum::actingAs($admin);

        $this->postJson("/api/missions/{$mission->id}/approve", ['assigned_user_id' => $admin->id])->assertOk();

        $intervention = Intervention::firstOrFail();
        $this->assertSame($admin->id, (int) $intervention->pro_id);
        $this->assertSame($admin->id, (int) $mission->fresh()->assigned_user_id);
        $this->assertDatabaseHas('assignments', ['intervention_id' => $intervention->id, 'user_id' => $admin->id, 'unassigned_at' => null]);

        // and the admin can then work it: set it to delayed / completed
        $this->putJson("/api/interventions/{$intervention->id}", ['status' => 'DELAYED', 'delay_reason' => 'WEATHER'])->assertOk();
        $this->putJson("/api/interventions/{$intervention->id}", ['status' => 'COMPLETED'])->assertOk();
        $this->assertSame('COMPLETED', $intervention->fresh()->status);
    }

    public function test_super_admin_can_take_a_mission_themselves(): void
    {
        $super = $this->makeUser('SUPERADMIN');
        $mission = $this->pendingMission();
        Sanctum::actingAs($super);

        $this->postJson("/api/missions/{$mission->id}/approve", ['assigned_user_id' => $super->id])->assertOk();
        $this->assertSame($super->id, (int) Intervention::firstOrFail()->pro_id);
    }

    public function test_admin_takes_over_from_a_technician_who_then_loses_access(): void
    {
        $admin = $this->makeUser('ADMIN');
        $tech = $this->makeUser('PROFESSIONAL');
        $mission = $this->pendingMission();

        Sanctum::actingAs($admin);
        $this->postJson("/api/missions/{$mission->id}/approve", ['assigned_user_id' => $tech->id])->assertOk();
        $intervention = Intervention::firstOrFail();

        // admin: "Do it myself"
        $this->putJson("/api/interventions/{$intervention->id}", ['pro_id' => $admin->id])->assertOk();

        $this->assertSame($admin->id, (int) $intervention->fresh()->pro_id);
        $this->assertSame($admin->id, (int) $mission->fresh()->assigned_user_id);
        $this->assertDatabaseHas('assignments', ['intervention_id' => $intervention->id, 'user_id' => $admin->id, 'unassigned_at' => null]);
        $this->assertSame(1, Assignment::where('intervention_id', $intervention->id)->whereNull('unassigned_at')->count());

        // the technician no longer sees or updates it
        Sanctum::actingAs($tech);
        $this->getJson('/api/interventions')->assertOk()->assertJsonCount(0);
        $this->putJson("/api/interventions/{$intervention->id}", ['status' => 'COMPLETED'])->assertForbidden();
    }

    public function test_technician_cannot_hand_the_task_to_the_admin_or_anyone(): void
    {
        $admin = $this->makeUser('ADMIN');
        $tech = $this->makeUser('PROFESSIONAL');
        $other = $this->makeUser('PROFESSIONAL');
        $mission = $this->pendingMission();
        Sanctum::actingAs($admin);
        $this->postJson("/api/missions/{$mission->id}/approve", ['assigned_user_id' => $tech->id])->assertOk();
        $intervention = Intervention::firstOrFail();

        Sanctum::actingAs($tech);
        $this->putJson("/api/interventions/{$intervention->id}", ['pro_id' => $other->id])->assertOk();
        $this->assertSame($tech->id, (int) $intervention->fresh()->pro_id);
    }

    private function assignmentPushes(User $actor, User $assignee): int
    {
        $count = 0;
        $push = \Mockery::mock(\App\Services\NotificationService::class);
        $push->shouldReceive('notifyUser')->andReturnUsing(function ($user, $type) use (&$count) {
            if ($type === 'new_assignment') {
                $count++;
            }
        });
        $this->app->instance(\App\Services\NotificationService::class, $push);

        $mission = $this->pendingMission();
        Sanctum::actingAs($actor);
        $this->postJson("/api/missions/{$mission->id}/approve", ['assigned_user_id' => $assignee->id])->assertOk();

        return $count;
    }

    public function test_assignment_push_goes_to_a_technician_but_not_to_yourself(): void
    {
        $admin = $this->makeUser('ADMIN');
        $tech = $this->makeUser('PROFESSIONAL');

        $this->assertSame(1, $this->assignmentPushes($admin, $tech));   // positive control
        $this->assertSame(0, $this->assignmentPushes($admin, $admin));  // do it myself: no push to yourself
    }

    public function test_tasks_assigned_to_an_admin_carry_the_admin_flag_everywhere(): void
    {
        $admin = $this->makeUser('ADMIN');
        $super = $this->makeUser('SUPERADMIN');
        $tech = $this->makeUser('PROFESSIONAL');
        Sanctum::actingAs($super);

        foreach ([$admin, $super, $tech] as $assignee) {
            $mission = $this->pendingMission();
            $this->postJson("/api/missions/{$mission->id}/approve", ['assigned_user_id' => $assignee->id])
                ->assertOk()
                ->assertJsonPath('intervention.assigned_to_admin', $assignee->role !== 'PROFESSIONAL')
                ->assertJsonPath('mission.assigned_to_admin', $assignee->role !== 'PROFESSIONAL');
        }

        // an unassigned task is not flagged
        $unassigned = $this->pendingMission();
        $this->postJson("/api/missions/{$unassigned->id}/approve", [])->assertOk()->assertJsonPath('intervention.assigned_to_admin', false);

        $flags = collect($this->getJson('/api/interventions')->assertOk()->json())->pluck('assigned_to_admin', 'pro_id');
        $this->assertTrue($flags[$admin->id]);
        $this->assertTrue($flags[$super->id]);
        $this->assertFalse($flags[$tech->id]);

        $missionFlags = collect($this->getJson('/api/missions')->assertOk()->json())->pluck('assigned_to_admin', 'assigned_user_id');
        $this->assertTrue($missionFlags[$admin->id]);
        $this->assertFalse($missionFlags[$tech->id]);

        // a technician sees the flag on their own list too, and it follows a take-over
        $intervention = Intervention::where('pro_id', $tech->id)->firstOrFail();
        $this->putJson("/api/interventions/{$intervention->id}", ['pro_id' => $admin->id])->assertOk()
            ->assertJsonPath('intervention.assigned_to_admin', true);
        $this->putJson("/api/interventions/{$intervention->id}", ['pro_id' => $tech->id])->assertOk()
            ->assertJsonPath('intervention.assigned_to_admin', false);
        Sanctum::actingAs($tech);
        $this->getJson('/api/interventions')->assertOk()->assertJsonPath('0.assigned_to_admin', false);
    }
}
