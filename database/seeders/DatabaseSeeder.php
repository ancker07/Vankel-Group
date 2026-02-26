<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Super Admin
        User::updateOrCreate(
            ['email' => 'admin@vanakel.com'],
            [
                'name' => 'Super Admin',
                'password' => bcrypt('admin123'),
                'role' => 'SUPERADMIN',
                'status' => 'APPROVED',
            ]
        );

        // Syndic User
        User::updateOrCreate(
            ['email' => 'syndic@demo.com'],
            [
                'name' => 'Demo Syndic',
                'password' => bcrypt('demo123'),
                'role' => 'SYNDIC',
                'status' => 'APPROVED',
            ]
        );

        // Create Seed Data
        $syndic = \App\Models\Syndic::create([
            'company_name' => 'ImmoTrust Syndic',
            'contact_person' => 'Jean Dupont',
            'email' => 'contact@immotrust.be',
            'phone' => '+32 470 11 22 33',
        ]);

        $building = \App\Models\Building::create([
            'address' => 'Avenue Louise 123',
            'city' => 'Brussels',
            'syndic_id' => $syndic->id,
        ]);

        \App\Models\Mission::create([
            'building_id' => $building->id,
            'title' => 'Basement Lighting',
            'description' => 'Suggested upgrade for emergency lighting in basement due to flickering lights.',
            'urgency' => 'NORMAL',
            'status' => 'PENDING',
            'requested_by' => 'SYNDIC',
            'category' => 'ELECTRICITY',
            'sector' => 'ELECTRICITY',
        ]);

        \App\Models\Intervention::create([
            'building_id' => $building->id,
            'title' => 'Water Leak in Garage',
            'description' => 'Heavy water infiltration detected in level -1.',
            'urgency' => 'HIGH',
            'status' => 'ONGOING',
            'category' => 'PLUMBING',
            'sector' => 'PLUMBING',
        ]);
    }
}

