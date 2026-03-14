<?php
require __DIR__ . '/vendor/autoload.php';

use App\Services\NotificationService;
use Illuminate\Support\Facades\Log;

// Mock Log for terminal output
class MockLog {
    public static function error($msg) { echo "ERROR: $msg\n"; }
    public static function info($msg) { echo "INFO: $msg\n"; }
}

// We need a minimal Laravel environment or just simulate the service
$service = new class extends NotificationService {
    public function testToken() {
        return $this->getAccessToken();
    }
};

$token = $service->testToken();
if ($token) {
    echo "Access Token retrieved successfully!\n";
} else {
    echo "Failed to retrieve Access Token.\n";
}
