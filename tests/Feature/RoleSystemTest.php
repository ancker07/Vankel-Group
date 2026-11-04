<?php

namespace Tests\Feature;

use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use App\Support\PermissionCatalog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** Three fixed roles: Super admin, Admin (system owner), Technician. No custom roles, a clear hierarchy. */
class RoleSystemTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role, array $extra = []): User
    {
        return User::create($extra + ['name' => $role . uniqid(), 'email' => strtolower($role) . uniqid() . '@test.com',
            'password' => 'password123', 'role' => $role, 'status' => 'APPROVED']);
    }

    public function test_exactly_three_roles_are_offered_with_the_permissions_defined_in_code(): void
    {
        Sanctum::actingAs($this->user('SUPERADMIN'));

        $roles = $this->getJson('/api/roles')->assertOk()->json();

        $this->assertSame(['SUPERADMIN', 'ADMIN', 'PROFESSIONAL'], array_column($roles, 'name'));
        foreach ($roles as $role) {
            $this->assertNotEmpty($role['description']);
            $this->assertEqualsCanonicalizing(PermissionCatalog::permissionsFor($role['name']), $role['permissions']);
        }
    }

    public function test_the_admin_can_see_the_roles_and_the_technician_cannot(): void
    {
        Sanctum::actingAs($this->user('ADMIN'));
        $this->getJson('/api/roles')->assertOk();

        Sanctum::actingAs($this->user('PROFESSIONAL'));
        $this->getJson('/api/roles')->assertForbidden();
    }

    public function test_roles_cannot_be_created_edited_or_deleted_by_anyone(): void
    {
        $super = $this->user('SUPERADMIN');
        Sanctum::actingAs($super);
        $technician = Role::where('name', 'PROFESSIONAL')->first();

        $gone = fn ($response) => $this->assertContains($response->getStatusCode(), [404, 405], 'the route no longer exists');
        $gone($this->postJson('/api/roles', ['name' => 'DISPATCH', 'label' => 'Dispatch', 'portal' => 'admin', 'permissions' => ['missions.view']]));
        $gone($this->putJson("/api/roles/{$technician->id}", ['permissions' => ['users.create']]));
        $gone($this->deleteJson("/api/roles/{$technician->id}"));
        $this->assertNull(Role::where('name', 'DISPATCH')->first());
        $this->assertNotContains('users.create', $technician->fresh()->permissionKeys());
    }

    public function test_role_permissions_cannot_drift_in_the_database(): void
    {
        // even if someone edits the permission table by hand, the code decides
        $technician = Role::where('name', 'PROFESSIONAL')->first();
        $technician->permissions()->attach(Permission::where('key', 'users.create')->pluck('id'));
        $user = $this->user('PROFESSIONAL');

        $this->assertNotContains('users.create', $user->permissionKeys());
        $this->assertNotContains('users.create', $technician->fresh()->permissionKeys());
        $this->assertFalse($user->hasPermission('users.create'));
    }

    public function test_the_admin_manages_technicians_but_never_a_super_admin_or_an_admin(): void
    {
        $admin = $this->user('ADMIN');
        $super = $this->user('SUPERADMIN');
        $technician = $this->user('PROFESSIONAL');
        Sanctum::actingAs($admin);

        // technicians: full control
        $this->postJson("/api/users/{$technician->id}/reset-password", ['password' => 'newpassword1'])->assertOk();
        $this->postJson("/api/users/{$technician->id}/approve")->assertOk();
        $this->deleteJson("/api/users/{$technician->id}")->assertOk();

        // super admin: untouchable (every way of managing an account)
        $this->postJson("/api/users/{$super->id}/reset-password", ['password' => 'newpassword1'])->assertForbidden();
        $this->putJson("/api/users/{$super->id}/role", ['role' => 'PROFESSIONAL'])->assertForbidden();
        $this->postJson("/api/users/{$super->id}/approve")->assertForbidden();
        $this->postJson("/api/users/{$super->id}/reject")->assertForbidden();
        $this->deleteJson("/api/users/{$super->id}")->assertForbidden();
        $this->assertSame('SUPERADMIN', $super->fresh()->role);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('password123', $super->fresh()->password));
    }

    public function test_the_admin_cannot_promote_a_technician_to_admin_or_super_admin(): void
    {
        $technician = $this->user('PROFESSIONAL');
        Sanctum::actingAs($this->user('ADMIN'));

        $this->putJson("/api/users/{$technician->id}/role", ['role' => 'SUPERADMIN'])->assertForbidden();
        $this->putJson("/api/users/{$technician->id}/role", ['role' => 'ADMIN'])->assertStatus(422); // refused either way
        $this->assertSame('PROFESSIONAL', $technician->fresh()->role);
    }

    public function test_the_super_admin_manages_everyone(): void
    {
        $admin = $this->user('ADMIN');
        $technician = $this->user('PROFESSIONAL');
        Sanctum::actingAs($this->user('SUPERADMIN'));

        $this->postJson("/api/users/{$admin->id}/reset-password", ['password' => 'newpassword1'])->assertOk();
        $this->putJson("/api/users/{$technician->id}/role", ['role' => 'PROFESSIONAL'])->assertOk();
        $this->deleteJson("/api/users/{$technician->id}")->assertOk();
    }

    public function test_the_technician_manages_nobody(): void
    {
        $other = $this->user('PROFESSIONAL');
        Sanctum::actingAs($this->user('PROFESSIONAL'));

        $this->getJson('/api/users/all')->assertForbidden();
        $this->postJson("/api/users/{$other->id}/reset-password", ['password' => 'newpassword1'])->assertForbidden();
        $this->deleteJson("/api/users/{$other->id}")->assertForbidden();
    }

    public function test_the_admin_has_full_owner_level_access_to_every_area(): void
    {
        Sanctum::actingAs($this->user('ADMIN'));

        foreach (['/api/missions', '/api/interventions', '/api/buildings', '/api/maintenance-plans', '/api/emails', '/api/contacts',
                  '/api/team', '/api/users/all', '/api/roles', '/api/settings/ai', '/api/superadmin/stats',
                  '/api/superadmin/notifications/history'] as $url) {
            $this->getJson($url)->assertOk();
        }
    }

    public function test_the_technician_is_kept_out_of_the_owner_areas(): void
    {
        Sanctum::actingAs($this->user('PROFESSIONAL'));

        foreach (['/api/missions', '/api/emails', '/api/contacts', '/api/team', '/api/users/all', '/api/roles',
                  '/api/settings/ai', '/api/superadmin/stats', '/api/superadmin/notifications/history'] as $url) {
            $this->getJson($url)->assertForbidden();
        }
        foreach (['/api/interventions', '/api/buildings', '/api/maintenance-plans'] as $url) {
            $this->getJson($url)->assertOk();
        }
    }

    public function test_syncing_removes_old_custom_roles_and_makes_their_users_technicians(): void
    {
        $custom = Role::create(['name' => 'DISPATCH', 'label' => 'Dispatch', 'portal' => 'admin', 'is_system' => false]);
        $custom->permissions()->attach(Permission::where('key', 'missions.view')->pluck('id'));
        $orphan = $this->user('DISPATCH');
        Role::where('name', 'PROFESSIONAL')->first()->permissions()->attach(Permission::where('key', 'missions.view')->pluck('id'));

        PermissionCatalog::sync();
        PermissionCatalog::syncRoles();
        PermissionCatalog::syncRoles(); // idempotent

        $this->assertNull(Role::where('name', 'DISPATCH')->first());
        $this->assertSame('PROFESSIONAL', $orphan->fresh()->role, 'least access for users of a removed role');
        foreach (PermissionCatalog::FIXED_ROLES as $name) {
            $this->assertEqualsCanonicalizing(
                PermissionCatalog::permissionsFor($name),
                Role::where('name', $name)->first()->permissions()->pluck('key')->all(),
                "{$name}: the stored permissions match the code"
            );
        }
    }

    public function test_every_permission_is_held_by_the_admin_and_none_by_accident_by_the_technician(): void
    {
        $this->assertEqualsCanonicalizing(PermissionCatalog::keys(), PermissionCatalog::permissionsFor('ADMIN'));
        $this->assertEqualsCanonicalizing(PermissionCatalog::keys(), PermissionCatalog::permissionsFor('SUPERADMIN'));
        $this->assertNotContains('roles.manage', PermissionCatalog::keys());
        $this->assertSame([], array_diff(PermissionCatalog::permissionsFor('PROFESSIONAL'), PermissionCatalog::keys()));
    }
}
