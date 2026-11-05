<?php

namespace Tests\Feature;

use App\Models\Setting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as ClientRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TranscriptionTest extends TestCase
{
    use RefreshDatabase;

    private const URL = 'https://api.openai.com/v1/audio/transcriptions';

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::create([
            'name' => 'Super', 'email' => 'super' . uniqid() . '@test.com', 'password' => 'password123',
            'role' => 'SUPERADMIN', 'status' => 'APPROVED',
        ]));
        Setting::updateOrCreate(['key' => 'ai_api_key'], ['value' => 'sk-secret-test']);
    }

    private function wav(): UploadedFile
    {
        $pcm = str_repeat("\0\0", 1600);
        $header = 'RIFF' . pack('V', 36 + strlen($pcm)) . 'WAVEfmt ' . pack('VvvVVvv', 16, 1, 1, 16000, 32000, 2, 16) . 'data' . pack('V', strlen($pcm));

        return $this->realUpload('speech.wav', $header . $pcm);
    }

    /** A real file, so the type is detected from its content as in production. */
    private function realUpload(string $name, string $content): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'upl');
        file_put_contents($path, $content);

        return new UploadedFile($path, $name, null, null, true);
    }

    private function send(string $language = 'fr', ?UploadedFile $file = null)
    {
        return $this->post('/api/ai/transcribe', ['audio' => $file ?? $this->wav(), 'language' => $language], ['Accept' => 'application/json']);
    }

    public function test_sends_language_and_model_and_returns_text(): void
    {
        $spokenNow = '';
        Http::fake([self::URL => function () use (&$spokenNow) {
            return Http::response(['text' => " $spokenNow "]);
        }]);
        foreach (['fr' => 'bonjour', 'nl' => 'goedendag', 'en' => 'hello'] as $language => $spoken) {
            $spokenNow = $spoken;
            $this->send($language)->assertOk()->assertExactJson(['text' => $spoken]);
            Http::assertSent(fn (ClientRequest $r) => str_contains($r->body(), 'gpt-transcribe')
                && str_contains($r->body(), 'name="languages[]"')
                && preg_match('/name="languages\[\]".*?\r\n\r\n' . $language . '\r\n/s', $r->body())
                && str_contains($r->body(), 'filename="speech.wav"')
                && $r->hasHeader('Authorization', 'Bearer sk-secret-test'));
        }
    }

    public function test_key_is_never_returned(): void
    {
        Http::fake([self::URL => Http::response(['error' => ['message' => 'bad key sk-secret-test']], 401)]);
        $response = $this->send();
        $response->assertStatus(503);
        $this->assertStringNotContainsString('sk-secret-test', $response->getContent());
        $this->assertStringNotContainsString('sk-secret-test', $this->getJson('/api/ai/transcribe/status')->getContent());
    }

    public function test_upstream_failures_map_to_what_the_apps_should_do(): void
    {
        foreach ([429 => 502, 500 => 502, 400 => 422, 404 => 503] as $upstream => $expected) {
            $status = $upstream;
            Http::fake([self::URL => fn () => Http::response(['error' => []], $status)]);
            $this->send()->assertStatus($expected);
            $this->app->forgetInstance(\Illuminate\Http\Client\Factory::class);
            \Illuminate\Support\Facades\Http::clearResolvedInstances();
        }
    }

    public function test_falls_back_to_older_models_with_their_parameters(): void
    {
        Http::fakeSequence(self::URL)
            ->push(['error' => []], 400)->push(['error' => []], 500)->push(['text' => 'la fuite']);
        $this->send()->assertOk()->assertExactJson(['text' => 'la fuite']);
        Http::assertSentCount(3);
        Http::assertSent(fn (ClientRequest $r) => str_contains($r->body(), 'whisper-1')
            && str_contains($r->body(), 'name="language"') && !str_contains($r->body(), 'languages[]'));
    }

    public function test_a_bad_key_does_not_try_every_model(): void
    {
        Http::fake([self::URL => Http::response(['error' => []], 401)]);
        $this->send()->assertStatus(503);
        Http::assertSentCount(1);
    }

    public function test_missing_key_reports_unavailable(): void
    {
        Setting::where('key', 'ai_api_key')->delete();
        config(['app.env' => 'testing']);
        putenv('OPENAI_API_KEY');
        $this->getJson('/api/ai/transcribe/status')->assertOk()->assertExactJson(['available' => false]);
        $this->send()->assertStatus(503);
    }

    public function test_rejects_other_files_and_languages(): void
    {
        Http::fake();
        $this->send('de')->assertStatus(422);
        $this->send('fr', $this->realUpload('a.wav', '<?php echo 1;'))->assertStatus(422);
        Http::assertNothingSent();
    }

    public function test_error_message_follows_language(): void
    {
        Http::fake([self::URL => Http::response([], 500)]);
        $this->post('/api/ai/transcribe', ['audio' => $this->wav(), 'language' => 'nl'], ['Accept' => 'application/json', 'Accept-Language' => 'nl'])
            ->assertStatus(502)->assertJsonPath('error', 'Spraaktranscriptie is mislukt.');
    }
}
