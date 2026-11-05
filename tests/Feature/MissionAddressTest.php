<?php

namespace Tests\Feature;

use App\Models\Building;
use App\Models\Mission;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MissionAddressTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Http::fake();
        Sanctum::actingAs(User::create([
            'name' => 'Super', 'email' => 'super' . uniqid() . '@test.com', 'password' => 'password123',
            'role' => 'SUPERADMIN', 'status' => 'APPROVED',
        ]));
    }

    private function mission(array $extra = []): Mission
    {
        return Mission::create($extra + ['requested_by' => 'SYNDIC', 'title' => 'T', 'description' => 'D', 'status' => 'NEEDS_REVIEW']);
    }

    /** Sent the way the mobile app sends an edit. */
    private function mobileEdit(Mission $m, array $fields)
    {
        return $this->post("/api/missions/{$m->id}", ['_method' => 'PUT', 'title' => 'T', 'description' => 'D'] + $fields, ['Accept' => 'application/json']);
    }

    public function test_missions_without_address_are_listed_last_but_not_hidden(): void
    {
        $building = Building::create(['address' => 'Rue Haute 1', 'city' => 'Bruxelles']);
        $none = $this->mission(['title' => 'none']);
        $blank = $this->mission(['title' => 'blank', 'extracted_address' => '  ']);
        $old = $this->mission(['title' => 'with building', 'building_id' => $building->id]);
        $text = $this->mission(['title' => 'with text', 'extracted_address' => 'Rue Basse 2']);
        Mission::whereKey($none->id)->update(['created_at' => now()->addDay()]);

        $ids = collect($this->getJson('/api/missions')->assertOk()->json())->pluck('id');

        $this->assertCount(4, $ids);
        $this->assertEqualsCanonicalizing([$old->id, $text->id], $ids->take(2)->all());
        $this->assertEqualsCanonicalizing([$none->id, $blank->id], $ids->slice(2)->values()->all());
    }

    public function test_address_added_on_mobile_is_saved_and_mission_can_then_be_approved(): void
    {
        $m = $this->mission();
        $this->postJson("/api/missions/{$m->id}/approve", ['scheduled_date' => '2026-12-01'])->assertStatus(422);

        $this->mobileEdit($m, ['addressFull' => 'Rue Neuve 10, 1000 Bruxelles'])->assertOk();

        $m->refresh();
        $this->assertSame('Rue Neuve 10, 1000 Bruxelles', $m->building->address);
        $this->postJson("/api/missions/{$m->id}/approve", ['scheduled_date' => '2026-12-01'])->assertSuccessful();
        $this->assertSame('APPROVED', $m->fresh()->status);
    }

    public function test_changing_address_never_edits_the_old_building_or_matches_a_similar_one(): void
    {
        $old = Building::create(['address' => 'Rue Haute 1', 'city' => 'X']);
        $similar = Building::create(['address' => 'Rue Haute 12', 'city' => 'X']);
        $m = $this->mission(['building_id' => $similar->id]);

        $this->mobileEdit($m, ['addressFull' => 'rue haute 1'])->assertOk();
        $this->assertSame($old->id, $m->fresh()->building_id);
        $this->assertSame('Rue Haute 12', $similar->fresh()->address);
        $this->assertSame(2, Building::count());
    }

    public function test_unchanged_or_empty_address_keeps_the_building_and_other_fields_save(): void
    {
        $b = Building::create(['address' => 'Rue Haute 1', 'city' => 'X']);
        $m = $this->mission(['building_id' => $b->id]);

        $this->mobileEdit($m, ['addressFull' => 'Rue Haute 1', 'urgency' => 'HIGH', 'sector' => 'CHAUFFAGE', 'onSiteContactName' => 'Ann', 'onSiteContactPhone' => '0470'])->assertOk();
        $this->mobileEdit($m, ['addressFull' => ''])->assertOk();

        $fresh = $m->fresh();
        $this->assertSame($b->id, $fresh->building_id);
        $this->assertSame(1, Building::count());
        $this->assertSame('HIGH', $fresh->urgency);
        $this->assertSame('CHAUFFAGE', $fresh->sector);
        $this->assertSame('Ann', $fresh->on_site_contact_name);
        $this->assertSame('0470', $fresh->on_site_contact_phone);
    }

    public function test_extracted_address_is_replaced_by_the_edit(): void
    {
        $m = $this->mission(['extracted_address' => 'Quelque part']);
        $this->mobileEdit($m, ['addressFull' => 'Rue Neuve 10'])->assertOk();
        $this->assertNull($m->fresh()->extracted_address);
        $this->assertNotNull($m->fresh()->building_id);
    }
}
