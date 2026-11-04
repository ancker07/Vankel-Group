<?php

use App\Models\Permission;
use App\Models\Role;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Technicians only see what is assigned to them (their interventions), not the missions list.
     * Takes missions.view away from the built-in Technician role. Custom roles are left alone:
     * an admin can still give any role the permission on the Users & roles page.
     */
    public function up(): void
    {
        $technician = Role::where('name', 'PROFESSIONAL')->first();
        if ($technician) {
            $technician->permissions()->detach(Permission::where('key', 'missions.view')->pluck('id'));
        }
    }

    public function down(): void
    {
        $technician = Role::where('name', 'PROFESSIONAL')->first();
        if ($technician) {
            $technician->permissions()->syncWithoutDetaching(Permission::where('key', 'missions.view')->pluck('id'));
        }
    }
};
