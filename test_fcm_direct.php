<?php
require_once __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';

use App\Services\NotificationService;

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$tokens = [
    'e9OpCPCeR7uFuyJJ3Y3O_H:APA91bFRYyE0TLWDuAS4n13VmLe3Ntfn4Ls9SdRPamppMoEBtbegBeBlFpfiVehNv-pbfVckbHguiLBa8TKDiHW80Wfi2ubesFzPg1k7uTEUmVqve4CStcU',
    'dPO_WudNRkOxF9uCq2sik6:APA91bFkFrJFqaGDKeg1r3xM_NypH_peD50BmnSIdbt81OTx1oMjFm9oR6ql7Y6b5jKlKkSeBLS1YGUpFRyD53AunmAOnxYyNQUa639iI8ynKlpG0YFbFVA'
];

$service = new NotificationService();
foreach ($tokens as $token) {
    echo "Sending to " . substr($token, 0, 15) . "...\n";
    $result = $service->sendNotification($token, 'Direct Test', 'This is a direct test');
    if ($result) {
        echo "SUCCESS\n";
    } else {
        echo "FAILED (Check logs)\n";
    }
}
