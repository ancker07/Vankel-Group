<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ResetSystemDataTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role, string $email): User
    {
        return User::create([
            'name' => $role, 'email' => $email, 'password' => 'password123', 'role' => $role, 'status' => 'APPROVED',
        ]);
    }

    private function seedBusinessData(User $tech): void
    {
        $syndicId = DB::table('syndics')->insertGetId(['company_name' => 'ACME', 'created_at' => now(), 'updated_at' => now()]);
        $buildingId = DB::table('buildings')->insertGetId(['address' => 'Rue 1', 'syndic_id' => $syndicId, 'created_at' => now(), 'updated_at' => now()]);
        DB::table('emails')->insert(['message_id' => 'm1', 'from_address' => 'a@b.c', 'subject' => 'Leak', 'received_at' => now(), 'created_at' => now(), 'updated_at' => now()]);
        DB::table('missions')->insert(['title' => 'Leak', 'requested_by' => $tech->id, 'description' => 'd', 'building_id' => $buildingId, 'assigned_user_id' => $tech->id, 'created_at' => now(), 'updated_at' => now()]);
    }

    public function test_it_wipes_everything_but_the_super_admin_and_platform_config(): void
    {
        Storage::fake('public');
        $super = $this->user('SUPERADMIN', 'super@test.com');
        $super->update(['image_url' => UploadedFile::fake()->image('me.jpg')->store('profiles', 'public')]);
        $superToken = $super->createToken('web')->accessToken->id;

        $admin = $this->user('ADMIN', 'admin@test.com');
        $tech = $this->user('PROFESSIONAL', 'tech@test.com');
        $admin->createToken('web');
        $gone = $this->user('PROFESSIONAL', 'gone@test.com');
        $gone->delete(); // soft-deleted users are removed too

        DB::table('settings')->insert(['key' => 'ai_model', 'value' => 'x', 'created_at' => now(), 'updated_at' => now()]);
        $this->seedBusinessData($tech);
        UploadedFile::fake()->image('p.jpg')->store('photos', 'public');

        $this->artisan('system:reset', ['--force' => true])->assertSuccessful();

        $this->assertSame([$super->id], DB::table('users')->pluck('id')->all());
        $this->assertSame([$superToken], DB::table('personal_access_tokens')->pluck('id')->all());
        foreach (['missions', 'emails', 'syndics', 'buildings'] as $table) {
            $this->assertSame(0, DB::table($table)->count(), $table);
        }
        $this->assertSame('x', DB::table('settings')->where('key', 'ai_model')->value('value'));
        $this->assertTrue(DB::table('roles')->where('name', 'SUPERADMIN')->exists());
        $this->assertGreaterThan(0, DB::table('permissions')->count());

        Storage::disk('public')->assertExists($super->image_url);
        $this->assertEmpty(Storage::disk('public')->allFiles('photos'));

        // the email of a deleted user can be used again
        $this->user('ADMIN', 'gone@test.com');
    }

    public function test_keep_directory_keeps_syndics_and_buildings(): void
    {
        $this->user('SUPERADMIN', 'super@test.com');
        $this->seedBusinessData($this->user('PROFESSIONAL', 'tech@test.com'));

        $this->artisan('system:reset', ['--force' => true, '--keep-directory' => true, '--keep-files' => true])->assertSuccessful();

        $this->assertSame(1, DB::table('syndics')->count());
        $this->assertSame(1, DB::table('buildings')->count());
        $this->assertSame(0, DB::table('missions')->count());
    }

    public function test_it_creates_the_new_admin_who_can_log_in(): void
    {
        $this->user('SUPERADMIN', 'super@test.com');
        $this->user('ADMIN', 'old-admin@test.com');
        $password = 'Exemple-l’été-déjà'; // curly apostrophe + accents must be stored exactly

        $this->artisan('system:reset', [
            '--force' => true, '--keep-files' => true,
            '--admin-email' => 'New.Admin@example.test', '--admin-name' => 'New admin', '--admin-password' => $password,
        ])->assertSuccessful();

        $admin = User::where('role', 'ADMIN')->sole();
        $this->assertSame('New.Admin@example.test', $admin->email);
        $this->assertSame('APPROVED', $admin->status);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check($password, $admin->password));
        $this->assertFalse(\Illuminate\Support\Facades\Hash::check("Exemple-l'été-déjà", $admin->password));

        $this->postJson('/api/login', ['email' => 'New.Admin@example.test', 'password' => $password, 'role' => 'ADMIN'])
            ->assertOk();
    }

    public function test_only_account_leaves_one_super_admin_and_nobody_else(): void
    {
        Storage::fake('public');
        $oldSuper = $this->user('SUPERADMIN', 'old-super@test.com');
        $oldSuper->update(['image_url' => UploadedFile::fake()->image('me.jpg')->store('profiles', 'public')]);
        $oldSuper->createToken('web');
        $this->user('SUPERADMIN', 'second-super@test.com');
        $this->user('ADMIN', 'admin@test.com');
        $this->seedBusinessData($this->user('PROFESSIONAL', 'tech@test.com'));

        $this->artisan('system:reset', [
            '--force' => true, '--only-account' => true,
            '--admin-email' => 'Owner@example.test', '--admin-name' => 'Owner', '--admin-password' => 'Exemple-l’été-déjà',
        ])->assertSuccessful();

        $only = User::sole();
        $this->assertSame('Owner@example.test', $only->email);
        $this->assertSame('SUPERADMIN', $only->role);
        $this->assertSame(0, DB::table('personal_access_tokens')->count());
        $this->assertSame(0, DB::table('missions')->count());
        $this->assertEmpty(Storage::disk('public')->allFiles('profiles'));

        $this->postJson('/api/login', ['email' => 'Owner@example.test', 'password' => 'Exemple-l’été-déjà', 'role' => 'ADMIN'])
            ->assertOk();
    }

    public function test_only_account_without_an_email_aborts_before_deleting(): void
    {
        $this->user('SUPERADMIN', 'super@test.com');

        $this->artisan('system:reset', ['--force' => true, '--only-account' => true])->assertFailed();

        $this->assertSame(1, DB::table('users')->count());
    }

    public function test_an_invalid_admin_email_aborts_before_deleting(): void
    {
        $this->user('SUPERADMIN', 'super@test.com');
        $this->user('ADMIN', 'admin@test.com');

        $this->artisan('system:reset', ['--force' => true, '--admin-email' => 'not-an-email', '--admin-password' => 'longenough'])
            ->assertFailed();

        $this->assertSame(2, DB::table('users')->count());
    }

    public function test_it_refuses_without_a_super_admin_and_changes_nothing(): void
    {
        $this->user('ADMIN', 'admin@test.com');

        $this->artisan('system:reset', ['--force' => true])->assertFailed();

        $this->assertSame(1, DB::table('users')->count());
    }

    public function test_wrong_confirmation_cancels(): void
    {
        $this->user('SUPERADMIN', 'super@test.com');
        $this->user('ADMIN', 'admin@test.com');

        $this->artisan('system:reset')->expectsQuestion('Type RESET to continue', 'no')->assertSuccessful();

        $this->assertSame(2, DB::table('users')->count());
    }
}
