<?php

namespace Tests\Feature;

use App\Models\Document;
use App\Models\Email;
use App\Models\Mission;
use App\Models\MissionUpdate;
use App\Services\AiService;
use App\Services\EmailIngestionService;
use App\Services\MissionDeduplicator;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Mockery;
use Tests\TestCase;

class MissionDeduplicationTest extends TestCase
{
    use RefreshDatabase;

    private int $seq = 0;
    private $notifications;

    private function email(string $subject, ?string $threadId = null): Email
    {
        $this->seq++;

        return Email::create([
            'message_id' => "msg-{$this->seq}@test",
            'thread_id' => $threadId,
            'from_address' => 'syndic@example.com',
            'subject' => $subject,
            'body_text' => "Body of {$subject}",
            'received_at' => now()->addSeconds($this->seq),
        ]);
    }

    private function ingest(Email $email, string $title, ?string $reference = null, string $address = 'Rue de la Loi 67, Bruxelles', string $number = '67', ?MissionDeduplicator $deduper = null): array
    {
        $ai = Mockery::mock(AiService::class);
        $ai->shouldReceive('extractEmailData')->andReturn([
            'classification' => 'MISSION',
            'reasons' => ['test'],
            'mission' => [
                'title' => $title,
                'description' => "Description {$title}",
                'reference' => $reference,
                'address' => ['raw' => $address, 'street' => explode(' ', $address)[0], 'number' => $number, 'city' => 'Bruxelles'],
            ],
        ]);
        $this->notifications ??= Mockery::mock(NotificationService::class)->shouldIgnoreMissing();

        return (new EmailIngestionService($ai, $this->notifications, $deduper))->ingest($email);
    }

    public function test_follow_up_with_same_reference_is_attached_not_duplicated(): void
    {
        $first = $this->ingest($this->email('Demande AO-3008'), 'Fuite toiture', 'AO-3008');
        $second = $this->ingest($this->email('RAPPEL: ao 3008 urgent'), 'Rappel intervention toiture', null, 'Autre adresse 12, Liège', '12');

        $this->assertCount(1, Mission::all());
        $this->assertTrue($second['attached_to_existing']);
        $this->assertSame($first['mission_id'], $second['mission_id']);
        $this->assertCount(1, MissionUpdate::all());
        $this->assertSame('reference', MissionUpdate::first()->match_reason);
        // the AI picked another building for the follow-up: the original building is kept
        $this->assertSame($first['building_id'], Mission::first()->building_id);
    }

    private function existingMission(array $attrs = []): Mission
    {
        return Mission::create($attrs + ['requested_by' => 'SYNDIC', 'title' => 'Panne ascenseur bloc A', 'description' => 'd',
            'status' => 'PENDING', 'source_message_id' => 'orig@test']);
    }

    public function test_same_thread_is_attached_to_the_existing_mission(): void
    {
        // e.g. an email re-ingested after an admin reset, or a thread whose first email was never linked
        $mission = $this->existingMission(['thread_id' => 'thread-1']);

        $second = $this->ingest($this->email('Re: Panne ascenseur', 'thread-1'), 'Totally different title', null, 'Elsewhere 5, Gand', '5');

        $this->assertCount(1, Mission::all());
        $this->assertSame('thread', MissionUpdate::first()->match_reason);
        $this->assertTrue($second['attached_to_existing']);
        $this->assertSame($mission->id, $second['mission_id']);
        $this->assertSame('PROCESSED', Email::first()->ingestion_status);
    }

    public function test_same_thread_but_different_job_reference_is_not_merged(): void
    {
        $this->existingMission(['thread_id' => 'thread-2', 'reference' => 'AO-100']);

        $this->ingest($this->email('Dossier', 'thread-2'), 'Job two', 'AO-200', 'Rue Neuve 1, Bruxelles', '1');

        $this->assertCount(2, Mission::all());
    }

    public function test_same_building_and_very_similar_title_is_attached(): void
    {
        $this->ingest($this->email('a'), 'Remplacement ascenseur Rue de la Loi 67');
        $second = $this->ingest($this->email('b'), 'Remplacement ascenseur rue de la Loi 67 urgent');

        $this->assertCount(1, Mission::all());
        $this->assertSame('building_title', MissionUpdate::first()->match_reason);
        $this->assertGreaterThanOrEqual(85, MissionUpdate::first()->match_score);
        $this->assertTrue($second['attached_to_existing']);
    }

    public function test_borderline_title_creates_a_flagged_mission(): void
    {
        $first = $this->ingest($this->email('a'), 'Raccordement fibre Proximus Rue de la Loi 67');
        $second = $this->ingest($this->email('b'), 'Installation fibre Proximus Rue de la Loi 67');

        $this->assertCount(2, Mission::all());
        $flagged = Mission::find($second['mission_id']);
        $this->assertSame($first['mission_id'], $flagged->possible_duplicate_of_id);
        $this->assertSame('NEEDS_REVIEW', $flagged->status);
        $this->assertGreaterThanOrEqual(70, $flagged->duplicate_score);
        $this->assertLessThan(85, $flagged->duplicate_score);
        $this->assertSame($first['mission_id'], $second['possible_duplicate_of']);
    }

    public function test_unrelated_request_in_same_building_creates_a_new_mission(): void
    {
        $this->ingest($this->email('a'), 'Fuite toiture');
        $this->ingest($this->email('b'), 'Remplacement de la porte du garage');

        $this->assertCount(2, Mission::all());
        $this->assertNull(Mission::orderByDesc('id')->first()->possible_duplicate_of_id);
        $this->assertCount(0, MissionUpdate::all());
    }

    public function test_rejected_missions_do_not_absorb_new_requests(): void
    {
        $first = $this->ingest($this->email('x'), 'Fuite toiture', 'AO-3558');
        Mission::find($first['mission_id'])->update(['status' => 'REJECTED']);

        $this->ingest($this->email('y'), 'Fuite toiture', 'AO-3558');

        $this->assertCount(2, Mission::all());
    }

    public function test_new_mission_stores_thread_and_does_not_notify_for_attached_follow_ups(): void
    {
        $this->notifications = Mockery::mock(NotificationService::class);
        $this->notifications->shouldReceive('notifyNewMission')->once();

        $this->ingest($this->email('x', 'thread-9'), 'Fuite', 'QUE-29');
        $this->ingest($this->email('y'), 'Rappel', 'QUE-29');

        $this->assertSame('thread-9', Mission::first()->thread_id);
    }

    public function test_concurrent_ingestion_is_blocked_by_the_lock_and_retried_later(): void
    {
        $deduper = new MissionDeduplicator();
        $deduper->lockWait = 0;

        // another worker is currently creating the mission for AO-4000
        $held = Cache::lock('mission-ingest:ref:AO-4000', 60);
        $this->assertTrue($held->get());

        $email = $this->email('AO-4000');
        $result = $this->ingest($email, 'Job', 'AO-4000', deduper: $deduper);

        $this->assertSame('DEFERRED', $result['status']);
        $this->assertCount(0, Mission::all());
        $this->assertNull($email->fresh()->ingested_at, 'email must stay un-ingested so it is retried');

        $held->release();
        $retry = $this->ingest($email->fresh(), 'Job', 'AO-4000', deduper: $deduper);

        $this->assertSame('PROCESSED', $retry['status']);
        $this->assertCount(1, Mission::all());
    }

    public function test_locks_are_released_after_ingestion(): void
    {
        $this->ingest($this->email('AO-5000'), 'Job', 'AO-5000');

        $lock = Cache::lock('mission-ingest:ref:AO-5000', 5);
        $this->assertTrue($lock->get());
        $lock->release();
    }

    public function test_dedup_decisions_are_logged(): void
    {
        Log::spy();

        $this->ingest($this->email('x'), 'Fuite', 'AO-7000');
        $this->ingest($this->email('y'), 'Rappel', 'AO-7000');

        Log::shouldHaveReceived('info')->withArgs(fn ($m) => str_contains($m, 'attached to mission'))->once();
    }

    public function test_reference_extraction(): void
    {
        $d = new MissionDeduplicator();

        $this->assertSame(['AO-3008', 'INT-12', 'QUE-29', 'O261234'], $d->extractReferences('Re: AO 3008 / int-0012', 'que_29 and o261234'));
        $this->assertSame([], $d->extractReferences('no reference here', null));
    }

    public function test_merge_moves_everything_into_the_oldest_mission_and_flag_is_cleared(): void
    {
        $d = new MissionDeduplicator();
        $keeper = Mission::create(['requested_by' => 'SYNDIC', 'title' => 'Old', 'description' => 'd', 'status' => 'PENDING', 'source_message_id' => 'k@t']);
        $dupe = Mission::create(['requested_by' => 'SYNDIC', 'title' => 'New', 'description' => 'd2', 'status' => 'NEEDS_REVIEW', 'source_message_id' => 'd@t',
            'building_id' => null, 'reference' => 'AO-11', 'possible_duplicate_of_id' => $keeper->id, 'duplicate_score' => 80]);
        $dupe->documents()->create(['file_path' => 'a.pdf', 'file_name' => 'a.pdf', 'file_type' => 'application/pdf']);
        $keeper->documents()->create(['file_path' => 'b.pdf', 'file_name' => 'b.pdf', 'file_type' => 'application/pdf']);

        $merged = $d->merge($keeper, $dupe);

        $this->assertNull(Mission::find($dupe->id));
        $this->assertSame('AO-11', $merged->reference);
        $this->assertCount(2, Document::where('documentable_type', Mission::class)->where('documentable_id', $keeper->id)->get());
        $this->assertSame('MERGED_DUPLICATE', MissionUpdate::first()->type);
        $this->assertSame('d@t', MissionUpdate::first()->source_message_id);
    }

    public function test_cleanup_command_merges_each_group_into_its_oldest_mission(): void
    {
        $make = fn ($title, $ref, $msg) => Mission::create(['requested_by' => 'SYNDIC', 'title' => $title, 'description' => 'x', 'status' => 'PENDING',
            'reference' => $ref, 'source_message_id' => $msg]);

        $a1 = $make('Fuite A', 'AO-3008', 'm1');
        $a2 = $make('Relance fuite', 'AO-3008', 'm2');
        $a3 = $make('Fuite urgent', 'AO-3008', 'm3');
        $b1 = $make('Autre job', 'AO-11', 'm4');
        $b2 = $make('Autre job suite', 'AO-11', 'm5');
        $solo = $make('Seul', null, 'm6');
        // a thread-based group, no reference at all
        $t1 = $make('Chaudiere', null, 'm7');
        $t2 = $make('Chaudiere bis', null, 'm8');
        foreach (['m7' => 'm7', 'm8' => 'm7'] as $msg => $thread) {
            Email::create(['message_id' => $msg, 'thread_id' => $thread, 'from_address' => 'a@b.c', 'subject' => 's', 'received_at' => now()]);
        }

        // dry run changes nothing
        $this->artisan('missions:merge-duplicates')->assertSuccessful();
        $this->assertCount(8, Mission::all());

        $this->artisan('missions:merge-duplicates', ['--execute' => true])->assertSuccessful();

        $this->assertEqualsCanonicalizing([$a1->id, $b1->id, $solo->id, $t1->id], Mission::pluck('id')->all());
        $this->assertCount(4, MissionUpdate::where('type', 'MERGED_DUPLICATE')->get());

        // idempotent
        $this->artisan('missions:merge-duplicates', ['--execute' => true])->assertSuccessful();
        $this->assertCount(4, Mission::all());
    }

    public function test_cleanup_command_accepts_an_explicit_group_file(): void
    {
        $make = fn ($t, $m) => Mission::create(['requested_by' => 'SYNDIC', 'title' => $t, 'description' => 'x', 'status' => 'PENDING', 'source_message_id' => $m]);
        $a = $make('One', 'a'); $b = $make('Two', 'b'); $c = $make('Three', 'c');

        $file = tempnam(sys_get_temp_dir(), 'grp');
        file_put_contents($file, "{$a->id},{$c->id}\n");

        $this->artisan('missions:merge-duplicates', ['--execute' => true, '--file' => $file])->assertSuccessful();

        $this->assertEqualsCanonicalizing([$a->id, $b->id], Mission::pluck('id')->all());
        unlink($file);
    }
}
