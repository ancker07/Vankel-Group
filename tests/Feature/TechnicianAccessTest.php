<?php

namespace Tests\Feature;

use App\Models\Building;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

/** A technician works on what is assigned to them: no missions section, only the permissions their role has. */
class TechnicianAccessTest extends TestCase
{
    use RefreshDatabase;

    private function technician(): User
    {
        return User::create([
            'name' => 'Tom', 'email' => 'tom' . uniqid() . '@test.com', 'password' => 'password123',
            'role' => 'PROFESSIONAL', 'status' => 'APPROVED', 'locale' => 'fr', 'fcm_token' => 'tech-token',
        ]);
    }

    public function test_the_technician_role_has_no_mission_permission(): void
    {
        $permissions = Role::where('name', 'PROFESSIONAL')->first()->permissionKeys();

        $this->assertNotContains('missions.view', $permissions);
        $this->assertNotContains('missions.update', $permissions);
        $this->assertNotContains('missions.approve', $permissions);
        // what a technician does need
        foreach (['interventions.view', 'interventions.update', 'location.share', 'buildings.view'] as $needed) {
            $this->assertContains($needed, $permissions);
        }
    }

    public function test_login_gives_the_technician_only_his_permissions(): void
    {
        $user = $this->technician();

        $response = $this->postJson('/api/login', ['email' => $user->email, 'password' => 'password123', 'role' => 'PROFESSIONAL'])
            ->assertOk();

        $permissions = $response->json('user.permissions');
        $this->assertNotContains('missions.view', $permissions);
        $this->assertContains('interventions.view', $permissions);
    }

    public function test_the_missions_api_is_closed_to_a_technician(): void
    {
        Sanctum::actingAs($this->technician());
        $mission = Mission::create(['requested_by' => 'SYNDIC', 'title' => 'T', 'description' => 'D', 'status' => 'PENDING']);

        $this->getJson('/api/missions')->assertForbidden();
        $this->getJson("/api/missions/{$mission->id}")->assertForbidden();
        $this->postJson("/api/missions/{$mission->id}/approve")->assertForbidden();
        $this->postJson("/api/missions/{$mission->id}/reject")->assertForbidden();
    }

    public function test_the_technician_still_sees_the_interventions_assigned_to_him(): void
    {
        $tech = $this->technician();
        Sanctum::actingAs($tech);
        $building = Building::create(['address' => 'Rue 1']);
        $mine = Intervention::create(['building_id' => $building->id, 'title' => 'Mine', 'description' => 'd', 'pro_id' => $tech->id]);
        Intervention::create(['building_id' => $building->id, 'title' => 'Someone else', 'description' => 'd']);

        $titles = collect($this->getJson('/api/interventions')->assertOk()->json())->pluck('title')->all();

        $this->assertContains('Mine', $titles);
        $this->assertNotContains('Someone else', $titles);
    }

    public function test_a_new_mission_alert_is_not_sent_to_technicians(): void
    {
        $tech = $this->technician();
        $admin = User::create(['name' => 'Ada', 'email' => 'ada@test.com', 'password' => 'password123', 'role' => 'ADMIN',
            'status' => 'APPROVED', 'fcm_token' => 'admin-token']);

        $pushed = [];
        $service = Mockery::mock(NotificationService::class)->makePartial();
        $service->shouldReceive('sendNotification')->andReturnUsing(function ($token) use (&$pushed) {
            $pushed[] = $token;

            return true;
        });

        $mission = Mission::create(['requested_by' => 'SYNDIC', 'title' => 'T', 'description' => 'D', 'status' => 'PENDING']);
        $service->notifyNewMission($mission);

        $this->assertContains('admin-token', $pushed);
        $this->assertNotContains('tech-token', $pushed);
    }

    public function test_an_admin_can_still_give_missions_to_a_custom_role(): void
    {
        $role = Role::create(['name' => 'DISPATCH', 'label' => 'Dispatch', 'portal' => 'admin', 'is_system' => false]);
        $role->permissions()->attach(\App\Models\Permission::where('key', 'missions.view')->pluck('id'));
        $user = User::create(['name' => 'D', 'email' => 'd@test.com', 'password' => 'password123', 'role' => 'DISPATCH', 'status' => 'APPROVED']);
        Sanctum::actingAs($user);

        $this->getJson('/api/missions')->assertOk();
    }

    public function test_the_migration_removes_missions_from_an_existing_technician_role_and_keeps_custom_roles(): void
    {
        $missions = \App\Models\Permission::where('key', 'missions.view')->first();
        $technician = Role::where('name', 'PROFESSIONAL')->first();
        $technician->permissions()->attach($missions->id); // what an existing database looks like today

        $custom = Role::create(['name' => 'DISPATCH', 'label' => 'Dispatch', 'portal' => 'admin', 'is_system' => false]);
        $custom->permissions()->attach($missions->id);

        (require database_path('migrations/2026_11_05_000000_remove_missions_from_technician_role.php'))->up();

        $this->assertNotContains('missions.view', $technician->fresh()->permissionKeys());
        $this->assertContains('missions.view', $custom->fresh()->permissionKeys());
        $this->assertContains('interventions.view', $technician->fresh()->permissionKeys());
    }
}
