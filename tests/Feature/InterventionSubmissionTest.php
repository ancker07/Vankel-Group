<?php

namespace Tests\Feature;

use App\Models\Assignment;
use App\Models\Building;
use App\Models\Intervention;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

/** "Send to Admin": the technician hands the work over for review. */
class InterventionSubmissionTest extends TestCase
{
    use RefreshDatabase;

    /** @var array<int, array{token: string, title: string, body: string}> */
    private array $pushes = [];
    private User $technician;
    private User $admin;
    private Intervention $intervention;

    protected function setUp(): void
    {
        parent::setUp();
        $this->pushes = [];
        $service = Mockery::mock(NotificationService::class)->makePartial();
        $service->shouldReceive('sendNotification')->andReturnUsing(function ($token, $title, $body) {
            $this->pushes[] = ['token' => $token, 'title' => $title, 'body' => $body];

            return true;
        });
        $this->app->instance(NotificationService::class, $service);

        $this->technician = User::create(['name' => 'Tom', 'email' => 'tom@test.be', 'password' => 'password123', 'role' => 'PROFESSIONAL',
            'status' => 'APPROVED', 'locale' => 'fr', 'fcm_token' => 'tech-token']);
        $this->admin = User::create(['name' => 'Ada', 'email' => 'ada@test.be', 'password' => 'password123', 'role' => 'ADMIN',
            'status' => 'APPROVED', 'locale' => 'nl', 'fcm_token' => 'admin-token']);
        $building = Building::create(['address' => 'Rue de la Loi 67']);
        $this->intervention = Intervention::create(['building_id' => $building->id, 'title' => 'Fuite', 'title_nl' => 'Lek',
            'description' => 'd', 'status' => 'PENDING', 'pro_id' => $this->technician->id]);
        Assignment::record($this->intervention->id, null, $this->technician->id, null);
    }

    private function save(array $fields, array $headers = [])
    {
        return $this->post("/api/interventions/{$this->intervention->id}", ['_method' => 'PUT'] + $fields, ['Accept' => 'application/json'] + $headers);
    }

    public function test_technician_sends_completed_work_to_the_admin(): void
    {
        Sanctum::actingAs($this->technician);

        $response = $this->save(['save_mode' => 'SUBMIT', 'status' => 'COMPLETED', 'admin_feedback' => 'Fuite réparée'])
            ->assertOk()
            ->assertJsonPath('submitted', true)
            ->assertJsonPath('intervention.status', 'COMPLETED')
            ->assertJsonPath('intervention.submitter.name', 'Tom');

        $fresh = $this->intervention->fresh();
        $this->assertNotNull($fresh->submitted_at);
        $this->assertSame($this->technician->id, (int) $fresh->submitted_by);
        $this->assertSame('Fuite réparée', $fresh->admin_feedback);
        $this->assertNotNull($response->json('intervention.submitted_at'));
    }

    public function test_technician_can_send_a_delayed_job_with_its_reason(): void
    {
        Sanctum::actingAs($this->technician);

        $this->save(['save_mode' => 'SUBMIT', 'status' => 'DELAYED', 'delay_reason' => 'no_access', 'delay_details' => 'Locataire absent'])
            ->assertOk()->assertJsonPath('intervention.status', 'DELAYED');

        $this->assertNotNull($this->intervention->fresh()->submitted_at);
    }

    public function test_only_completed_or_delayed_can_be_sent_and_nothing_changes_when_refused(): void
    {
        Sanctum::actingAs($this->technician);

        // still "in progress"
        $this->save(['save_mode' => 'SUBMIT', 'admin_feedback' => 'x'], ['Accept-Language' => 'fr'])
            ->assertStatus(422)
            ->assertJsonPath('message', "Choisissez Terminé ou Retardé avant d'envoyer à l'admin.");
        // delayed without a reason
        $this->save(['save_mode' => 'SUBMIT', 'status' => 'DELAYED', 'admin_feedback' => 'x'], ['Accept-Language' => 'nl'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Selecteer de reden van de vertraging voordat u naar de beheerder verzendt.');

        $fresh = $this->intervention->fresh();
        $this->assertNull($fresh->submitted_at);
        $this->assertSame('PENDING', $fresh->status);
        $this->assertNull($fresh->admin_feedback);
        $this->assertSame([], $this->pushes);
    }

    public function test_admins_are_notified_in_their_own_language_and_the_technician_is_not(): void
    {
        Sanctum::actingAs($this->technician);

        $this->save(['save_mode' => 'SUBMIT', 'status' => 'COMPLETED'])->assertOk();

        $tokens = array_column($this->pushes, 'token');
        $this->assertContains('admin-token', $tokens);
        $this->assertNotContains('tech-token', $tokens);

        $push = collect($this->pushes)->firstWhere('token', 'admin-token');
        $this->assertSame('Interventie ter controle verzonden', $push['title']); // the admin chose Dutch
        $this->assertStringContainsString('Tom', $push['body']);
        $this->assertStringContainsString('Lek', $push['body']);                  // title in Dutch too
        $this->assertStringContainsString('Voltooid', $push['body']);
    }

    public function test_the_admin_saving_it_counts_as_the_review(): void
    {
        $this->intervention->update(['submitted_at' => now(), 'submitted_by' => $this->technician->id, 'status' => 'COMPLETED']);

        // an unrelated technician edit does not clear it... the admin's save does
        Sanctum::actingAs($this->admin);
        $this->save(['save_mode' => 'NONE', 'status' => 'COMPLETED', 'admin_feedback' => 'Vérifié'])->assertOk()->assertJsonPath('submitted', false);

        $fresh = $this->intervention->fresh();
        $this->assertNull($fresh->submitted_at);
        $this->assertNull($fresh->submitted_by);
    }

    public function test_a_technician_cannot_change_completed_work_afterwards(): void
    {
        Sanctum::actingAs($this->technician);
        $this->save(['save_mode' => 'SUBMIT', 'status' => 'COMPLETED'])->assertOk();

        // locked: only an admin can change it now (existing rule, unchanged)
        $this->save(['save_mode' => 'SUBMIT', 'status' => 'COMPLETED', 'admin_feedback' => 'again'])->assertForbidden();
    }

    public function test_a_technician_can_only_send_his_own_interventions(): void
    {
        $other = User::create(['name' => 'Other', 'email' => 'other@test.be', 'password' => 'password123', 'role' => 'PROFESSIONAL', 'status' => 'APPROVED']);
        Sanctum::actingAs($other);

        $this->save(['save_mode' => 'SUBMIT', 'status' => 'COMPLETED'])->assertForbidden();
        $this->assertNull($this->intervention->fresh()->submitted_at);
    }

    public function test_the_list_tells_who_sent_what_for_review(): void
    {
        $this->intervention->update(['submitted_at' => now(), 'submitted_by' => $this->technician->id]);
        Sanctum::actingAs($this->admin);

        $row = collect($this->getJson('/api/interventions')->assertOk()->json())->firstWhere('id', $this->intervention->id);

        $this->assertNotNull($row['submitted_at']);
        $this->assertSame('Tom', $row['submitter']['name']);
    }

    // ---- resilience: the technician's "send to admin" must not end in an error --------------------------------

    public function test_a_retry_of_a_submission_whose_answer_was_lost_is_answered_as_done(): void
    {
        Sanctum::actingAs($this->technician);
        $fields = ['save_mode' => 'SUBMIT', 'status' => 'COMPLETED', 'submission_id' => 'abc-123'];

        $this->save($fields)->assertOk();
        // the same submission again (the phone never got the answer): done, not "completed, only an admin can change it"
        $this->save($fields)->assertOk()->assertJsonPath('duplicate', true);
        // a different submission is still locked
        $this->save(['submission_id' => 'other'] + $fields)->assertForbidden();
    }

    public function test_a_bad_attachment_is_skipped_and_reported_instead_of_failing_the_whole_send(): void
    {
        \Illuminate\Support\Facades\Storage::fake('public');
        Sanctum::actingAs($this->technician);

        $this->save([
            'save_mode' => 'SUBMIT', 'status' => 'COMPLETED',
            'photos' => [\Illuminate\Http\UploadedFile::fake()->image('ok.jpg'), \Illuminate\Http\UploadedFile::fake()->create('virus.exe', 10)],
            'files' => [\Illuminate\Http\UploadedFile::fake()->create('too-big.pdf', 20000)],
        ])->assertOk()->assertJsonPath('intervention.status', 'COMPLETED')
            ->assertJsonFragment(['warnings' => ['file virus.exe', 'file too-big.pdf']]);

        $fresh = $this->intervention->fresh();
        $this->assertNotNull($fresh->submitted_at);
        $this->assertSame(['ok.jpg'], $fresh->documents()->pluck('file_name')->all(), 'only the valid photo was kept');
    }

    public function test_a_failing_notification_does_not_turn_a_saved_send_into_an_error(): void
    {
        $service = Mockery::mock(NotificationService::class)->makePartial();
        $service->shouldReceive('notifyUser')->andThrow(new \RuntimeException('push service down'));
        $this->app->instance(NotificationService::class, $service);
        Sanctum::actingAs($this->technician);

        $this->save(['save_mode' => 'SUBMIT', 'status' => 'COMPLETED'])
            ->assertOk()
            ->assertJsonPath('submitted', true)
            ->assertJsonFragment(['warnings' => ['notification to the admins']]);

        $this->assertNotNull($this->intervention->fresh()->submitted_at, 'the hand-over is recorded even though the push failed');
    }

    public function test_a_technician_assigned_through_the_mission_may_still_send(): void
    {
        $building = Building::create(['address' => 'Street 2']);
        $other = User::create(['name' => 'Eve', 'email' => 'eve@test.be', 'password' => 'password123', 'role' => 'PROFESSIONAL', 'status' => 'APPROVED']);
        $mission = \App\Models\Mission::create(['building_id' => $building->id, 'title' => 'm', 'description' => 'd', 'status' => 'APPROVED',
            'requested_by' => 'SYNDIC', 'assigned_user_id' => $other->id]);
        // the intervention's own pro_id points elsewhere, but its mission is assigned to Eve
        $intervention = Intervention::create(['building_id' => $building->id, 'title' => 'x', 'description' => 'd', 'status' => 'PENDING', 'pro_id' => $this->admin->id]);
        Assignment::record($intervention->id, $mission->id, $this->admin->id, null);
        Assignment::where('intervention_id', $intervention->id)->update(['unassigned_at' => now()]);
        Assignment::create(['intervention_id' => $intervention->id, 'mission_id' => $mission->id, 'user_id' => $this->admin->id, 'assigned_at' => now(), 'unassigned_at' => now()]);

        Sanctum::actingAs($other);
        $this->post("/api/interventions/{$intervention->id}", ['_method' => 'PUT', 'save_mode' => 'SUBMIT', 'status' => 'COMPLETED'], ['Accept' => 'application/json'])->assertOk();
    }
}
