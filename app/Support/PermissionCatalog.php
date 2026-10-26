<?php

namespace App\Support;

use App\Models\Permission;

/**
 * Every permission the code checks. Roles are created freely in the UI,
 * but permissions are fixed here because each one is enforced in routes/code.
 * Run `php artisan permissions:sync` after adding a new one.
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
            'roles.manage' => 'Manage roles and permissions',
        ],
        'System' => [
            'stats.view' => 'View system statistics',
            'notifications.broadcast' => 'Send push notifications',
            'settings.ai' => 'Manage AI settings',
            'ai.use' => 'Use the AI writing assistant',
        ],
    ];

    /** Built-in roles: name => [label, portal, permissions] ('*' = all). */
    public const DEFAULT_ROLES = [
        'SUPERADMIN' => ['Super admin', 'admin', ['*']],
        'ADMIN' => ['Admin', 'admin', [
            'missions.view', 'missions.create', 'missions.update', 'missions.approve',
            'interventions.view', 'interventions.create', 'interventions.update', 'interventions.send_report',
            'interventions.reopen', 'maintenance.view', 'maintenance.manage', 'buildings.view', 'reports.view',
            'emails.view', 'emails.manage', 'contacts.view', 'contacts.manage',
            'team.view', 'location.share', 'users.view', 'users.update', 'ai.use',
        ]],
        'PROFESSIONAL' => ['Technician', 'admin', [
            'missions.view', 'interventions.view', 'interventions.update',
            'maintenance.view', 'buildings.view', 'location.share', 'ai.use',
        ]],
        'SYNDIC' => ['Syndic', 'syndic', [
            'missions.view', 'missions.create', 'missions.update',
            'interventions.view', 'maintenance.view', 'buildings.view',
        ]],
    ];

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
}
