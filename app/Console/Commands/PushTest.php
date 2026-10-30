<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class PushTest extends Command
{
    protected $signature = 'push:test {email : Email of the user to test}';

    protected $description = 'Diagnose push notifications for a user and send them a test push';

    public function handle(NotificationService $push): int
    {
        $user = User::where('email', $this->argument('email'))->first();
        if (!$user) {
            $this->error('No user with that email.');
            return self::FAILURE;
        }

        $this->line("User: {$user->email} (role {$user->role}, status {$user->status})");
        $this->line('Can view missions (gets new-mission pushes): ' . ($user->hasPermission('missions.view') ? 'yes' : 'NO'));

        $keyFile = file_exists(base_path('public/vanakelgroup.json')) ? 'public/vanakelgroup.json'
            : (file_exists(base_path('public/vankelgroup.json')) ? 'public/vankelgroup.json' : null);
        $this->line('Firebase service-account file: ' . ($keyFile ?? 'MISSING'));

        if (!$user->fcm_token) {
            $this->error('This user has NO fcm_token saved. The phone never registered (log in on the phone first, then re-run).');
            return self::FAILURE;
        }

        $this->line('Saved token: ' . substr($user->fcm_token, 0, 20) . '...');

        $ok = $push->sendNotification($user->fcm_token, 'Push test', 'If you see this, push works.', [], true);

        if ($ok) {
            $this->info('FCM accepted the message. If the phone shows nothing, check Android notification permission / battery restrictions.');
            return self::SUCCESS;
        }

        $this->error('FCM rejected the message. See the "FCM API Error" line in storage/logs/laravel.log.');
        return self::FAILURE;
    }
}
