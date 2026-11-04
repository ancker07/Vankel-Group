<?php

namespace Tests\Feature;

use App\Models\Email;
use App\Models\Mission;
use App\Models\User;
use App\Support\UploadRules;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UploadValidationTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $user = User::create([
            'name' => 'Super', 'email' => 'super' . uniqid() . '@test.com', 'password' => 'password123',
            'role' => 'SUPERADMIN', 'status' => 'APPROVED',
        ]);
        Sanctum::actingAs($user);

        return $user;
    }

    private function mission(): Mission
    {
        return Mission::create(['requested_by' => 'SYNDIC', 'title' => 'T', 'description' => 'D', 'status' => 'PENDING']);
    }

    /** PHP only parses multipart bodies for POST, so updates are sent the way the apps send them. */
    private function updateMission(Mission $m, array $files)
    {
        return $this->post("/api/missions/{$m->id}", ['_method' => 'PUT'] + $files, ['Accept' => 'application/json']);
    }

    public function test_mission_update_accepts_office_documents_and_photos(): void
    {
        Storage::fake('public');
        $this->admin();
        $m = $this->mission();

        $res = $this->updateMission($m, [
            'files' => [
                UploadedFile::fake()->create('plan.xlsx', 200),
                UploadedFile::fake()->create('notes.txt', 5, 'text/plain'),
                UploadedFile::fake()->create('rapport.pdf', 300, 'application/pdf'),
            ],
            'photos' => [UploadedFile::fake()->image('leak.jpg')],
        ]);

        $res->assertOk();
        $this->assertCount(4, $m->documents()->get());
    }

    public function test_mission_update_rejects_dangerous_or_oversized_files(): void
    {
        Storage::fake('public');
        $this->admin();
        $m = $this->mission();

        foreach (['shell.php', 'page.html', 'logo.svg', 'tool.exe'] as $name) {
            $this->updateMission($m, ['files' => [UploadedFile::fake()->create($name, 10)]])
                ->assertStatus(422)
                ->assertJsonValidationErrors(['files.0']);
        }

        $this->updateMission($m, ['files' => [UploadedFile::fake()->create('big.pdf', 10241, 'application/pdf')]])
            ->assertStatus(422)->assertJsonValidationErrors(['files.0']);

        $this->updateMission($m, ['photos' => [UploadedFile::fake()->create('not-an-image.jpg', 10, 'text/plain')]])
            ->assertStatus(422)->assertJsonValidationErrors(['photos.0']);

        $this->assertCount(0, $m->documents()->get());
    }

    public function test_profile_picture_limit_allows_normal_phone_photos(): void
    {
        Storage::fake('public');
        $user = $this->admin();

        // 3 MB: used to be rejected by the old 2 MB limit
        $this->post('/api/profile/update', ['image' => UploadedFile::fake()->image('me.jpg')->size(3000)], ['Accept' => 'application/json'])
            ->assertOk();
        $first = $user->fresh()->image_url;
        Storage::disk('public')->assertExists($first);

        // replacing the picture removes the old file
        $this->post('/api/profile/update', ['image' => UploadedFile::fake()->image('me2.png')->size(100)], ['Accept' => 'application/json'])
            ->assertOk();
        Storage::disk('public')->assertMissing($first);
        Storage::disk('public')->assertExists($user->fresh()->image_url);

        $this->post('/api/profile/update', ['image' => UploadedFile::fake()->image('huge.jpg')->size(6000)], ['Accept' => 'application/json'])
            ->assertStatus(422)->assertJsonValidationErrors(['image']);

        $this->post('/api/profile/update', ['image' => UploadedFile::fake()->create('x.php', 10)], ['Accept' => 'application/json'])
            ->assertStatus(422)->assertJsonValidationErrors(['image']);
    }

    public function test_email_reply_attachments_are_restricted(): void
    {
        Storage::fake('public');
        Mail::fake();
        $this->admin();
        $email = Email::create(['message_id' => 'm1@test', 'from_address' => 'a@b.be', 'subject' => 'Hi', 'body_text' => 'x', 'received_at' => now()]);

        $this->post("/api/emails/{$email->id}/reply", [
            'body' => 'Merci', 'account' => 'no-reply',
            'attachments' => [UploadedFile::fake()->create('virus.exe', 10)],
        ], ['Accept' => 'application/json'])->assertStatus(422)->assertJsonValidationErrors(['attachments.0']);

        $this->post("/api/emails/{$email->id}/reply", [
            'body' => 'Merci', 'account' => 'no-reply',
            'attachments' => [UploadedFile::fake()->create('offre.pdf', 100, 'application/pdf')],
        ], ['Accept' => 'application/json'])->assertOk();
    }

    public function test_incoming_email_attachment_names_are_neutralised(): void
    {
        $this->assertMatchesRegularExpression('/^invoice_[0-9a-f]{8}\.bin$/', UploadRules::safeFileName('invoice.php'));
        $this->assertMatchesRegularExpression('/\.bin$/', UploadRules::safeFileName('x.html'));
        $this->assertMatchesRegularExpression('/\.bin$/', UploadRules::safeFileName('x.php.jpg.svg'));
        $this->assertMatchesRegularExpression('/\.bin$/', UploadRules::safeFileName('noextension'));
        $this->assertMatchesRegularExpression('/^Facture_Eté_2026_[0-9a-f]{8}\.pdf$|^Facture_Ete_2026_[0-9a-f]{8}\.pdf$/', UploadRules::safeFileName('Facture Eté #2026?.PDF'));
        $this->assertStringNotContainsString('..', UploadRules::safeFileName('../../etc/passwd.txt'));
        $this->assertStringNotContainsString('/', UploadRules::safeFileName('../../etc/passwd.txt'));
        // two attachments with the same name in the same second must not overwrite each other
        $this->assertNotSame(UploadRules::safeFileName('a.pdf'), UploadRules::safeFileName('a.pdf'));
        $this->assertMatchesRegularExpression('/^attachment_[0-9a-f]{8}\.pdf$/', UploadRules::safeFileName('.pdf', 'attachment'));
    }
}
