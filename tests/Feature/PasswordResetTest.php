<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PasswordResetTest extends TestCase
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

    public function test_admin_can_reset_a_users_password(): void
    {
        Sanctum::actingAs($this->makeUser('ADMIN'));
        $target = $this->makeUser('PROFESSIONAL');
        $target->createToken('mobile');

        $this->postJson("/api/users/{$target->id}/reset-password", ['password' => 'newpassword123'])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertTrue(Hash::check('newpassword123', $target->fresh()->password));
        $this->assertSame(0, $target->tokens()->count(), 'Existing sessions should be revoked.');

        $this->postJson('/api/login', [
            'email' => $target->email,
            'password' => 'newpassword123',
            'role' => 'ADMIN',
        ])->assertOk();
    }

    public function test_superadmin_can_reset_a_users_password(): void
    {
        Sanctum::actingAs($this->makeUser('SUPERADMIN'));
        $target = $this->makeUser('ADMIN');

        $this->postJson("/api/users/{$target->id}/reset-password", ['password' => 'newpassword123'])
            ->assertOk();

        $this->assertTrue(Hash::check('newpassword123', $target->fresh()->password));
    }

    public function test_professional_cannot_reset_passwords(): void
    {
        Sanctum::actingAs($this->makeUser('PROFESSIONAL'));
        $target = $this->makeUser('SYNDIC');

        $this->postJson("/api/users/{$target->id}/reset-password", ['password' => 'newpassword123'])
            ->assertForbidden();
    }

    public function test_admin_cannot_reset_the_superadmins_password(): void
    {
        Sanctum::actingAs($this->makeUser('ADMIN'));
        $superadmin = $this->makeUser('SUPERADMIN');

        $this->postJson("/api/users/{$superadmin->id}/reset-password", ['password' => 'newpassword123'])
            ->assertForbidden();

        $this->assertTrue(Hash::check('password123', $superadmin->fresh()->password));
    }

    public function test_new_password_must_be_at_least_eight_characters(): void
    {
        Sanctum::actingAs($this->makeUser('ADMIN'));
        $target = $this->makeUser('PROFESSIONAL');

        $this->postJson("/api/users/{$target->id}/reset-password", ['password' => 'short'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('password');
    }
}
