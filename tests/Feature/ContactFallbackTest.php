<?php

namespace Tests\Feature;

use App\Models\Assignment;
use App\Models\Building;
use App\Models\Intervention;
use App\Models\Mission;
use App\Models\Syndic;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ContactFallbackTest extends TestCase
{
    use RefreshDatabase;

    public function test_missing_contact_details_come_from_the_mission_then_the_syndic(): void
    {
        $syndic = Syndic::create(['company_name' => 'Gest', 'email' => 'office@gest.be', 'phone' => '+32 2 111']);
        $building = Building::create(['address' => 'Rue 1', 'syndic_id' => $syndic->id]);
        $mission = Mission::create(['building_id' => $building->id, 'title' => 'm', 'description' => 'd', 'status' => 'APPROVED',
            'requested_by' => 'SYNDIC', 'on_site_contact_phone' => '+32 470 000']);
        $intervention = Intervention::create(['building_id' => $building->id, 'title' => 't', 'description' => 'd', 'status' => 'PENDING',
            'on_site_contact_name' => 'M. De Moor']);
        $tech = \App\Models\User::create(['name' => 'T', 'email' => 't@t.be', 'password' => 'password123', 'role' => 'PROFESSIONAL', 'status' => 'APPROVED']);
        Assignment::record($intervention->id, $mission->id, $tech->id, null);

        $this->assertSame(['phone' => '+32 470 000', 'email' => 'office@gest.be'], $intervention->fresh()->contact_fallback);
    }

    public function test_its_own_contact_wins_and_nothing_known_stays_empty(): void
    {
        $building = Building::create(['address' => 'Rue 2']);
        $own = Intervention::create(['building_id' => $building->id, 'title' => 't', 'description' => 'd', 'status' => 'PENDING',
            'on_site_contact_phone' => '0499', 'on_site_contact_email' => 'me@x.be']);
        $none = Intervention::create(['building_id' => $building->id, 'title' => 't', 'description' => 'd', 'status' => 'PENDING']);

        $this->assertSame(['phone' => '0499', 'email' => 'me@x.be'], $own->contact_fallback);
        $this->assertSame(['phone' => null, 'email' => null], $none->contact_fallback);
    }
}
