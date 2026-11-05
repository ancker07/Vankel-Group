<?php

namespace App\Support;

use App\Models\Permission;
use App\Models\Role;
use App\Models\User;

/**
 * Every permission the code checks, and the three fixed roles that hold them.
 *
 *   SUPERADMIN    platform operator: everything, and the only one who manages admins / super admins
 *   ADMIN         the system owner: every permission except ADMIN_EXCLUDED (AI settings, push notifications, contacts, maintenance), manages the technicians
 *   PROFESSIONAL  the technician: works on the interventions assigned to them
 *
 * Roles cannot be created, edited or deleted: what each role may do is defined HERE (one place,
 * in code), so it can never drift in the database. Run `php artisan permissions:sync` after a change.
 */
class PermissionCatalog
{
    public const SUPERADMIN = 'SUPERADMIN';

    /** Roles with a maximum number of users: two super admins (Bilal, Zain), one admin for the owner. */
    public const ROLE_LIMITS = [
        'SUPERADMIN' => [2, 'There can only be two super admins.'],
        'ADMIN' => [1, 'There can only be one admin.'],
    ];

    /** group => [key => label] */
    public const PERMISSIONS = [
        'Missions' => [
            'missions.view' => 'View missions',
            'missions.create' => 'Create missions (requests)',
            'missions.update' => 'Edit missions',
            'missions.approve' => 'Approve / reject missions',
        ],
        'Interventions' => [
            'interventions.view' => 'View interventions',
            'interventions.create' => 'Create interventions',
            'interventions.update' => 'Edit interventions and assign workers',
            'interventions.reopen' => 'Change a completed intervention (edit or reopen it)',
            'interventions.send_report' => 'Send intervention reports',
        ],
        'Maintenance' => [
            'maintenance.view' => 'View maintenance plans',
            'maintenance.manage' => 'Create / edit / delete maintenance plans',
        ],
        'Buildings' => [
            'buildings.view' => 'View buildings and syndic companies',
        ],
        'Reports' => [
            'reports.view' => 'View reports',
        ],
        'Emails' => [
            'emails.view' => 'View the inbox',
            'emails.manage' => 'Sync, import, reply to and delete emails',
        ],
        'Contacts' => [
            'contacts.view' => 'View website contact requests',
            'contacts.manage' => 'Delete website contact requests',
        ],
        'Team' => [
            'team.view' => 'View the team and their locations',
            'location.share' => 'Share own location (mobile app)',
        ],
        'Users' => [
            'users.view' => 'View users',
            'users.create' => 'Create users',
            'users.update' => 'Approve / reject users, change their role and reset their password',
        ],
        'System' => [
            'stats.view' => 'View system statistics',
            'notifications.broadcast' => 'Send push notifications',
            'settings.ai' => 'Manage AI settings',
            'ai.use' => 'Use the AI writing assistant',
        ],
    ];

    /**
     * Permissions the admin does NOT get (the admin otherwise holds everything): AI settings, push
     * notifications, website contacts and maintenance plans are for the super admin only.
     */
    public const ADMIN_EXCLUDED = [
        'settings.ai', 'notifications.broadcast',
        'contacts.view', 'contacts.manage',
        'maintenance.view', 'maintenance.manage',
    ];

    /** The only roles that exist for staff. */
    public const FIXED_ROLES = ['SUPERADMIN', 'ADMIN', 'PROFESSIONAL'];

    /** Built-in roles: name => [label, portal, permissions] ('*' = all). SYNDIC is a legacy client role: kept for old accounts, never offered. */
    public const DEFAULT_ROLES = [
        'SUPERADMIN' => ['Super admin', 'admin', ['*']],
        // The owner of the system: full control (users, AI, broadcasts, statistics, every mission and intervention)
        'ADMIN' => ['Admin', 'admin', ['*']],
        // A technician works on interventions that are assigned to them. Missions (requests still to be
        // approved / dispatched), users, e-mails and reports are for the admin.
        'PROFESSIONAL' => ['Technician', 'admin', [
            'interventions.view', 'interventions.update',
            'maintenance.view', 'buildings.view', 'location.share', 'ai.use',
        ]],
        'SYNDIC' => ['Syndic', 'syndic', [
            'missions.view', 'missions.create', 'missions.update',
            'interventions.view', 'maintenance.view', 'buildings.view',
        ]],
    ];

    public const ROLE_DESCRIPTIONS = [
        'SUPERADMIN' => 'Platform operator: full access, and the only one who can create or manage admins and super admins.',
        'ADMIN' => 'System owner: full control of missions, interventions, team, e-mails, reports, settings and the technicians.',
        'PROFESSIONAL' => 'Technician: works on the interventions assigned to them and sends them to the admin for review.',
    ];

    public static function isFixed(?string $role): bool
    {
        return in_array($role, self::FIXED_ROLES, true);
    }

    /** What a role may do. Fixed roles come from the code above; anything else (legacy) from the database. */
    public static function permissionsFor(string $role): array
    {
        $keys = self::DEFAULT_ROLES[$role][2] ?? null;
        if ($keys === null || !self::isFixed($role)) {
            return [];
        }

        if ($keys === ['*']) {
            return $role === 'ADMIN' ? array_values(array_diff(self::keys(), self::ADMIN_EXCLUDED)) : self::keys();
        }

        return array_values(array_intersect($keys, self::keys()));
    }

    public static function keys(): array
    {
        return array_merge(...array_map('array_keys', array_values(self::PERMISSIONS)));
    }

    /** Create missing permissions and remove ones no longer in the catalog. */
    public static function sync(): void
    {
        foreach (self::PERMISSIONS as $group => $permissions) {
            foreach ($permissions as $key => $label) {
                Permission::updateOrCreate(['key' => $key], ['label' => $label, 'group' => $group]);
            }
        }
        Permission::whereNotIn('key', self::keys())->delete();
    }

    /**
     * Make the database match the three fixed roles (idempotent): labels, the permission list of each
     * role, and no custom roles. Users of a removed custom role become technicians (least access).
     */
    public static function syncRoles(): void
    {
        foreach (self::FIXED_ROLES as $name) {
            [$label, $portal] = self::DEFAULT_ROLES[$name];
            $role = Role::updateOrCreate(
                ['name' => $name],
                ['label' => $label, 'description' => self::ROLE_DESCRIPTIONS[$name], 'portal' => $portal, 'is_system' => true]
            );
            $role->permissions()->sync(Permission::whereIn('key', self::permissionsFor($name))->pluck('id'));
        }

        // custom roles no longer exist (the legacy SYNDIC client role is kept for old accounts)
        $custom = Role::whereNotIn('name', array_merge(self::FIXED_ROLES, ['SYNDIC']))->pluck('name');
        if ($custom->isNotEmpty()) {
            User::whereIn('role', $custom)->update(['role' => 'PROFESSIONAL']);
            Role::whereIn('name', $custom)->delete();
        }
    }
}
