import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/shared/widgets/dictation_button.dart';

void main() {
  test('prefers the Belgian variant when the phone has it', () {
    expect(DictationButton.chooseLocale(['en_US', 'fr_FR', 'fr_BE', 'nl_NL'], 'fr'), 'fr_BE');
    expect(DictationButton.chooseLocale(['nl_NL', 'nl_BE'], 'nl'), 'nl_BE');
  });

  test('falls back to another variant of the same language instead of failing', () {
    expect(DictationButton.chooseLocale(['en_US', 'fr_FR', 'nl_NL'], 'nl'), 'nl_NL');
    expect(DictationButton.chooseLocale(['fr_CA'], 'fr'), 'fr_CA');
  });

  test('understands both en-GB and en_GB style ids (Android vs iOS)', () {
    expect(DictationButton.chooseLocale(['en-US', 'en-GB'], 'en'), 'en-GB');
  });

  test('returns null (phone default) when the language is not installed', () {
    expect(DictationButton.chooseLocale(['en_US'], 'nl'), isNull);
    expect(DictationButton.chooseLocale([], 'fr'), isNull);
    expect(DictationButton.chooseLocale(['fr_FR'], 'de'), isNull);
  });

  test('a phone without French / Dutch speech is reported, not silently recognised in another language', () {
    expect(DictationButton.languageMissing(['en_US', 'en_GB'], 'fr'), isTrue);
    expect(DictationButton.languageMissing(['en_US', 'fr_FR'], 'nl'), isTrue);
    expect(DictationButton.languageMissing(['en_US', 'fr_FR'], 'fr'), isFalse);
    expect(DictationButton.languageMissing(const [], 'nl'), isFalse); // list unknown: let the phone choose
    expect(DictationButton.languageMissing(['fr_FR'], 'en'), isFalse); // English is never blocked
  });
}
