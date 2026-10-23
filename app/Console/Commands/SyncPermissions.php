<?php

namespace App\Console\Commands;

use App\Support\PermissionCatalog;
use Illuminate\Console\Command;

class SyncPermissions extends Command
{
    protected $signature = 'permissions:sync';

    protected $description = 'Create / update the permissions defined in PermissionCatalog';

    public function handle(): int
    {
        PermissionCatalog::sync();
        $this->info(count(PermissionCatalog::keys()) . ' permissions synced.');

        return self::SUCCESS;
    }
}
