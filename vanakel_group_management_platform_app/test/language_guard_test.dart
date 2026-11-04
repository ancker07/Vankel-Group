import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vanakel_group_management_platform_app/core/error/error_text.dart';
import 'package:vanakel_group_management_platform_app/core/error/exceptions.dart';
import 'package:vanakel_group_management_platform_app/core/utils/app_format.dart';
import 'package:vanakel_group_management_platform_app/core/utils/app_labels.dart';
import 'package:vanakel_group_management_platform_app/core/utils/translation_helper.dart';
import 'package:vanakel_group_management_platform_app/features/intervention/domain/intervention.dart';
import 'package:vanakel_group_management_platform_app/features/mission/domain/mission.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

/// Whatever language is selected, the whole app must follow it. These tests fail when
/// someone adds a screen string, a date or a label that does not.

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Iterable<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'));

void main() {
  group('language files', () {
    final en = _arb('en'), fr = _arb('fr'), nl = _arb('nl');
    Set<String> keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();

    test('English, French and Dutch have exactly the same keys', () {
      expect(keys(fr).difference(keys(en)), isEmpty, reason: 'in fr but not en');
      expect(keys(nl).difference(keys(en)), isEmpty, reason: 'in nl but not en');
      expect(keys(en).difference(keys(fr)), isEmpty, reason: 'missing in fr');
      expect(keys(en).difference(keys(nl)), isEmpty, reason: 'missing in nl');
    });

    test('no translation is empty and placeholders match the English text', () {
      final placeholder = RegExp(r'\{(\w+)\}');
      for (final key in keys(en)) {
        for (final entry in {'fr': fr, 'nl': nl}.entries) {
          final value = entry.value[key] as String;
          expect(value.trim(), isNotEmpty, reason: '${entry.key}.$key is empty');
          final want = placeholder.allMatches(en[key] as String).map((m) => m[1]).toSet();
          final got = placeholder.allMatches(value).map((m) => m[1]).toSet();
          expect(got, want, reason: '${entry.key}.$key placeholders differ from English');
        }
      }
    });

    test('a translation is not just the English text (unless it is the same word in that language)', () {
      // words that really are identical in French / Dutch
      const sameWord = {
        'fr': {'notifications', 'interventions', 'admPermissionsCount', 'admStatInterventions', 'admThreadMessages', 'admContacts'},
        'nl': {'syndicManager', 'mediaAudit', 'admStatEmails', 'admStatSyndics', 'admTeam', 'admMessage', 'admBroadcastBody', 'admRole'},
      };
      for (final entry in {'fr': fr, 'nl': nl}.entries) {
        final untranslated = keys(en)
            .where((k) => (en[k] as String).length > 14)
            .where((k) => en[k] == entry.value[k] && !sameWord[entry.key]!.contains(k))
            .toList();
        expect(untranslated, isEmpty, reason: '${entry.key} still has the English text for: $untranslated');
      }
    });
  });

  group('no text hard-coded in the screens', () {
    // Visible text must come from l10n. Allowed: brand name, e-mail addresses, pure interpolation.
    final slot = RegExp(
      r"(?:Text|SelectableText)\(\s*(?:const\s+)?'((?:[^'\\]|\\.)*)'"
      r"|(?:labelText|hintText|helperText|errorText|tooltip|semanticLabel|title|label|content)\s*:\s*(?:const\s+)?(?:Text\(\s*(?:const\s+)?)?'((?:[^'\\]|\\.)*)'",
    );
    bool allowed(String s) {
      if (!RegExp(r'[A-Za-zÀ-ÿ]{3}').hasMatch(s)) return true; // no real words
      if (s.contains(r'$') && !RegExp(r'[A-Za-z]{4,}\s+[A-Za-z]{3,}').hasMatch(s.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), ''))) return true;
      if (s == 'Vanakel Group' || s.contains('@') || s.startsWith('http')) return true;
      if (RegExp(r'^[\w\-./:#]+$').hasMatch(s) && !s.contains(' ') && s != s.toUpperCase()) return true; // identifiers / ids
      return false;
    }

    test('Text(), labels, hints, tooltips, titles and SnackBars use l10n', () {
      final offenders = <String>[];
      for (final file in _dartFiles()) {
        // PDF labels live in pdf_service.dart (three-language map, covered by its own tests)
        if (file.path.endsWith('core/services/pdf_service.dart') || file.path.endsWith('firebase_options.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith(RegExp(r'(import|//|///)'))) continue;
          if (line.contains('pw.Text')) continue;
          for (final m in slot.allMatches(line)) {
            final text = m[1] ?? m[2] ?? '';
            if (text.isNotEmpty && !allowed(text)) offenders.add('${file.path}:${i + 1}  "$text"');
          }
        }
      }
      expect(offenders, isEmpty, reason: 'Move these to lib/l10n/*.arb (en, fr, nl):\n${offenders.join('\n')}');
    });

    test('dates are never formatted without the selected language', () {
      final offenders = <String>[];
      for (final file in _dartFiles()) {
        if (file.path.endsWith('core/utils/app_format.dart') || file.path.endsWith('core/services/pdf_service.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          // DateFormat('...') / DateFormat.yMMMd() without a locale: English month names
          if (RegExp(r'''DateFormat\s*\(\s*['"][^'"]*['"]\s*\)|DateFormat\.\w+\(\s*\)''').hasMatch(line) ||
              RegExp(r'\$\{[\w!.?]+\.day\}\s*/\s*\$\{').hasMatch(line)) {
            offenders.add('${file.path}:${i + 1}  ${line.trim()}');
          }
        }
      }
      expect(offenders, isEmpty, reason: 'Use AppFormat (core/utils/app_format.dart):\n${offenders.join('\n')}');
    });

    test('raw server values (status.name, urgency...) are not printed in Text()', () {
      final offenders = <String>[];
      final raw = RegExp(r'Text\(\s*[\w.!?]*(?:status|urgency|sector|frequency)\.(?:name|toUpperCase\(\))');
      for (final file in _dartFiles()) {
        if (file.path.endsWith('core/services/pdf_service.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (raw.hasMatch(lines[i])) offenders.add('${file.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
      expect(offenders, isEmpty, reason: 'Use the helpers in core/utils/app_labels.dart:\n${offenders.join('\n')}');
    });
  });

  group('the screens really change with the selected language', () {
    setUpAll(() async => initializeDateFormatting());

    Future<AppLocalizations> pumpIn(WidgetTester tester, String lang, void Function(BuildContext) body) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('nl')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(builder: (context) {
          l10n = AppLocalizations.of(context)!;
          body(context);
          return const SizedBox();
        }),
      ));
      return l10n;
    }

    testWidgets('status, urgency, sector and frequency labels', (tester) async {
      final seen = <String, Set<String>>{};
      for (final lang in ['en', 'fr', 'nl']) {
        final l10n = await pumpIn(tester, lang, (_) {});
        for (final entry in {
          'delayed': l10n.interventionStatusLabel(InterventionStatus.delayed),
          'pending': l10n.interventionStatusLabel(InterventionStatus.pending),
          'mission': l10n.missionStatusLabel(MissionStatus.needsReview),
          'urgent': l10n.urgencyLabel('HIGH'),
          'sector-en': l10n.sectorLabel('PLUMBING'),
          'sector-fr': l10n.sectorLabel('PLOMBERIE'),
          'frequency': l10n.frequencyLabel('MONTHLY'),
          'ingestion': l10n.ingestionStatusLabel('PROCESSED'),
          'account': l10n.accountStatusLabel('PENDING'),
        }.entries) {
          expect(entry.value, isNotEmpty);
          seen.putIfAbsent(entry.key, () => {}).add(entry.value);
        }
        // English and French ids are the same sector
        expect(l10n.sectorLabel('PLUMBING'), l10n.sectorLabel('PLOMBERIE'));
      }
      // each label has three different wordings (one per language), except words shared by languages
      for (final entry in seen.entries) {
        expect(entry.value.length, greaterThanOrEqualTo(2), reason: '${entry.key} does not change with the language: ${entry.value}');
      }
    });

    testWidgets('dates use the month names of the selected language', (tester) async {
      final date = DateTime(2026, 11, 4, 14, 30);
      final out = <String, String>{};
      for (final lang in ['en', 'fr', 'nl']) {
        await pumpIn(tester, lang, (c) => out[lang] = AppFormat.dateLong(c, date));
      }
      expect(out['en'], contains('November'));
      expect(out['fr'], contains('novembre'));
      expect(out['nl'], contains('november'));
      expect(out['fr'], contains('mercredi'));
      expect(out['nl'], contains('woensdag'));
    });

    testWidgets('"time ago" is spoken in the selected language', (tester) async {
      final ago = DateTime.now().subtract(const Duration(minutes: 5));
      final out = <String, String>{};
      for (final lang in ['en', 'fr', 'nl']) {
        await pumpIn(tester, lang, (c) => out[lang] = AppFormat.timeAgo(c, ago));
      }
      expect(out['en'], contains('ago'));
      expect(out['fr'], contains('il y a'));
      expect(out['nl'], contains('geleden'));
    });

    testWidgets('errors, addresses and titles follow the language', (tester) async {
      final out = <String, List<String>>{};
      for (final lang in ['en', 'fr', 'nl']) {
        await pumpIn(tester, lang, (c) {
          out[lang] = [
            errorText(c, NetworkException()),
            errorText(c, ServerException()),
            errorText(c, ValidationException('Le champ email est obligatoire.')),
            TranslationHelper.address(c, ''),
            TranslationHelper.getLocalizedField(
                context: c, enValue: 'Roof leak', frValue: 'Fuite de toiture', nlValue: 'Dakkanaal lek', fallback: 'x'),
            TranslationHelper.getLocalizedField(context: c, fallback: ''),
          ];
        });
      }
      expect(out['en']![0], 'No internet connection');
      expect(out['fr']![0], 'Pas de connexion internet');
      expect(out['nl']![0], 'Geen internetverbinding');
      expect(out['fr']![1], contains('serveur'));
      expect(out['nl']![1], contains('Serverfout'));
      // a message the server wrote is already in the user's language and is shown as it is
      expect(out['nl']![2], 'Le champ email est obligatoire.');
      expect(out['en']![3], 'No address');
      expect(out['fr']![3], 'Aucune adresse');
      expect(out['nl']![3], 'Geen adres');
      expect([out['en']![4], out['fr']![4], out['nl']![4]], ['Roof leak', 'Fuite de toiture', 'Dakkanaal lek']);
      expect(out['fr']![5], 'Sans titre');
    });
  });
}
