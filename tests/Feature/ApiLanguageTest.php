<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Whatever language the user selected, the API answers in it: validation errors and every
 * message the server writes. The two "guard" tests fail when a new message is added without
 * its French and Dutch text, so the problem cannot come back unnoticed.
 */
class ApiLanguageTest extends TestCase
{
    use RefreshDatabase;

    private function login(string $role = 'SUPERADMIN', ?string $locale = null): User
    {
        $user = User::create([
            'name' => $role, 'email' => strtolower($role) . uniqid() . '@test.com', 'password' => 'password123',
            'role' => $role, 'status' => 'APPROVED', 'locale' => $locale,
        ]);
        Sanctum::actingAs($user);

        return $user;
    }

    private function validationMessage(array $headers = []): string
    {
        // email is missing: the same field error in every language
        return $this->postJson('/api/users', ['firstName' => 'A', 'lastName' => 'B', 'password' => 'password123', 'role' => 'SYNDIC'], $headers)
            ->assertStatus(422)
            ->json('errors.email.0');
    }

    public function test_validation_errors_follow_the_accept_language_header(): void
    {
        $this->login();

        $this->assertSame("Le champ adresse e-mail est obligatoire.", $this->validationMessage(['Accept-Language' => 'fr']));
        $this->assertSame("Het veld e-mailadres is verplicht.", $this->validationMessage(['Accept-Language' => 'nl']));
        $this->assertStringContainsString('is required', $this->validationMessage(['Accept-Language' => 'en']));
        // a regional variant sent by a browser
        $this->assertStringContainsString('obligatoire', $this->validationMessage(['Accept-Language' => 'fr-BE,fr;q=0.9']));
    }

    public function test_without_a_header_the_users_saved_language_is_used(): void
    {
        $this->login('SUPERADMIN', 'nl');
        // (an empty header: the test client would otherwise add a default "en-us" one)
        $this->assertStringContainsString('verplicht', $this->validationMessage(['Accept-Language' => '']));
    }

    public function test_the_header_wins_over_the_saved_language_and_unknown_languages_fall_back(): void
    {
        $this->login('SUPERADMIN', 'nl');
        // the app is showing French right now, even if the account still says Dutch
        $this->assertStringContainsString('obligatoire', $this->validationMessage(['Accept-Language' => 'fr']));
        // a language we do not have: the saved one, then the default
        $this->assertStringContainsString('verplicht', $this->validationMessage(['Accept-Language' => 'de']));
    }

    public function test_messages_written_by_the_server_are_translated(): void
    {
        $this->login();
        $mission = Mission::create(['requested_by' => 'SYNDIC', 'title' => 'T', 'description' => 'D', 'status' => 'PENDING']);

        $this->postJson("/api/missions/{$mission->id}/reject", [], ['Accept-Language' => 'fr'])
            ->assertOk()->assertJsonPath('message', 'Mission refusée avec succès');
        $this->postJson("/api/missions/{$mission->id}/reject", [], ['Accept-Language' => 'nl'])
            ->assertOk()->assertJsonPath('message', 'Missie succesvol afgewezen');
        $this->postJson("/api/missions/{$mission->id}/reject", [], ['Accept-Language' => 'en'])
            ->assertOk()->assertJsonPath('message', 'Mission rejected successfully');
    }

    public function test_permission_and_login_errors_are_translated(): void
    {
        $this->login('PROFESSIONAL');

        $this->postJson('/api/users', [], ['Accept-Language' => 'nl'])
            ->assertForbidden()->assertJsonPath('message', 'U mag deze actie niet uitvoeren.');
        $this->postJson('/api/users', [], ['Accept-Language' => 'fr'])
            ->assertForbidden()->assertJsonPath('message', "Vous n'êtes pas autorisé à effectuer cette action.");
    }

    public function test_messages_with_values_keep_their_values(): void
    {
        $this->login();
        $role = \App\Models\Role::where('is_system', false)->first()
            ?? \App\Models\Role::create(['name' => 'CUSTOM_X', 'label' => 'Custom', 'portal' => 'admin', 'is_system' => false]);
        User::create(['name' => 'u', 'email' => 'u' . uniqid() . '@t.com', 'password' => 'password123', 'role' => $role->name, 'status' => 'APPROVED']);

        $this->deleteJson("/api/roles/{$role->id}", [], ['Accept-Language' => 'fr'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Ce rôle est utilisé par 1 utilisateur(s). Déplacez-les d\'abord vers un autre rôle.');
    }

    // ---------------------------------------------------------------- guards

    /** @return string[] every message key passed to __() in the application code */
    private function translatableKeys(): array
    {
        $keys = [];
        $files = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator(app_path()));
        foreach ($files as $file) {
            if ($file->getExtension() !== 'php') {
                continue;
            }
            if (preg_match_all("/__\('((?:[^'\\\\]|\\\\.)*)'/", file_get_contents($file->getPathname()), $m)) {
                foreach ($m[1] as $key) {
                    $keys[] = str_replace("\\'", "'", $key);
                }
            }
        }
        foreach (\App\Support\PermissionCatalog::ROLE_LIMITS as [$max, $message]) {
            $keys[] = $message;
        }

        return array_values(array_unique($keys));
    }

    public function test_every_server_message_has_a_french_and_a_dutch_translation(): void
    {
        $fr = json_decode(file_get_contents(lang_path('fr.json')), true);
        $nl = json_decode(file_get_contents(lang_path('nl.json')), true);
        $placeholders = fn (string $s) => (function () use ($s) { preg_match_all('/:[a-z_]+/', $s, $m); sort($m[0]); return $m[0]; })();

        $this->assertNotEmpty($this->translatableKeys());
        foreach ($this->translatableKeys() as $key) {
            foreach (['fr' => $fr, 'nl' => $nl] as $lang => $dictionary) {
                $this->assertArrayHasKey($key, $dictionary, "Missing {$lang} translation for: {$key}");
                $this->assertNotSame('', trim($dictionary[$key]), "Empty {$lang} translation for: {$key}");
                $this->assertSame($placeholders($key), $placeholders($dictionary[$key]), "{$lang}: placeholders differ for: {$key}");
            }
        }
        // and nothing stale left behind
        $keys = $this->translatableKeys();
        foreach (array_merge(array_keys($fr), array_keys($nl)) as $key) {
            $this->assertContains($key, $keys, "Unused translation (remove it or use it): {$key}");
        }
    }

    public function test_no_user_facing_message_is_left_untranslated_in_the_code(): void
    {
        $offenders = [];
        $files = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator(app_path()));
        foreach ($files as $file) {
            if ($file->getExtension() !== 'php' || str_ends_with($file->getPathname(), 'NotificationService.php')) {
                continue;
            }
            foreach (file($file->getPathname()) as $n => $line) {
                // 'message' => 'English sentence'  (not a validation rule, not already __())
                if (preg_match("/'(message|error)' => ['\"][A-Za-z][^'\"|]*['\"]/", $line)) {
                    $offenders[] = basename($file->getPathname()) . ':' . ($n + 1) . '  ' . trim($line);
                }
            }
        }
        $this->assertSame([], $offenders, "Wrap these messages in __() and add them to lang/fr.json and lang/nl.json:\n" . implode("\n", $offenders));
    }

    public function test_validation_files_cover_every_framework_rule_in_both_languages(): void
    {
        $en = require base_path('vendor/laravel/framework/src/Illuminate/Translation/lang/en/validation.php');
        foreach (['fr', 'nl'] as $lang) {
            $file = require lang_path("{$lang}/validation.php");
            foreach (array_keys($en) as $rule) {
                if (in_array($rule, ['custom', 'attributes'], true)) {
                    continue;
                }
                $this->assertArrayHasKey($rule, $file, "{$lang}/validation.php lacks the '{$rule}' rule");
            }
            foreach (['email', 'password', 'phone', 'files.*', 'photos.*', 'image'] as $attribute) {
                $this->assertArrayHasKey($attribute, $file['attributes'], "{$lang}: no readable name for the field '{$attribute}'");
            }
        }
    }
}
