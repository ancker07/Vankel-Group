<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Support\PermissionCatalog;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

/**
 * Clears out all business data so the client can start over, and keeps what the platform needs to run.
 *
 * KEPT:   super admin account(s) with their login tokens, roles, permissions, settings (AI model and key,
 *         mobile access switch), migrations.
 * WIPED:  all other users, syndics, buildings, missions (+ updates, assignments), interventions, documents,
 *         maintenance plans, emails (+ attachments), contacts, notifications, sessions, password resets,
 *         queue and cache, plus the uploaded files that belonged to that data.
 *
 * Emails: the fetcher only imports UNSEEN mailbox messages and marks them seen. Mails that were already
 * imported will NOT come back after the reset; only mails that arrive from now on get imported.
 */
class ResetSystemData extends Command
{
    protected $signature = 'system:reset
        {--keep-directory : Keep syndics and buildings (unlinked from missions) instead of deleting them}
        {--keep-files : Do not delete uploaded files from storage}
        {--admin-email= : After the reset, create the (single) ADMIN account with this email}
        {--admin-name=Admin : Display name of that admin}
        {--admin-password= : Its password (asked hidden when left out, so it stays out of shell history)}
        {--only-account : Delete EVERY user, super admins too; --admin-email becomes the one and only account, as SUPERADMIN}
        {--force : Skip the confirmation prompt}';

    protected $description = 'Delete all business data and every user except the super admin(s), or every user with --only-account';

    /** Business tables, cleared in full. Child tables first (FK checks are off anyway). */
    private const DATA_TABLES = [
        'mission_updates',
        'assignments',
        'documents',
        'notification_logs',
        'notifications',
        'contacts',
        'email_attachments',
        'emails',
        'interventions',
        'maintenance_plans',
        'missions',
    ];

    private const DIRECTORY_TABLES = ['buildings', 'syndics'];

    /** Framework runtime tables: safe to empty, they rebuild themselves. */
    private const RUNTIME_TABLES = [
        'sessions',
        'password_reset_tokens',
        'jobs',
        'job_batches',
        'failed_jobs',
        'cache',
        'cache_locks',
    ];

    /** Upload folders on the public disk (see InterventionController, EmailController, FetchEmails, AuthController). */
    private const UPLOAD_FOLDERS = ['documents', 'photos', 'attachments', 'email_attachments', 'profiles'];

    public function handle(): int
    {
        $onlyAccount = (bool) $this->option('only-account');
        $adminEmail = trim((string) $this->option('admin-email'));
        $newRole = $onlyAccount ? PermissionCatalog::SUPERADMIN : 'ADMIN';

        if ($onlyAccount && $adminEmail === '') {
            $this->error('--only-account deletes every user, so --admin-email is required (otherwise nobody can log in).');

            return self::FAILURE;
        }

        // With --only-account nobody is kept: the new account replaces them all.
        $keep = $onlyAccount ? collect() : User::withTrashed()
            ->where('role', PermissionCatalog::SUPERADMIN)
            ->whereNull('deleted_at')
            ->get(['id', 'name', 'email', 'image_url']);

        if (! $onlyAccount && $keep->isEmpty()) {
            $this->error('No active super admin found. Aborting so nobody gets locked out.');

            return self::FAILURE;
        }

        // Validate the new account BEFORE anything is deleted.
        $adminPassword = null;
        if ($adminEmail !== '') {
            if (! filter_var($adminEmail, FILTER_VALIDATE_EMAIL)) {
                $this->error("Invalid admin email: {$adminEmail}");

                return self::FAILURE;
            }
            if ($keep->contains(fn ($u) => strcasecmp($u->email, $adminEmail) === 0)) {
                $this->error('That email belongs to a super admin that is kept. Use another email.');

                return self::FAILURE;
            }
            $adminPassword = (string) ($this->option('admin-password') ?? $this->secret('Password for '.$adminEmail));
            if (mb_strlen($adminPassword) < 8) {
                $this->error('Admin password must be at least 8 characters.');

                return self::FAILURE;
            }
        }

        $keepDirectory = (bool) $this->option('keep-directory');
        $tables = array_merge(self::DATA_TABLES, $keepDirectory ? [] : self::DIRECTORY_TABLES, self::RUNTIME_TABLES);
        $tables = array_values(array_filter($tables, fn ($t) => Schema::hasTable($t)));

        $this->warn('Database: '.DB::connection()->getDatabaseName().' ('.app()->environment().')');
        if ($onlyAccount) {
            $this->warn('ALL accounts are deleted, super admins included (--only-account).');
        } else {
            $this->line('Super admin(s) kept:');
            foreach ($keep as $u) {
                $this->line("  #{$u->id} {$u->name} <{$u->email}>");
            }
        }
        $this->line('Users deleted: '.User::withTrashed()->whereNotIn('id', $keep->pluck('id'))->count());
        $this->newLine();
        $this->table(['Table to empty', 'Rows'], array_map(fn ($t) => [$t, DB::table($t)->count()], $tables));
        if ($keepDirectory) {
            $this->line('Syndics and buildings are kept (--keep-directory).');
        }
        if ($adminEmail !== '') {
            $this->line("New {$newRole} account created afterwards: {$adminEmail}".($onlyAccount ? ' (the only account)' : ''));
        }
        $this->line($this->option('keep-files') ? 'Uploaded files are kept (--keep-files).' : 'Uploaded files in: '.implode(', ', self::UPLOAD_FOLDERS).' get deleted.');
        $this->newLine();
        $this->warn('This cannot be undone. Take a database backup first.');

        if (! $this->option('force') && $this->ask('Type RESET to continue') !== 'RESET') {
            $this->info('Cancelled. Nothing was changed.');

            return self::SUCCESS;
        }

        $keepIds = $keep->pluck('id')->all();

        // TRUNCATE commits implicitly on MySQL, so this is not one transaction: that's why we ask for a backup.
        Schema::disableForeignKeyConstraints();
        try {
            foreach ($tables as $table) {
                DB::table($table)->truncate();
            }

            if ($keepDirectory) {
                // Their missions/plans are gone; nothing else points at them.
                $this->line('Syndics and buildings kept: '.DB::table('syndics')->count().' / '.DB::table('buildings')->count());
            }

            // Hard delete, soft-deleted users included, so their emails can be registered again.
            DB::table('users')->whereNotIn('id', $keepIds)->delete();

            // Logins of deleted users. The super admin stays logged in.
            DB::table('personal_access_tokens')
                ->where(fn ($q) => $q->where('tokenable_type', '!=', User::class)->orWhereNotIn('tokenable_id', $keepIds))
                ->delete();
        } finally {
            Schema::enableForeignKeyConstraints();
        }

        // The super admin keeps its fixed role with the right permissions.
        PermissionCatalog::sync();
        PermissionCatalog::syncRoles();

        if ($adminEmail !== '') {
            // All other users are gone, so the role limit (1 admin / 2 super admins) holds. Password is hashed by the model cast.
            User::create([
                'name' => (string) $this->option('admin-name') ?: 'Admin',
                'email' => $adminEmail,
                'password' => $adminPassword,
                'role' => $newRole,
                'status' => 'APPROVED',
            ]);
            $this->info("{$newRole} account created: {$adminEmail}");
        }

        if (! $this->option('keep-files')) {
            $this->deleteUploads($keep->pluck('image_url')->filter()->all());
        }

        $this->newLine();
        $this->info('Reset done. Only mails that arrive from now on will be imported.');

        return self::SUCCESS;
    }

    /** @param string[] $keepPaths files that still belong to a kept user (profile pictures) */
    private function deleteUploads(array $keepPaths): void
    {
        $disk = Storage::disk('public');
        $deleted = 0;

        foreach (self::UPLOAD_FOLDERS as $folder) {
            if (! $disk->exists($folder)) {
                continue;
            }
            foreach ($disk->allFiles($folder) as $file) {
                if (in_array($file, $keepPaths, true)) {
                    continue;
                }
                $disk->delete($file);
                $deleted++;
            }
            foreach (array_reverse($disk->allDirectories($folder)) as $dir) {
                if (empty($disk->allFiles($dir))) {
                    $disk->deleteDirectory($dir);
                }
            }
        }

        $this->line("Uploaded files deleted: {$deleted}");
    }
}
