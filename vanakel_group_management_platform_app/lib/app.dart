import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';

class VanakelApp extends ConsumerStatefulWidget {
  const VanakelApp({super.key});

  @override
  ConsumerState<VanakelApp> createState() => _VanakelAppState();
}

class _VanakelAppState extends ConsumerState<VanakelApp> {
  @override
  void initState() {
    super.initState();
    NotificationService().onNotificationUpdate = () {
      if (mounted) {
        ref.invalidate(notificationProvider);
        // We also want to fetch immediately after invalidate
        ref.read(notificationProvider.notifier).fetchNotifications();
      }
    };
  }

  @override
  void dispose() {
    NotificationService().onNotificationUpdate = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Vanakel Group',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('nl')],
    );
  }
}
