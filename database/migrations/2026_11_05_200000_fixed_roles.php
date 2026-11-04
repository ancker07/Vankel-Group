<?php

use App\Support\PermissionCatalog;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Only three roles remain: Super admin, Admin (system owner) and Technician. What each may do is
     * defined in PermissionCatalog; this brings the database in line (custom roles are removed and
     * their users become technicians).
     */
    public function up(): void
    {
        PermissionCatalog::sync();
        PermissionCatalog::syncRoles();
    }

    public function down(): void
    {
        // roles that were removed are not restored
    }
};
