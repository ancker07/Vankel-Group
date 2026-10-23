<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;
use App\Support\PermissionCatalog;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone',
        'company_name',
        'status',
        'bio',
        'image_url',
        'fcm_token',
        'latitude',
        'longitude',
        'location_updated_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'latitude' => 'float',
            'longitude' => 'float',
            'location_updated_at' => 'datetime',
        ];
    }

    /** The role record matching users.role (roles.name). */
    public function roleModel()
    {
        return $this->belongsTo(Role::class, 'role', 'name');
    }

    public function isSuperAdmin(): bool
    {
        return $this->role === PermissionCatalog::SUPERADMIN;
    }

    /** Client users (syndics) only see their own data and use the syndic app. */
    public function isClient(): bool
    {
        return ($this->roleModel?->portal ?? ($this->role === 'SYNDIC' ? 'syndic' : 'admin')) === 'syndic';
    }

    public function portal(): string
    {
        return $this->isClient() ? 'syndic' : 'admin';
    }

    public function permissionKeys(): array
    {
        if ($this->isSuperAdmin()) {
            return PermissionCatalog::keys();
        }

        return $this->roleModel?->permissionKeys() ?? [];
    }

    public function hasPermission(string ...$keys): bool
    {
        return $this->isSuperAdmin() || count(array_intersect($keys, $this->permissionKeys())) > 0;
    }

    /**
     * Prevent privilege escalation: a user may only give a role (to someone,
     * or by editing it) whose permissions they hold themselves.
     */
    public function canGrant(array $permissionKeys): bool
    {
        return $this->isSuperAdmin() || empty(array_diff($permissionKeys, $this->permissionKeys()));
    }

    public function canAssignRole(Role $role): bool
    {
        if ($role->isSuperAdmin()) {
            return $this->isSuperAdmin();
        }

        return $this->canGrant($role->permissionKeys());
    }

    /** Users whose role grants a permission (super admins always included). */
    public function scopeWithPermission($query, string $key)
    {
        $roles = Role::whereHas('permissions', fn ($q) => $q->where('key', $key))->pluck('name')
            ->push(PermissionCatalog::SUPERADMIN);

        return $query->whereIn('role', $roles);
    }

    /** Staff users (everyone who is not a client / syndic). */
    public function scopeStaff($query)
    {
        $clientRoles = Role::where('portal', 'syndic')->pluck('name')->push('SYNDIC')->unique();

        return $query->whereNotIn('role', $clientRoles);
    }

    /** Public shape of the logged-in user, with what the apps need for access control. */
    public function toAuthArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'role_label' => $this->roleModel?->label ?? $this->role,
            'portal' => $this->portal(),
            'status' => $this->status,
            'company_name' => $this->company_name,
            'permissions' => $this->permissionKeys(),
        ];
    }
}
