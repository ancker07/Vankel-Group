<?php

namespace App\Models;

use App\Support\PermissionCatalog;
use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    protected $guarded = [];

    protected $casts = [
        'is_system' => 'boolean',
    ];

    public function permissions()
    {
        return $this->belongsToMany(Permission::class);
    }

    public function users()
    {
        return $this->hasMany(User::class, 'role', 'name');
    }

    public function isSuperAdmin(): bool
    {
        return $this->name === PermissionCatalog::SUPERADMIN;
    }

    /** Permission keys of this role (all of them for the super admin). */
    public function permissionKeys(): array
    {
        if ($this->isSuperAdmin()) {
            return PermissionCatalog::keys();
        }

        return $this->permissions->pluck('key')->all();
    }
}
