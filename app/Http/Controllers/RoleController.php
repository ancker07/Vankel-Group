<?php

namespace App\Http\Controllers;

use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RoleController extends Controller
{
    /**
     * All roles with their permissions and number of users.
     */
    public function index(Request $request)
    {
        $actor = $request->user();

        $roles = Role::with('permissions:id,key')->withCount('users')->orderByDesc('is_system')->orderBy('label')->get()
            ->map(fn (Role $role) => [
                'assignable' => $actor->canAssignRole($role),
                'full' => User::roleLimitReached($role->name) !== null,
                'id' => $role->id,
                'name' => $role->name,
                'label' => $role->label,
                'description' => $role->description,
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

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:50', 'regex:/^[A-Za-z0-9_]+$/', Rule::unique('roles', 'name')],
            'label' => 'required|string|max:100',
            'description' => 'nullable|string|max:255',
            'portal' => 'required|in:admin,syndic',
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,key',
        ]);

        $keys = $validated['permissions'] ?? [];
        if (!$request->user()->canGrant($keys)) {
            return $this->escalationError();
        }

        $role = Role::create([
            'name' => strtoupper($validated['name']),
            'label' => $validated['label'],
            'description' => $validated['description'] ?? null,
            'portal' => $validated['portal'],
        ]);
        $role->permissions()->sync(Permission::whereIn('key', $keys)->pluck('id'));

        return response()->json(['success' => true, 'role' => $role->load('permissions')], 201);
    }

    /**
     * Update a role's label, description, portal and permissions.
     * The role's name (stored on users) cannot change; the super admin role cannot be edited.
     */
    public function update(Request $request, $id)
    {
        $role = Role::findOrFail($id);

        if ($role->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => 'The super admin role always has every permission.'], 422);
        }

        $validated = $request->validate([
            'label' => 'sometimes|required|string|max:100',
            'description' => 'nullable|string|max:255',
            'portal' => 'sometimes|required|in:admin,syndic',
            'permissions' => 'sometimes|array',
            'permissions.*' => 'string|exists:permissions,key',
        ]);

        $actor = $request->user();
        if ($actor->role === $role->name && !$actor->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => 'You cannot edit your own role.'], 403);
        }
        // The actor must hold every permission the role has now and will have after the change
        $keys = $validated['permissions'] ?? $role->permissionKeys();
        if (!$actor->canGrant(array_merge($keys, $role->permissionKeys()))) {
            return $this->escalationError();
        }

        $role->update(collect($validated)->only(['label', 'description', 'portal'])->all());
        if (array_key_exists('permissions', $validated)) {
            $role->permissions()->sync(Permission::whereIn('key', $keys)->pluck('id'));
        }

        return response()->json(['success' => true, 'role' => $role->load('permissions')]);
    }

    public function destroy(Request $request, $id)
    {
        $role = Role::withCount('users')->findOrFail($id);

        if ($role->is_system) {
            return response()->json(['success' => false, 'message' => 'Built-in roles cannot be deleted.'], 422);
        }
        if ($role->users_count > 0) {
            return response()->json(['success' => false, 'message' => "This role is used by {$role->users_count} user(s). Move them to another role first."], 422);
        }
        if (!$request->user()->canGrant($role->permissionKeys())) {
            return $this->escalationError();
        }

        $role->delete();

        return response()->json(['success' => true]);
    }

    protected function escalationError()
    {
        return response()->json([
            'success' => false,
            'message' => 'You can only grant permissions you have yourself.',
        ], 403);
    }
}
