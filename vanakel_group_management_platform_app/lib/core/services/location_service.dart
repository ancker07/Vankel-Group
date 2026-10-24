import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../api/api_constants.dart';

/// Sends the user's position to the backend so admins can see the team on
/// the "Team" page. Keeps running while the app is in the background
/// (Android foreground service with a notification / iOS background location).
class LocationService {
  /// Minimum time between two uploads, to save battery and requests.
  static const Duration minUploadInterval = Duration(seconds: 15);

  /// Only report a new position after moving this many meters.
  static const int distanceFilterMeters = 10;

  final Dio _dio;
  StreamSubscription<Position>? _subscription;
  DateTime? _lastUpload;

  LocationService(this._dio);

  bool get isRunning => _subscription != null;

  Future<void> start() async {
    if (isRunning) return;
    if (!await _ensurePermission()) return;

    // Send the current position right away, then follow movements
    try {
      await _upload(await Geolocator.getCurrentPosition(locationSettings: _settings()), force: true);
    } catch (e) {
      debugPrint('Location: initial position failed: $e');
    }

    _subscription = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (position) => _upload(position),
      onError: (e) => debugPrint('Location stream error: $e'),
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        intervalDuration: minUploadInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Vanakel Group',
          notificationText: 'Location sharing with your team is active',
          enableWakeLock: false,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: true,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: distanceFilterMeters);
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // "While in use" is enough to start; the OS may later offer "Always"
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
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
