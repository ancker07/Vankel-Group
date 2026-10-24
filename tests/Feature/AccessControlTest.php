<?php

namespace Tests\Feature;

use App\Models\Building;
use App\Models\Intervention;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AccessControlTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role, array $attrs = []): User
    {
        return User::create(array_merge([
            'name' => $role . ' user',
            'email' => strtolower($role) . uniqid() . '@test.com',
            'password' => 'password123',
            'role' => $role,
            'status' => 'APPROVED',
        ], $attrs));
    }

    private function newUserPayload(string $role, array $extra = []): array
    {
        return array_merge([
            'firstName' => 'New',
            'lastName' => 'Person',
            'email' => 'new' . uniqid() . '@test.com',
            'password' => 'password123',
            'phone' => '0470000000',
            'role' => $role,
            'companyName' => '',
        ], $extra);
    }

    public function test_superadmin_can_create_each_assignable_role(): void
    {
        Sanctum::actingAs($this->makeUser('SUPERADMIN'));

        foreach (['ADMIN', 'PROFESSIONAL', 'SYNDIC'] as $role) {
            $this->postJson('/api/users', $this->newUserPayload($role))
                ->assertCreated()
                ->assertJsonPath('user.role', $role);
        }
    }

    public function test_second_superadmin_can_be_created_by_a_superadmin(): void
    {
        Sanctum::actingAs($this->makeUser('SUPERADMIN'));

        $this->postJson('/api/users', $this->newUserPayload('SUPERADMIN'))->assertCreated();
        $this->assertSame(2, User::where('role', 'SUPERADMIN')->count());

        $this->postJson('/api/users', $this->newUserPayload('SUPERADMIN'))
            ->assertStatus(422)
            ->assertJsonPath('message', 'There can only be two super admins.');
    }

    public function test_only_one_admin_allowed_with_clear_message(): void
    {
        Sanctum::actingAs($this->makeUser('SUPERADMIN'));
        $this->makeUser('ADMIN');

        $this->postJson('/api/users', $this->newUserPayload('ADMIN'))
            ->assertStatus(422)
            ->assertJsonPath('message', 'There can only be one admin.');
    }

    public function test_admin_and_technician_cannot_create_users(): void
    {
        foreach (['ADMIN', 'PROFESSIONAL'] as $role) {
            Sanctum::actingAs($this->makeUser($role));
            $this->postJson('/api/users', $this->newUserPayload('PROFESSIONAL'))->assertForbidden();
        }
    }

    public function test_created_user_can_log_in_to_the_right_app(): void
    {
        Sanctum::actingAs($this->makeUser('SUPERADMIN'));
        $payload = $this->newUserPayload('PROFESSIONAL');
        $this->postJson('/api/users', $payload)->assertCreated();

        $this->postJson('/api/login', ['email' => $payload['email'], 'password' => $payload['password'], 'role' => 'ADMIN'])
            ->assertOk()
            ->assertJsonPath('user.role', 'PROFESSIONAL');
    }

    public function test_superadmin_logs_in_and_gets_all_permissions(): void
    {
        $user = $this->makeUser('SUPERADMIN', ['email' => 'zain@test.com']);

        $response = $this->postJson('/api/login', ['email' => 'zain@test.com', 'password' => 'password123', 'role' => 'SUPERADMIN'])
            ->assertOk();
        $this->assertContains('users.create', $response->json('user.permissions'));
    }

    public function test_technician_cannot_complete_but_admin_can(): void
    {
        $building = Building::create(['address' => 'Street 1']);
        $intervention = Intervention::create([
            'building_id' => $building->id, 'title' => 'Leak', 'description' => 'd',
            'urgency' => 'LOW', 'status' => 'IN_PROGRESS', 'category' => 'GENERAL', 'sector' => 'GENERAL',
        ]);

        Sanctum::actingAs($this->makeUser('PROFESSIONAL'));
        $this->putJson("/api/interventions/{$intervention->id}", ['status' => 'COMPLETED'])->assertForbidden();

        Sanctum::actingAs($this->makeUser('ADMIN'));
        $this->putJson("/api/interventions/{$intervention->id}", ['status' => 'COMPLETED'])->assertOk();
    }
}
