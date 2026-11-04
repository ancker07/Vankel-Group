<?php

namespace App\Http\Controllers;

use App\Models\Permission;
use App\Support\PermissionCatalog;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    /**
     * The three fixed roles with their permissions and number of users (read-only: roles cannot be
     * created, edited or deleted).
     */
    public function index(Request $request)
    {
        $actor = $request->user();

        // only the three fixed roles are ever offered (the legacy client role is hidden)
        $roles = Role::whereIn('name', PermissionCatalog::FIXED_ROLES)->withCount('users')->get()
            ->sortBy(fn (Role $role) => array_search($role->name, PermissionCatalog::FIXED_ROLES))->values()
            ->map(fn (Role $role) => [
                'assignable' => $actor->canAssignRole($role),
                'full' => User::roleLimitReached($role->name) !== null,
                'id' => $role->id,
                'name' => $role->name,
                'label' => $role->label,
                'description' => PermissionCatalog::ROLE_DESCRIPTIONS[$role->name] ?? $role->description,
                'portal' => $role->portal,
                'is_system' => $role->is_system,
                'is_super_admin' => $role->isSuperAdmin(),
                'users_count' => $role->users_count,
                'permissions' => $role->permissionKeys(),
            ]);

        return response()->json($roles);
    }

    /**
     * The permission catalog, grouped for the UI.
     */
    public function permissions()
    {
        $groups = Permission::orderBy('id')->get(['key', 'label', 'group'])
            ->groupBy('group')
            ->map(fn ($permissions, $group) => ['group' => $group, 'permissions' => $permissions->values()])
            ->values();

        return response()->json($groups);
    }
}
