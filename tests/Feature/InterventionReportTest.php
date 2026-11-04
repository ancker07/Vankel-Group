<?php

namespace Tests\Feature;

use App\Mail\InterventionReportMail;
use App\Models\Assignment;
use App\Models\Building;
use App\Models\Email;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\Syndic;
use App\Models\User;
use App\Services\InterventionReportService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * "Save & send report": the technician and the person who asked for the work must receive it.
 */
class InterventionReportTest extends TestCase
{
    use RefreshDatabase;

    private User $technician;
    private User $syndicUser;
    private Intervention $intervention;
    private Mission $mission;

    protected function setUp(): void
    {
        parent::setUp();

        // the syndic exists as an account AND as a company record with the same id (that is how the data is linked)
        $this->syndicUser = User::create(['name' => 'Syndic', 'email' => 'syndic-user@test.be', 'password' => 'password123',
            'role' => 'SYNDIC', 'status' => 'APPROVED', 'locale' => 'nl']);
        Syndic::create(['id' => $this->syndicUser->id, 'company_name' => 'Syndic NV', 'email' => 'syndic-company@test.be']);
        $buildingSyndic = Syndic::create(['company_name' => 'Building Syndic', 'email' => 'building-syndic@test.be']);

        $this->technician = User::create(['name' => 'Tom', 'email' => 'tom@test.be', 'password' => 'password123',
            'role' => 'PROFESSIONAL', 'status' => 'APPROVED', 'locale' => 'fr']);

        $building = Building::create(['address' => 'Rue de la Loi 67', 'city' => 'Bruxelles', 'syndic_id' => $buildingSyndic->id]);

        // the work was asked for by e-mail
        Email::create(['message_id' => 'orig@mid', 'from_address' => 'owner@client.be', 'subject' => 'Fuite', 'body_text' => 'x', 'received_at' => now()]);
        $this->mission = Mission::create(['requested_by' => 'SYNDIC', 'title' => 'Fuite', 'description' => 'd', 'status' => 'APPROVED',
            'syndic_id' => $this->syndicUser->id, 'source_type' => 'EMAIL', 'source_message_id' => 'orig@mid',
            'on_site_contact_email' => 'mission-contact@test.be']);

        $this->intervention = Intervention::create(['building_id' => $building->id, 'title' => 'Fuite', 'description' => 'd',
            'status' => 'PENDING', 'pro_id' => $this->technician->id, 'syndic_id' => $this->syndicUser->id,
            'on_site_contact_email' => 'onsite@test.be']);
        Assignment::record($this->intervention->id, $this->mission->id, $this->technician->id, null);
    }

    public function test_the_report_goes_to_the_technician_and_to_the_person_who_asked_for_the_work(): void
    {
        $recipients = app(InterventionReportService::class)->recipients($this->intervention);

        foreach ([
            'admin@vanakelgroup.com' => 'office',
            'tom@test.be' => 'technician',
            'owner@client.be' => 'requester',          // sender of the original e-mail
            'syndic-company@test.be' => 'syndic',
            'syndic-user@test.be' => 'syndic',
            'building-syndic@test.be' => 'building_syndic',
            'onsite@test.be' => 'on_site_contact',
            'mission-contact@test.be' => 'on_site_contact',
        ] as $email => $reason) {
            $this->assertArrayHasKey($email, $recipients, "{$email} should receive the report");
            $this->assertSame($reason, $recipients[$email]);
        }
    }

    public function test_addresses_are_deduplicated_and_invalid_ones_ignored(): void
    {
        $this->intervention->update(['on_site_contact_email' => 'TOM@test.be']); // same person as the technician
        $this->mission->update(['on_site_contact_email' => 'not an email']);

        $recipients = array_keys(app(InterventionReportService::class)->recipients($this->intervention->fresh()));

        $this->assertCount(count(array_unique(array_map('strtolower', $recipients))), $recipients);
        $this->assertNotContains('not an email', $recipients);
        $this->assertCount(1, array_filter($recipients, fn ($e) => strtolower($e) === 'tom@test.be'));
    }

    public function test_one_address_the_mail_server_rejects_does_not_stop_the_others(): void
    {
        $delivered = [];
        $result = app(InterventionReportService::class)->send($this->intervention, function (string $email, InterventionReportMail $mail) use (&$delivered) {
            if ($email === 'onsite@test.be') {
                throw new \RuntimeException('550 mailbox unavailable');
            }
            $delivered[] = $email;
        });

        $this->assertContains('tom@test.be', $result['sent']);
        $this->assertContains('owner@client.be', $result['sent']);
        $this->assertSame($delivered, $result['sent']);
        $this->assertSame([['email' => 'onsite@test.be', 'error' => '550 mailbox unavailable']], $result['failed']);
    }

    public function test_each_recipient_gets_the_report_in_their_own_language(): void
    {
        $languages = [];
        app(InterventionReportService::class)->send($this->intervention, function (string $email, InterventionReportMail $mail) use (&$languages) {
            $languages[$email] = $mail->lang;
        });

        $this->assertSame('fr', $languages['tom@test.be']);
        $this->assertSame('nl', $languages['syndic-user@test.be']);
        $this->assertSame('nl', $languages['owner@client.be']); // no account: language of the requesting syndic
    }

    public function test_save_and_send_from_the_phone_really_sends_the_report(): void
    {
        Mail::fake();
        Sanctum::actingAs($this->technician);

        // exactly what the phone sends: the save with save_mode=EMAIL (no separate send-report call)
        $response = $this->post("/api/interventions/{$this->intervention->id}", [
            '_method' => 'PUT', 'save_mode' => 'EMAIL', 'admin_feedback' => 'Fuite réparée',
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertContains('tom@test.be', $response->json('report.sent'));
        $this->assertContains('owner@client.be', $response->json('report.sent'));
        $this->assertSame([], $response->json('report.failed'));

        foreach (['tom@test.be', 'owner@client.be', 'syndic-user@test.be', 'admin@vanakelgroup.com'] as $email) {
            Mail::assertSent(InterventionReportMail::class, fn ($mail) => $mail->hasTo($email));
        }
        $this->assertSame('Fuite réparée', $this->intervention->fresh()->admin_feedback, 'the save itself still happens');
    }

    public function test_saving_without_send_does_not_send_anything(): void
    {
        Mail::fake();
        Sanctum::actingAs($this->technician);

        $response = $this->post("/api/interventions/{$this->intervention->id}", [
            '_method' => 'PUT', 'save_mode' => 'NONE', 'admin_feedback' => 'Note',
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertNull($response->json('report'));
        Mail::assertNothingSent();
    }

    public function test_a_mail_failure_does_not_undo_the_save_and_is_reported(): void
    {
        Sanctum::actingAs($this->technician);
        // every send fails (e.g. SMTP down)
        Mail::shouldReceive('to')->andThrow(new \RuntimeException('SMTP connection refused'));

        $response = $this->post("/api/interventions/{$this->intervention->id}", [
            '_method' => 'PUT', 'save_mode' => 'EMAIL', 'admin_feedback' => 'Gardé',
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertSame([], $response->json('report.sent'));
        $this->assertNotEmpty($response->json('report.failed'));
        $this->assertStringContainsString('SMTP connection refused', $response->json('report.failed.0.error'));
        $this->assertSame('Gardé', $this->intervention->fresh()->admin_feedback);
    }

    public function test_the_send_report_endpoint_lists_who_got_it_and_fails_loudly_when_nobody_did(): void
    {
        $admin = User::create(['name' => 'Ada', 'email' => 'ada@test.be', 'password' => 'password123', 'role' => 'ADMIN', 'status' => 'APPROVED']);
        Sanctum::actingAs($admin);

        Mail::fake();
        $this->postJson("/api/interventions/{$this->intervention->id}/send-report")
            ->assertOk()
            ->assertJsonPath('failed', [])
            ->assertJsonFragment(['recipients' => app(InterventionReportService::class)->send($this->intervention->fresh(), fn () => null)['sent']]);

        Mail::shouldReceive('to')->andThrow(new \RuntimeException('SMTP down'));
        $this->postJson("/api/interventions/{$this->intervention->id}/send-report")
            ->assertStatus(500)
            ->assertJsonPath('error', 'SMTP down');
    }
}
