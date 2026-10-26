<?php

use App\Models\Permission;
use App\Models\Role;
use App\Support\PermissionCatalog;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * The ADMIN role can again manage users: approve / reject, change role and
     * reset passwords. Creating users stays restricted to the super admin.
     */
    public function up(): void
    {
        PermissionCatalog::sync();

        $admin = Role::where('name', 'ADMIN')->first();
        if ($admin) {
            $admin->permissions()->syncWithoutDetaching(Permission::where('key', 'users.update')->pluck('id'));
        }
    }

    public function down(): void
    {
        $admin = Role::where('name', 'ADMIN')->first();
        if ($admin) {
            $admin->permissions()->detach(Permission::where('key', 'users.update')->pluck('id'));
        }
    }
};
