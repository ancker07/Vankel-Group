<?php
require_once __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';

use App\Services\NotificationService;

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$token = 'dPO_WudNRkOxF9uCq2sik6:APA91bFkFrJFqaGDKeg1r3xM_NypH_peD50BmnSIdbt81OTx1oMjFm9oR6ql7Y6b5jKlKkSeBLS1YGUpFRyD53AunmAOnxYyNQUa639iI8ynKlpG0YFbFVA';

$service = new NotificationService();
echo "Sending to user-provided token: " . substr($token, 0, 15) . "...\n";
$result = $service->sendNotification($token, 'UNIQUE_TOKEN_TEST_123', 'Testing from script');

if ($result) {
    echo "SUCCESS\n";
} else {
    echo "FAILED\n";
}
