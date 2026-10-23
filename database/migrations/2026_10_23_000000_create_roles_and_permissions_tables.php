<?php

use App\Models\Permission;
use App\Models\Role;
use App\Support\PermissionCatalog;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique(); // stored in users.role
            $table->string('label');
            $table->string('description')->nullable();
            $table->string('portal')->default('admin'); // admin = staff app, syndic = client app
            $table->boolean('is_system')->default(false);
            $table->timestamps();
        });

        Schema::create('permissions', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->string('label');
            $table->string('group');
            $table->timestamps();
        });

        Schema::create('permission_role', function (Blueprint $table) {
            $table->foreignId('role_id')->constrained()->cascadeOnDelete();
            $table->foreignId('permission_id')->constrained()->cascadeOnDelete();
            $table->primary(['role_id', 'permission_id']);
        });

        // Seed the permission catalog and the built-in roles (same access as before)
        PermissionCatalog::sync();

        foreach (PermissionCatalog::DEFAULT_ROLES as $name => [$label, $portal, $keys]) {
            $role = Role::create(['name' => $name, 'label' => $label, 'portal' => $portal, 'is_system' => true]);
            $ids = $keys === ['*'] ? Permission::pluck('id') : Permission::whereIn('key', $keys)->pluck('id');
            $role->permissions()->sync($ids);
        }

        // Any other role already used by users gets an empty role so nothing is orphaned
        DB::table('users')->whereNotNull('role')->distinct()->pluck('role')
            ->reject(fn ($name) => Role::where('name', $name)->exists())
            ->each(fn ($name) => Role::create(['name' => $name, 'label' => ucfirst(strtolower($name))]));
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('permission_role');
        Schema::dropIfExists('permissions');
        Schema::dropIfExists('roles');
    }
};
