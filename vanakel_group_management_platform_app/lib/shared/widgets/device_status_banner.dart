import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../l10n/app_localizations.dart';

/// Tells the user, in their language, when the phone blocks something the app needs, and gives a
/// button that fixes it: GPS switched off, location not allowed / blocked, notifications blocked,
/// battery restrictions that would stop live tracking.
///
/// It also runs the first-time setup in a sensible order (notifications, then an explanation
/// before the location prompt) instead of throwing system dialogs at the user at random moments.
class DeviceStatusBanner extends ConsumerStatefulWidget {
  const DeviceStatusBanner({super.key});

  @override
  ConsumerState<DeviceStatusBanner> createState() => _DeviceStatusBannerState();
}

class _DeviceStatusBannerState extends ConsumerState<DeviceStatusBanner> with WidgetsBindingObserver {
  static const _kNotificationAsked = 'setup_notification_asked';
  static const _kLocationExplained = 'setup_location_explained';
  static const _kBatteryHintDismissed = 'setup_battery_hint_dismissed';

  bool _notificationsBlocked = false;
  bool _batteryHint = false;
  bool _setupRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRunSetup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // back from the phone's Settings: look again
    if (state == AppLifecycleState.resumed) _refresh();
  }

  bool get _canShareLocation => ref.read(authStateProvider).user?.can('location.share') ?? false;

  Future<void> _refresh() async {
    final notification = await Permission.notification.status;
    var battery = false;
    if (_canShareLocation && ref.read(locationServiceProvider).status.value == LocationStatus.tracking) {
      final prefs = await SharedPreferences.getInstance();
      battery = !(prefs.getBool(_kBatteryHintDismissed) ?? false) && !await Permission.ignoreBatteryOptimizations.isGranted;
    }
    if (!mounted) return;
    setState(() {
      _notificationsBlocked = notification.isDenied || notification.isPermanentlyDenied;
      _batteryHint = battery;
    });
  }

  /// Notifications (Android 13+), then an explanation + the location prompt: once, in this order.
  Future<void> _firstRunSetup() async {
    if (_setupRunning) return;
    _setupRunning = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!(prefs.getBool(_kNotificationAsked) ?? false) && await Permission.notification.isDenied) {
        await prefs.setBool(_kNotificationAsked, true);
        await Permission.notification.request(); // no dialog on Android 12 and older
      }

      if (mounted && _canShareLocation) {
        final service = ref.read(locationServiceProvider);
        await service.start(); // silent: only records the state
        if (mounted && service.status.value == LocationStatus.denied && !(prefs.getBool(_kLocationExplained) ?? false)) {
          await prefs.setBool(_kLocationExplained, true);
          if (await _explainLocation()) await service.start(interactive: true);
        }
      }
    } finally {
      _setupRunning = false;
      await _refresh();
    }
  }

  Future<bool> _explainLocation() async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.zinc900,
        icon: const Icon(Icons.my_location, color: AppTheme.brandGreen),
        title: Text(l10n.locRationaleTitle),
        content: Text(l10n.locRationaleBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.notNow)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.locRationaleContinue)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _dismissBatteryHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBatteryHintDismissed, true);
    if (mounted) setState(() => _batteryHint = false);
  }

  Future<void> _allowBackground() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _dismissBatteryHint();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).user;
    if (user == null) return const SizedBox.shrink();
    final service = ref.watch(locationServiceProvider);

    return ValueListenableBuilder<LocationStatus>(
      valueListenable: service.status,
      builder: (context, status, _) {
        final banners = <Widget>[];

        if (user.can('location.share')) {
          switch (status) {
            case LocationStatus.servicesOff:
              banners.add(_banner(Icons.location_off_outlined, l10n.locBannerServicesOff, l10n.locActionTurnOn,
                  () async => service.resolveProblem()));
            case LocationStatus.denied:
              banners.add(_banner(Icons.location_disabled_outlined, l10n.locBannerDenied, l10n.locActionAllow,
                  () async => service.resolveProblem()));
            case LocationStatus.deniedForever:
              banners.add(_banner(Icons.location_disabled_outlined, l10n.locBannerBlocked, l10n.openSettings,
                  () async => service.resolveProblem()));
            case LocationStatus.tracking:
            case LocationStatus.idle:
              break;
          }
          if (status == LocationStatus.tracking && _batteryHint) {
            banners.add(_banner(Icons.battery_alert_outlined, '${l10n.batteryTitle}. ${l10n.batteryBody}', l10n.locActionAllow,
                _allowBackground,
                secondaryLabel: l10n.later, onSecondary: _dismissBatteryHint));
          }
        }

        if (_notificationsBlocked) {
          banners.add(_banner(Icons.notifications_off_outlined, l10n.notifBlocked, l10n.openSettings, () async {
            await openAppSettings();
          }));
        }

        if (banners.isEmpty) return const SizedBox.shrink();
        return Column(mainAxisSize: MainAxisSize.min, children: banners);
      },
    );
  }

  Widget _banner(IconData icon, String message, String actionLabel, Future<void> Function() onAction,
      {String? secondaryLabel, VoidCallback? onSecondary}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      color: AppTheme.brandOrange.withValues(alpha: 0.14),
      child: Row(children: [
        Icon(icon, color: AppTheme.brandOrange, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12, height: 1.3))),
        if (secondaryLabel != null)
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel, style: const TextStyle(color: AppTheme.zinc400))),
        TextButton(
          onPressed: () async {
            await onAction();
            await _refresh();
          },
          child: Text(actionLabel, style: const TextStyle(color: AppTheme.brandOrange, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
