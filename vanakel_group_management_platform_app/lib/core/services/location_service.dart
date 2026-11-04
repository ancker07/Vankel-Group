import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../api/api_constants.dart';
import '../api/dio_client.dart';

/// Why location sharing is (not) working. The UI shows a banner for the "problem" states so the
/// user always knows what to do; nothing fails silently.
enum LocationStatus {
  /// Not started (not logged in, or the role may not share its location).
  idle,

  /// Position is being shared with the team.
  tracking,

  /// GPS / "Location" is switched off in the phone's quick settings.
  servicesOff,

  /// Permission not granted yet: the app can still ask.
  denied,

  /// Blocked ("Don't ask again" / asked twice): only the phone's app settings can fix it.
  deniedForever,
}

/// Sends the user's position to the backend so admins can see the team on the "Team" page.
///
/// Background: while tracking, geolocator runs an Android foreground service (type "location",
/// with a notification). That keeps working when the app is in the background or the screen is off
/// on every Android version from 9 to the latest, because the service is started while the app is
/// visible (Android 10+ then allows location in the background with the normal "while in use"
/// permission; no "Allow all the time" is needed). It stops when the user swipes the app away.
class LocationService {
  /// Minimum time between two uploads, to save battery and requests.
  static const Duration minUploadInterval = Duration(seconds: 15);

  /// While the phone does not move nothing is reported; this keeps "last seen" fresh.
  static const Duration heartbeatInterval = Duration(minutes: 5);

  /// Give up waiting for the very first GPS fix after this long (indoors it can take a while).
  static const Duration firstFixTimeout = Duration(seconds: 20);

  /// Only report a new position after moving this many meters.
  static const int distanceFilterMeters = 10;

  final Dio _dio;
  StreamSubscription<Position>? _subscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Timer? _heartbeat;
  DateTime? _lastUpload;
  Position? _lastPosition;
  bool _starting = false;

  /// Current state; listen to it to show / hide the banner.
  final ValueNotifier<LocationStatus> status = ValueNotifier(LocationStatus.idle);

  LocationService(this._dio);

  /// Text of the Android "sharing your location" notification (follows the app language).
  String notificationText = 'Location sharing with your team is active';

  bool get isRunning => _subscription != null;

  /// Applies a new notification text; restarts the tracking so Android shows it right away.
  Future<void> setNotificationText(String text) async {
    if (text == notificationText) return;
    notificationText = text;
    if (isRunning) {
      await _stopStream();
      await start();
    }
  }

  /// Starts sharing the position if the phone allows it, and records why if it does not.
  ///
  /// [interactive]: show the system permission dialog when permission was never granted.
  /// (A silent start is used on login and when the app comes back to the screen.)
  Future<LocationStatus> start({bool interactive = false}) async {
    if (isRunning) return status.value;
    if (_starting) return status.value;

    // Android 12+ refuses to start a foreground service while the app is in the background
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return status.value;

    _starting = true;
    try {
      _watchServiceStatus();

      if (!await Geolocator.isLocationServiceEnabled()) {
        return _set(LocationStatus.servicesOff);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && interactive) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return _set(LocationStatus.deniedForever);
      if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
        return _set(LocationStatus.denied);
      }

      _subscribe();
      _set(LocationStatus.tracking);
      unawaited(_sendFirstPosition());
      _startHeartbeat();
      return status.value;
    } catch (e) {
      debugPrint('Location: start failed: $e');
      return _set(await _statusAfterFailure());
    } finally {
      _starting = false;
    }
  }

  /// What the banner button does: fix the problem the status describes.
  /// Returns the new status (the phone's settings screens return later: the app re-checks on resume).
  Future<LocationStatus> resolveProblem() async {
    switch (status.value) {
      case LocationStatus.servicesOff:
        await Geolocator.openLocationSettings();
        return status.value;
      case LocationStatus.deniedForever:
        await Geolocator.openAppSettings();
        return status.value;
      case LocationStatus.denied:
        return start(interactive: true);
      case LocationStatus.idle:
      case LocationStatus.tracking:
        return start(interactive: true);
    }
  }

  /// Stops sharing (logout, or the role may not share its location).
  Future<void> stop() async {
    await _stopStream();
    await _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    _set(LocationStatus.idle);
  }

  // ---------------------------------------------------------------------------

  LocationStatus _set(LocationStatus value) {
    if (status.value != value) status.value = value;
    return value;
  }

  void _subscribe() {
    _subscription = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (position) => _onPosition(position),
      onError: (Object e) async {
        debugPrint('Location stream error: $e');
        // permission revoked or GPS switched off while running: show why, retry when it is fixed
        await _stopStream();
        _set(await _statusAfterFailure());
      },
    );
  }

  Future<void> _stopStream() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  /// Reacts to the user switching GPS on / off in the phone's quick settings.
  void _watchServiceStatus() {
    _serviceStatusSubscription ??= Geolocator.getServiceStatusStream().listen((serviceStatus) async {
      if (serviceStatus == ServiceStatus.disabled) {
        await _stopStream();
        _set(LocationStatus.servicesOff);
      } else if (!isRunning) {
        await start();
      }
    }, onError: (Object e) => debugPrint('Location service-status error: $e'));
  }

  Future<LocationStatus> _statusAfterFailure() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocationStatus.servicesOff;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) return LocationStatus.deniedForever;
      if (permission == LocationPermission.denied) return LocationStatus.denied;
    } catch (_) {}
    return LocationStatus.idle; // unknown reason: the next resume tries again
  }

  /// The first upload must not wait for a GPS fix (indoors it may never come): use the last known
  /// position straight away, then try for a fresh one with a time limit.
  Future<void> _sendFirstPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) _onPosition(last, force: true);
    } catch (_) {}
    try {
      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: _settings(withForegroundService: false),
      ).timeout(firstFixTimeout);
      _onPosition(fresh, force: true);
    } catch (e) {
      debugPrint('Location: no first fix yet ($e); the stream will report when it has one');
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      final position = _lastPosition;
      final last = _lastUpload;
      if (position != null && (last == null || DateTime.now().difference(last) >= heartbeatInterval)) {
        _upload(position, force: true);
      }
    });
  }

  void _onPosition(Position position, {bool force = false}) {
    _lastPosition = position;
    _upload(position, force: force);
  }

  LocationSettings _settings({bool withForegroundService = true}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        intervalDuration: minUploadInterval,
        // The one-off "current position" request must not start a second foreground service
        foregroundNotificationConfig: withForegroundService
            ? ForegroundNotificationConfig(
                notificationTitle: 'Vanakel Group',
                notificationText: notificationText,
                notificationIcon: const AndroidResource(name: 'ic_notification', defType: 'drawable'),
                // keeps the CPU awake long enough to upload while the screen is off
                enableWakeLock: true,
                setOngoing: true,
              )
            : null,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: distanceFilterMeters);
  }

  Future<void> _upload(Position position, {bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastUpload != null && now.difference(_lastUpload!) < minUploadInterval) return;
    _lastUpload = now;

    try {
      await _dio.post(ApiConstants.updateLocation, data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      debugPrint('Location update failed: $e');
    }
  }
}

/// One shared instance for the app (the banner, the app shell and the lifecycle code use the same one).
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService(ref.watch(dioProvider));
  ref.onDispose(() => service.stop());
  return service;
});
