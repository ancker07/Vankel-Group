<?php

namespace Tests\Feature;

use App\Mail\InterventionReportMail;
use App\Models\Building;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\Notification;
use App\Models\Syndic;
use App\Models\User;
use App\Services\NotificationService;
use App\Support\MessageText;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class LocalizedNotificationsTest extends TestCase
{
    use RefreshDatabase;

    /** @var array<int, array{token: string, title: string, body: string}> */
    private array $pushes = [];

    protected function setUp(): void
    {
        parent::setUp();
        $this->pushes = [];

        // capture pushes instead of calling Firebase
        $service = Mockery::mock(NotificationService::class)->makePartial();
        $service->shouldReceive('sendNotification')->andReturnUsing(function ($token, $title, $body) {
            $this->pushes[] = ['token' => $token, 'title' => $title, 'body' => $body];

            return true;
        });
        $this->app->instance(NotificationService::class, $service);
    }

    private function user(string $role, ?string $locale, array $extra = []): User
    {
        $user = User::create($extra + [
            'name' => $role . uniqid(), 'email' => strtolower($role) . uniqid() . '@test.com', 'password' => 'password123',
            'role' => $role, 'status' => 'APPROVED', 'locale' => $locale, 'fcm_token' => 'token-' . uniqid(),
        ]);

        // missions / interventions reference the syndic by id (foreign key to the syndics table)
        if ($role === 'SYNDIC') {
            Syndic::create(['id' => $user->id, 'company_name' => 'Syndic ' . $user->id, 'email' => $user->email]);
        }

        return $user;
    }

    private function mission(User $syndic): Mission
    {
        return Mission::create([
            'requested_by' => 'SYNDIC', 'syndic_id' => $syndic->id, 'status' => 'PENDING', 'description' => 'd',
            'title' => 'Fuite toiture', 'title_en' => 'Roof leak', 'title_fr' => 'Fuite toiture', 'title_nl' => 'Dakkanaal lek',
        ]);
    }

    public function test_every_message_exists_in_all_three_languages_with_no_placeholder_left(): void
    {
        $params = ['title' => 'X', 'status' => 'S', 'urgency' => 'U', 'source' => 'R'];
        foreach (['mission_approved', 'mission_rejected', 'intervention_update', 'new_assignment', 'new_mission', 'urgent_mission'] as $key) {
            $titles = [];
            foreach (MessageText::LOCALES as $locale) {
                $m = MessageText::make($key, $locale, $params);
                $this->assertDoesNotMatchRegularExpression('/\{\w+\}/', $m['title'] . $m['body'], "$key/$locale");
                $titles[] = $m['title'];
            }
            $this->assertCount(3, array_unique($titles), "$key titles must differ per language");
        }
        foreach (MessageText::LOCALES as $locale) {
            foreach (MessageText::report($locale) as $key => $text) {
                $this->assertNotSame('', $text, "report.$key/$locale");
            }
        }
    }

    public function test_unknown_or_missing_language_falls_back_to_the_app_default(): void
    {
        $this->assertSame('en', MessageText::normalize(null));
        $this->assertSame('en', MessageText::normalize('de'));
        $this->assertSame('nl', MessageText::normalize('nl'));
        $this->assertSame('fr', MessageText::normalize('fr_BE'));
        $this->assertSame('Retardée', MessageText::word('status', 'DELAYED', 'fr'));
        $this->assertSame('WEIRD', MessageText::word('status', 'WEIRD', 'fr'));
    }

    public function test_rejection_push_and_in_app_notification_follow_the_syndics_language(): void
    {
        Sanctum::actingAs($this->user('SUPERADMIN', 'en'));

        foreach ([
            'nl' => ['Missie afgewezen', "Uw missie 'Dakkanaal lek' is helaas afgewezen."],
            'fr' => ['Mission refusée', 'Votre mission « Fuite toiture » a malheureusement été refusée.'],
            'en' => ['Mission Rejected', "Your mission 'Roof leak' was unfortunately rejected."],
            null => ['Mission Rejected', "Your mission 'Roof leak' was unfortunately rejected."], // never chose a language
        ] as $locale => [$title, $body]) {
            $this->pushes = [];
            $syndic = $this->user('SYNDIC', $locale === '' ? null : ($locale ?: null));
            $mission = $this->mission($syndic);

            $this->postJson("/api/missions/{$mission->id}/reject")->assertOk();

            $this->assertCount(1, $this->pushes);
            $this->assertSame($title, $this->pushes[0]['title'], "push title ($locale)");
            $this->assertSame($body, $this->pushes[0]['body'], "push body ($locale)");

            $row = Notification::where('user_id', $syndic->id)->latest('id')->first();
            $this->assertSame($title, $row->title);
            $this->assertSame('Mission refusée', $row->title_fr);
            $this->assertSame('Missie afgewezen', $row->title_nl);
            $this->assertSame('Mission Rejected', $row->title_en);
            $this->assertSame("Uw missie 'Dakkanaal lek' is helaas afgewezen.", $row->body_nl);
        }
    }

    public function test_assignment_notifies_the_technician_in_their_language(): void
    {
        $tech = $this->user('PROFESSIONAL', 'nl');
        $building = Building::create(['address' => 'Rue 1']);
        $intervention = Intervention::create([
            'building_id' => $building->id, 'title' => 'Chaudière', 'title_nl' => 'Verwarmingsketel', 'description' => 'd',
        ]);

        $controller = $this->app->make(\App\Http\Controllers\InterventionController::class);
        $method = new \ReflectionMethod($controller, 'notifyAssignedUser');
        $method->setAccessible(true);
        $method->invoke($controller, $tech, $intervention);

        $this->assertSame('Nieuwe toewijzing', $this->pushes[0]['title']);
        $this->assertStringContainsString('Verwarmingsketel', $this->pushes[0]['body']);
    }

    public function test_new_mission_alert_goes_to_each_admin_in_their_own_language(): void
    {
        $fr = $this->user('SUPERADMIN', 'fr');
        $nl = $this->user('SUPERADMIN', 'nl');
        $syndic = $this->user('SYNDIC', 'en');
        $mission = $this->mission($syndic);
        $mission->update(['urgency' => 'URGENT', 'source_type' => 'EMAIL']);

        $this->app->make(NotificationService::class)->notifyNewMission($mission->fresh());

        $byToken = collect($this->pushes)->keyBy('token');
        $this->assertSame('🚨 Mission urgente : Fuite toiture', $byToken[$fr->fcm_token]['title']);
        $this->assertSame('Urgence : Urgente. Reçue par e-mail.', $byToken[$fr->fcm_token]['body']);
        $this->assertSame('🚨 Dringende missie: Dakkanaal lek', $byToken[$nl->fcm_token]['title']);
        $this->assertSame('Urgentie: Dringend. Ontvangen per e-mail.', $byToken[$nl->fcm_token]['body']);
    }

    public function test_report_email_is_sent_to_each_recipient_in_their_language(): void
    {
        Mail::fake();
        Sanctum::actingAs($this->user('SUPERADMIN', 'en'));
        $nl = $this->user('SYNDIC', 'nl', ['email' => 'syndic-nl@test.com']);
        $building = Building::create(['address' => 'Rue de la Loi 67', 'city' => 'Bruxelles']);
        $intervention = Intervention::create([
            'building_id' => $building->id, 'syndic_id' => $nl->id, 'title' => 'Chaudière', 'title_nl' => 'Verwarmingsketel',
            'description' => 'd', 'status' => 'DELAYED', 'delay_reason' => 'no_access', 'on_site_contact_email' => 'concierge@test.com',
        ]);

        $this->postJson("/api/interventions/{$intervention->id}/send-report")->assertOk();

        $sent = [];
        Mail::assertSent(InterventionReportMail::class, function ($mail) use (&$sent) {
            foreach ($mail->to as $to) {
                $sent[$to['address']] = $mail->lang;
            }

            return true;
        });
        $this->assertSame('nl', $sent['syndic-nl@test.com']);
        $this->assertSame('nl', $sent['concierge@test.com']);   // no account: language of the requesting syndic
        $this->assertSame('nl', $sent['admin@vanakelgroup.com']);

        $html = html_entity_decode((new InterventionReportMail($intervention->fresh(), 'nl'))->render(), ENT_QUOTES);
        $this->assertStringContainsString('Gebouwinformatie', $html);
        $this->assertStringContainsString('Verwarmingsketel', $html);
        $this->assertStringContainsString('Geen toegang', $html);
        $this->assertStringNotContainsString('Informations de l', $html);

        $fr = html_entity_decode((new InterventionReportMail($intervention->fresh(), 'fr'))->render(), ENT_QUOTES);
        $this->assertStringContainsString("Informations de l'immeuble", $fr);
        $this->assertStringContainsString('Accès impossible', $fr);
        $this->assertStringContainsString('Retardé', $fr);

        $en = (new InterventionReportMail($intervention->fresh(), 'en'))->render();
        $this->assertStringContainsString('Building information', $en);
        $this->assertStringContainsString('No access', $en);
    }
}
