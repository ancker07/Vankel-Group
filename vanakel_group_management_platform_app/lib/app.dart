import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'core/utils/notification_navigator.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';

class VanakelApp extends ConsumerStatefulWidget {
  const VanakelApp({super.key});

  @override
  ConsumerState<VanakelApp> createState() => _VanakelAppState();
}

class _VanakelAppState extends ConsumerState<VanakelApp> with WidgetsBindingObserver {
  /// One shared instance: the shell banner shows its state and lets the user fix problems.
  LocationService get _locationService => ref.read(locationServiceProvider);

  /// Only users whose role has the location.share permission share their location.
  bool _shouldTrack(AuthState auth) =>
      auth.status == AuthStatus.authenticated && (auth.user?.can('location.share') ?? false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back on screen (also when returning from the phone's Settings after the user fixed GPS or
    // the permission): check again and (re)start sharing. Never started from the background:
    // Android 12+ forbids starting a foreground service there.
    if (state == AppLifecycleState.resumed && _shouldTrack(ref.read(authStateProvider))) {
      _locationService.start();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Texts the OS shows (not Flutter widgets) must follow the language too
    ref.listenManual<Locale>(localeProvider, (previous, next) async {
      final l10n = lookupAppLocalizations(next);
      await NotificationService().applyLanguage(
        name: l10n.notificationChannelName,
        description: l10n.notificationChannelDescription,
      );
      await _locationService.setNotificationText(l10n.locationSharingActive);
    }, fireImmediately: true);
    ref.listenManual<AuthState>(authStateProvider, (previous, next) {
      // Just logged in / session restored: make sure the server knows the user's language
      if (next.status == AuthStatus.authenticated && previous?.status != AuthStatus.authenticated) {
        ref.read(localeProvider.notifier).syncToServer();
      }
      if (_shouldTrack(next)) {
        _locationService.start();
      } else {
        _locationService.stop();
      }
    }, fireImmediately: true);
    NotificationService().onNotificationUpdate = () {
      if (mounted) {
        ref.invalidate(notificationProvider);
        // We also want to fetch immediately after invalidate
        ref.read(notificationProvider.notifier).fetchNotifications();
      }
    };
    NotificationService().onNotificationTap = (data) {
      if (!mounted) return;
      final router = ref.read(routerProvider);
      final user = ref.read(authStateProvider).user;
      final type = data['type'] as String? ?? '';
      navigateForNotificationData(router, user, type, data);
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService().onNotificationUpdate = null;
    NotificationService().onNotificationTap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
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
