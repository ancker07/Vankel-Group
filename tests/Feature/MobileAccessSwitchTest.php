<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\MobileAccess;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MobileAccessSwitchTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role): User
    {
        return User::create([
            'name' => $role.' user',
            'email' => strtolower($role).uniqid().'@test.com',
            'password' => 'password123',
            'role' => $role,
            'status' => 'APPROVED',
        ]);
    }

    public function test_mobile_access_is_on_by_default_and_the_phone_works(): void
    {
        $this->assertTrue(MobileAccess::enabled());
        Sanctum::actingAs($this->makeUser('ADMIN'));

        $this->withHeader('X-App', 'mobile')->getJson('/api/me')->assertOk();
    }

    public function test_when_switched_off_every_phone_request_is_refused_but_the_website_still_works(): void
    {
        $admin = $this->makeUser('ADMIN');
        MobileAccess::set(false);
        Sanctum::actingAs($admin);

        // the phone app, recognised by its header ...
        $this->withHeader('X-App', 'mobile')->getJson('/api/me')
            ->assertStatus(503)->assertJsonPath('code', 'MOBILE_DISABLED');
        // ... by Dart's HTTP client even without the header (older app versions) ...
        $this->withHeader('User-Agent', 'Dart/3.5 (dart:io)')->getJson('/api/me')->assertStatus(503);
        // ... and the login of the phone app
        $this->postJson('/api/login', ['email' => $admin->email, 'password' => 'password123', 'role' => 'ADMIN', 'app' => 'mobile'])
            ->assertStatus(503);

        // the website is not affected (headers set above stay on the test client until flushed)
        $this->flushHeaders();
        $this->getJson('/api/me')->assertOk();
        $this->postJson('/api/login', ['email' => $admin->email, 'password' => 'password123', 'role' => 'ADMIN'])->assertOk();
    }

    public function test_the_phone_can_still_ask_whether_it_may_work_again(): void
    {
        MobileAccess::set(false);
        $this->withHeader('X-App', 'mobile')->getJson('/api/app-status')->assertOk()->assertJsonPath('mobile_enabled', false);

        MobileAccess::set(true);
        $this->withHeader('X-App', 'mobile')->getJson('/api/app-status')->assertOk()->assertJsonPath('mobile_enabled', true);
    }

    public function test_only_the_super_admin_can_flip_the_switch(): void
    {
        Sanctum::actingAs($this->makeUser('ADMIN'));
        $this->putJson('/api/superadmin/mobile-access', ['enabled' => false])->assertForbidden();
        $this->getJson('/api/superadmin/mobile-access')->assertForbidden();
        $this->assertTrue(MobileAccess::enabled());

        Sanctum::actingAs($this->makeUser('PROFESSIONAL'));
        $this->putJson('/api/superadmin/mobile-access', ['enabled' => false])->assertForbidden();

        Sanctum::actingAs($this->makeUser('SUPERADMIN'));
        $this->putJson('/api/superadmin/mobile-access', ['enabled' => false])->assertOk()->assertJsonPath('enabled', false);
        $this->getJson('/api/superadmin/mobile-access')->assertOk()->assertJsonPath('enabled', false);
        $this->assertFalse(MobileAccess::enabled());

        $this->putJson('/api/superadmin/mobile-access', ['enabled' => true])->assertOk()->assertJsonPath('enabled', true);
        $this->assertTrue(MobileAccess::enabled());
        $this->putJson('/api/superadmin/mobile-access', [])->assertStatus(422);
    }
}
