<?php

use App\Models\Permission;
use App\Models\Role;
use App\Support\PermissionCatalog;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * - New permission interventions.reopen (given to ADMIN): completed missions are locked for everyone else.
     * - Only the super admin creates users: ADMIN loses users.create / users.update.
     */
    public function up(): void
    {
        PermissionCatalog::sync();

        $admin = Role::where('name', 'ADMIN')->first();
        if ($admin) {
            $admin->permissions()->syncWithoutDetaching(Permission::where('key', 'interventions.reopen')->pluck('id'));
            $admin->permissions()->detach(Permission::whereIn('key', ['users.create', 'users.update'])->pluck('id'));
        }
    }

    public function down(): void
    {
        $admin = Role::where('name', 'ADMIN')->first();
        if ($admin) {
            $admin->permissions()->syncWithoutDetaching(Permission::whereIn('key', ['users.create', 'users.update'])->pluck('id'));
        }
        Permission::where('key', 'interventions.reopen')->delete();
    }
};
