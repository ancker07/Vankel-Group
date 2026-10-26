<?php

use App\Models\Permission;
use App\Models\Role;
use App\Support\PermissionCatalog;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * The ADMIN role is the operational manager and approves / rejects the
     * missions that arrive from syndics and email ingestion.
     */
    public function up(): void
    {
        PermissionCatalog::sync();

        $admin = Role::where('name', 'ADMIN')->first();
        if ($admin) {
            $admin->permissions()->syncWithoutDetaching(Permission::where('key', 'missions.approve')->pluck('id'));
        }
    }

    public function down(): void
    {
        $admin = Role::where('name', 'ADMIN')->first();
        if ($admin) {
            $admin->permissions()->detach(Permission::where('key', 'missions.approve')->pluck('id'));
        }
    }
};
