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

        $this->call([
            SettingSeeder::class,
        ]);

    }
}

