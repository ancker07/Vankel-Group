import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/notifications/domain/entities/notification_item.dart';
import 'package:vanakel_group_management_platform_app/features/notifications/presentation/notifications_screen.dart';
import 'package:vanakel_group_management_platform_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:vanakel_group_management_platform_app/l10n/app_localizations.dart';

/// The notifications screen must never overflow ("RenderFlex overflowed by N pixels"), whatever the
/// language, the length of the text, the screen width or the phone's font size.
class _Notifier extends NotificationNotifier {
  final AsyncValue<List<NotificationItem>> value;
  _Notifier(this.value);
  @override
  AsyncValue<List<NotificationItem>> build() => value;
  @override
  Future<void> fetchNotifications() async {}
}

NotificationItem _item(int id, String title, String body, {bool read = false}) => NotificationItem(
      id: id, title: title, titleEn: title, titleFr: title, titleNl: title,
      body: body, bodyEn: body, bodyFr: body, bodyNl: body,
      type: id.isEven ? 'mission' : 'intervention', isRead: read,
      createdAt: DateTime.now().subtract(Duration(days: id * 40)),
    );

final _long = [
  _item(1, 'Nouvelle intervention assignée : Vérification des évacuations de toiture au-dessus du 8e étage - ACP GREENWOOD II - BLOC D-E1',
      'Une nouvelle intervention vous a été assignée. Veuillez consulter les détails dans l\'application dès que possible.'),
  _item(2, 'Nieuwe opdracht toegewezen: Controle van de dakafvoeren boven de 8e verdieping - ACP GREENWOOD II - BLOK D-E1',
      'Er is een nieuwe interventie aan u toegewezen. Bekijk de details zo snel mogelijk in de applicatie.', read: true),
  _item(3, 'Supercalifragilisticexpialidocious_AverylongwordwithoutanyspacesthatcannotbreakNormally_1234567890', 'ok'),
  _item(4, 'Short', 'x' * 400),
];

Future<void> _show(WidgetTester tester, AsyncValue<List<NotificationItem>> value,
    {required Size size, double textScale = 1.0, String locale = 'fr'}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [notificationProvider.overrideWith(() => _Notifier(value))],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const NotificationsScreen(),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  for (final size in const [Size(320, 640), Size(360, 740), Size(411, 891)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (final locale in const ['fr', 'nl', 'en']) {
        testWidgets('list: ${size.width.toInt()}px wide, font x$scale, $locale: no overflow', (tester) async {
          await _show(tester, AsyncValue.data(_long), size: size, textScale: scale, locale: locale);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('long error message does not overflow and can be retried', (tester) async {
    await _show(tester, AsyncValue.error(Exception('Connection failed: ' * 20), StackTrace.empty),
        size: const Size(320, 640), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state does not overflow on a tiny, large-font screen', (tester) async {
    await _show(tester, const AsyncValue.data([]), size: const Size(320, 480), textScale: 2.0, locale: 'nl');
    expect(tester.takeException(), isNull);
  });
}
