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

    public function test_technicians_and_admins_can_use_french_and_dutch_dictation(): void
    {
        Http::fake([self::URL => Http::response(['text' => 'ok'])]);

        foreach (['PROFESSIONAL', 'ADMIN'] as $role) {
            Sanctum::actingAs(User::create([
                'name' => $role, 'email' => strtolower($role) . uniqid() . '@test.com', 'password' => 'password123',
                'role' => $role, 'status' => 'APPROVED',
            ]));

            $this->getJson('/api/ai/transcribe/status')->assertOk()->assertExactJson(['available' => true]);
            foreach (['fr', 'nl'] as $language) {
                $this->send($language)->assertOk()->assertExactJson(['text' => 'ok']);
            }
        }
    }

    public function test_older_models_get_a_sentence_in_the_dictation_language(): void
    {
        foreach (['fr' => 'Dictée en français', 'nl' => 'Dictaat in het Nederlands', 'en' => 'Dictation in English'] as $language => $sentence) {
            Http::fakeSequence(self::URL)->push([], 400)->push([], 400)->push(['text' => 'ok']);
            $this->send($language)->assertOk();
            Http::assertSent(fn (ClientRequest $r) => str_contains($r->body(), 'whisper-1')
                && str_contains($r->body(), $sentence)
                && preg_match('/name="language".*?\r\n\r\n' . $language . '\r\n/s', $r->body()));
            $this->app->forgetInstance(\Illuminate\Http\Client\Factory::class);
            Http::clearResolvedInstances();
        }
    }

    public function test_invented_phrases_from_noise_are_dropped(): void
    {
        foreach (['Thank you.', 'Merci.', 'Bedankt voor het kijken!', "Merci d'avoir regardé cette vidéo"] as $invented) {
            Http::fake([self::URL => Http::response(['text' => $invented])]);
            $this->send('fr')->assertOk()->assertExactJson(['text' => '']);
            $this->app->forgetInstance(\Illuminate\Http\Client\Factory::class);
            Http::clearResolvedInstances();
        }
        Http::fake([self::URL => Http::response(['text' => 'Merci de vérifier la fuite au 3e étage.'])]);
        $this->send('fr')->assertOk()->assertExactJson(['text' => 'Merci de vérifier la fuite au 3e étage.']);
    }

    private const RESPONSES = 'https://api.openai.com/v1/responses';

    private function speak(string $spoken, string $appLanguage, ?string $translation = null, int $translationStatus = 200)
    {
        $this->app->forgetInstance(\Illuminate\Http\Client\Factory::class);
        Http::clearResolvedInstances();
        Http::fake([
            self::URL => Http::response(['text' => $spoken]),
            self::RESPONSES => Http::response(['output_text' => json_encode(['text' => $translation ?? ''])], $translationStatus),
        ]);

        return $this->send($appLanguage);
    }

    public function test_whatever_is_spoken_is_written_in_the_selected_language(): void
    {
        // English spoken, app in French
        $this->speak('Hi, we are testing the intervention update status', 'fr', "Bonjour, nous testons le statut de mise à jour de l'intervention")
            ->assertOk()->assertExactJson(['text' => "Bonjour, nous testons le statut de mise à jour de l'intervention"]);
        Http::assertSent(fn (ClientRequest $r) => $r->url() === self::RESPONSES
            && str_contains($r->body(), 'into French') && str_contains($r->body(), 'we are testing'));

        // French spoken, app in Dutch
        $this->speak('Il faut vérifier la chaudière dans la cave pour le propriétaire', 'nl', 'De ketel in de kelder moet gecontroleerd worden voor de eigenaar')
            ->assertOk()->assertExactJson(['text' => 'De ketel in de kelder moet gecontroleerd worden voor de eigenaar']);
        Http::assertSent(fn (ClientRequest $r) => $r->url() === self::RESPONSES && str_contains($r->body(), 'into Dutch'));

        // Dutch spoken, app in English
        $this->speak('De verwarmingsketel lekt en dat moet de eigenaar weten', 'en', 'The boiler is leaking and the owner must know')
            ->assertOk()->assertExactJson(['text' => 'The boiler is leaking and the owner must know']);
        Http::assertSent(fn (ClientRequest $r) => $r->url() === self::RESPONSES && str_contains($r->body(), 'into English'));
    }

    public function test_the_selected_language_is_never_translated(): void
    {
        foreach ([
            'fr' => 'Il faut vérifier la chaudière dans la cave pour le propriétaire',
            'nl' => 'De verwarmingsketel lekt en dat moet de eigenaar weten',
            'en' => 'The boiler is leaking and you have to check it for the owner',
        ] as $language => $spoken) {
            $this->speak($spoken, $language)->assertOk()->assertExactJson(['text' => $spoken]);
            Http::assertSentCount(1); // only the transcription, no translation call
        }
    }

    public function test_if_the_translation_fails_the_spoken_text_is_kept(): void
    {
        $this->speak('Hi, we are testing the intervention update status', 'fr', null, 500)
            ->assertOk()->assertExactJson(['text' => 'Hi, we are testing the intervention update status']);
    }

    public function test_the_selected_language_is_the_first_one_the_model_listens_for(): void
    {
        Http::fake([self::URL => Http::response(['text' => 'ok'])]);
        foreach (['fr', 'nl', 'en'] as $language) {
            $this->send($language)->assertOk();
            Http::assertSent(function (ClientRequest $r) use ($language) {
                preg_match_all('/name="languages\[\]".*?\r\n\r\n(\w+)\r\n/s', $r->body(), $m);

                return ($m[1][0] ?? null) === $language && count($m[1]) === 3 && count(array_unique($m[1])) === 3;
            });
        }
    }

    public function test_a_correct_answer_is_not_retried(): void
    {
        Http::fake([self::URL => Http::response(['text' => 'De verwarmingsketel lekt en dat moet de eigenaar weten'])]);
        $this->send('nl')->assertOk();
        Http::assertSentCount(1);
    }
}
