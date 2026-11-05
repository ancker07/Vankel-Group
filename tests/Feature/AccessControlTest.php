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
            'name' => $role.' user',
            'email' => strtolower($role).uniqid().'@test.com',
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
            'email' => 'new'.uniqid().'@test.com',
            'password' => 'password123',
            'phone' => '0470000000',
            'role' => $role,
            'companyName' => '',
        ], $extra);
    }

    public function test_superadmin_can_create_each_assignable_role(): void
    {
        Sanctum::actingAs($this->makeUser('SUPERADMIN'));

        foreach (['ADMIN', 'PROFESSIONAL'] as $role) {
            $this->postJson('/api/users', $this->newUserPayload($role))
                ->assertCreated()
                ->assertJsonPath('user.role', $role);
        }

        // there are only three roles: the old client role cannot be given any more
        $this->postJson('/api/users', $this->newUserPayload('SYNDIC'))->assertStatus(422)->assertJsonValidationErrors('role');
        $this->postJson('/api/users', $this->newUserPayload('DISPATCH'))->assertStatus(422)->assertJsonValidationErrors('role');
    }

    public function test_technician_is_created_with_a_username_instead_of_an_email_and_can_log_in(): void
    {
        Sanctum::actingAs($this->makeUser('SUPERADMIN'));

        $payload = $this->newUserPayload('PROFESSIONAL', ['username' => 'Jean.Tech']);
        unset($payload['email']);

        $this->postJson('/api/users', $payload)->assertCreated()->assertJsonPath('user.role', 'PROFESSIONAL');
        $this->postJson('/api/users', $payload)->assertStatus(422)->assertJsonValidationErrors('username');

        $minimal = ['firstName' => 'Solo', 'username' => 'solo.tech', 'password' => 'password123', 'role' => 'PROFESSIONAL'];
        $this->postJson('/api/users', $minimal)->assertCreated()->assertJsonPath('user.name', 'Solo');

        $noName = $this->newUserPayload('PROFESSIONAL');
        unset($noName['email']);
        $this->postJson('/api/users', $noName)->assertStatus(422)->assertJsonValidationErrors('username');

        // an admin still needs an e-mail
        $admin = $this->newUserPayload('ADMIN');
        unset($admin['email']);
        $this->postJson('/api/users', $admin)->assertStatus(422)->assertJsonValidationErrors('email');
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

    public function test_the_admin_creates_technicians_but_never_admins_or_super_admins(): void
    {
        Sanctum::actingAs($this->makeUser('ADMIN'));

        $this->postJson('/api/users', $this->newUserPayload('PROFESSIONAL'))->assertCreated()->assertJsonPath('user.role', 'PROFESSIONAL');
        // only a super admin gives these roles
        $this->postJson('/api/users', $this->newUserPayload('SUPERADMIN'))->assertForbidden()->assertJsonPath('message', 'Only a super admin can give this role.');
        $this->postJson('/api/users', $this->newUserPayload('ADMIN'))->assertStatus(422); // and there is only one admin anyway
    }

    public function test_a_technician_cannot_create_users(): void
    {
        Sanctum::actingAs($this->makeUser('PROFESSIONAL'));
        $this->postJson('/api/users', $this->newUserPayload('PROFESSIONAL'))->assertForbidden();
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

    public function test_the_admin_is_the_owner_and_gets_every_permission_the_technician_a_fixed_few(): void
    {
        $this->makeUser('ADMIN', ['email' => 'admin@test.com']);
        $this->makeUser('PROFESSIONAL', ['email' => 'tech@test.com']);

        $admin = $this->postJson('/api/login', ['email' => 'admin@test.com', 'password' => 'password123', 'role' => 'ADMIN'])->assertOk()->json('user.permissions');
        $this->assertEqualsCanonicalizing(
            array_diff(\App\Support\PermissionCatalog::keys(), \App\Support\PermissionCatalog::ADMIN_EXCLUDED),
            $admin,
            'the admin holds every permission except AI settings, push notifications, contacts and maintenance'
        );
        foreach (\App\Support\PermissionCatalog::ADMIN_EXCLUDED as $superAdminOnly) {
            $this->assertNotContains($superAdminOnly, $admin);
        }
        foreach (['users.create', 'users.update', 'missions.approve', 'stats.view'] as $owner) {
            $this->assertContains($owner, $admin);
        }

        $tech = $this->postJson('/api/login', ['email' => 'tech@test.com', 'password' => 'password123', 'role' => 'PROFESSIONAL'])->assertOk()->json('user.permissions');
        $this->assertEqualsCanonicalizing(
            ['interventions.view', 'interventions.update', 'maintenance.view', 'buildings.view', 'location.share', 'ai.use'],
            $tech
        );
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

    public function test_login_offers_technician_and_admin_only_and_keeps_them_apart(): void
    {
        $tech = $this->makeUser('PROFESSIONAL', ['email' => 'tech@test.com']);
        $admin = $this->makeUser('ADMIN', ['email' => 'admin@test.com']);

        $login = fn (string $email, string $role) => $this->postJson('/api/login', ['email' => $email, 'password' => 'password123', 'role' => $role]);

        // a technician logs in through the Technician choice (and still through Admin, like older app versions)
        $login('tech@test.com', 'PROFESSIONAL')->assertOk()->assertJsonPath('user.role', 'PROFESSIONAL');
        $login('tech@test.com', 'ADMIN')->assertOk();
        // an admin cannot use the Technician choice
        $login('admin@test.com', 'PROFESSIONAL')->assertStatus(401);
        $login('admin@test.com', 'ADMIN')->assertOk();
    }
}
