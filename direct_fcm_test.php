<?php
// Include the Laravel bootstrap environment
require_once __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';

use App\Services\NotificationService;
use Illuminate\Support\Facades\Log;

// Use the application kernel to handle the request environment
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$token = 'eT2TfRtfThSsa10f6aHqK2:APA91bGQkXUAMKQ4yjKSx89n2A4Dn6ozA6zL-TLkJhZBj2YSz7R3EylhpNQrKDcfLlkFTJZBY_wjFwHhcZizpZQOooKPTajknhwIXFcTycXLXoZ0xLKu5r4';
$title = 'Test Notification';
$body = 'This is a test notification sent directly from the server.';

echo "Attempting to send notification to token: " . substr($token, 0, 20) . "...\n";

$service = new NotificationService();
$result = $service->sendNotification($token, $title, $body);

if ($result) {
    echo "SUCCESS: Notification sent successfully!\n";
} else {
    echo "FAILURE: Failed to send notification. Check storage/logs/laravel.log for details.\n";
}
