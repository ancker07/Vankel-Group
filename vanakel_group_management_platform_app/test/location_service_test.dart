import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:vanakel_group_management_platform_app/core/services/location_service.dart';

/// Stand-in for the phone's location system, so every Android situation can be reproduced.
class FakeGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  bool servicesEnabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;
  int requests = 0;
  int streamsOpened = 0;
  int settingsOpened = 0;
  int appSettingsOpened = 0;
  Position? lastKnown;
  Object? currentPositionError = TimeoutException('no fix');

  final positions = StreamController<Position>.broadcast();
  final serviceStatus = StreamController<ServiceStatus>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => servicesEnabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    permission = permissionAfterRequest;
    return permission;
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() => serviceStatus.stream;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streamsOpened++;
    return positions.stream;
  }

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async => lastKnown;
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    throw currentPositionError!;
  }

  @override
  Future<bool> openLocationSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString('{"success":true}', 200, headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

Position _position(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGeolocator geo;
  late _RecordingAdapter http;
  late LocationService service;

  setUp(() {
    geo = FakeGeolocator();
    GeolocatorPlatform.instance = geo;
    http = _RecordingAdapter();
    service = LocationService(Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = http);
  });

  tearDown(() => service.stop());

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 250));

  test('GPS switched off: reports it, opens the phone settings, restarts by itself when GPS comes back', () async {
    geo.servicesEnabled = false;
    geo.permission = LocationPermission.whileInUse;

    expect(await service.start(), LocationStatus.servicesOff);
    expect(geo.streamsOpened, 0);

    await service.resolveProblem();
    expect(geo.settingsOpened, 1, reason: 'the banner button must open the location settings');

    // user turns GPS on in the quick settings
    geo.servicesEnabled = true;
    geo.serviceStatus.add(ServiceStatus.enabled);
    await settle();
    expect(service.status.value, LocationStatus.tracking);
    expect(geo.streamsOpened, 1);

    // and off again while tracking
    geo.serviceStatus.add(ServiceStatus.disabled);
    await settle();
    expect(service.status.value, LocationStatus.servicesOff);
    expect(service.isRunning, isFalse);
  });

  test('permission never granted: a silent start does not prompt, an interactive one does', () async {
    expect(await service.start(), LocationStatus.denied);
    expect(geo.requests, 0, reason: 'login / resume must not throw a system dialog at the user');

    expect(await service.start(interactive: true), LocationStatus.tracking);
    expect(geo.requests, 1);
    expect(service.isRunning, isTrue);
  });

  test('permission refused: stays denied and the banner can ask again (until the phone blocks it)', () async {
    geo.permissionAfterRequest = LocationPermission.denied;
    expect(await service.start(interactive: true), LocationStatus.denied);
    expect(await service.resolveProblem(), LocationStatus.denied);
    expect(geo.requests, 2);
    expect(service.isRunning, isFalse);
  });

  test('permission blocked ("don\'t ask again"): the button opens the app settings, not another prompt', () async {
    geo.permission = LocationPermission.deniedForever;
    expect(await service.start(interactive: true), LocationStatus.deniedForever);
    expect(geo.requests, 0);

    await service.resolveProblem();
    expect(geo.appSettingsOpened, 1);
  });

  test('tracking: the first position is uploaded straight away, without waiting for a GPS fix', () async {
    geo.permission = LocationPermission.whileInUse;
    geo.lastKnown = _position(50.85, 4.35);

    await service.start();
    await settle();

    expect(service.status.value, LocationStatus.tracking);
    expect(http.requests, hasLength(1));
    expect(http.requests.first.path, '/location');
    expect(http.requests.first.data, {'latitude': 50.85, 'longitude': 4.35});
  });

  test('a new position from the phone is uploaded, but not more often than every 15 seconds', () async {
    geo.permission = LocationPermission.whileInUse;
    await service.start();
    await settle();

    geo.positions.add(_position(50.0, 4.0));
    await settle();
    geo.positions.add(_position(50.1, 4.1)); // 1 ms later: skipped
    await settle();

    final uploads = http.requests.where((r) => r.path == '/location').toList();
    expect(uploads, hasLength(1));
    expect(uploads.first.data['latitude'], 50.0);
  });

  test('start() twice at the same time opens only one location stream', () async {
    geo.permission = LocationPermission.whileInUse;
    await Future.wait([service.start(), service.start(), service.start()]);
    expect(geo.streamsOpened, 1);
  });

  test('permission revoked while running: the stream error is turned into a visible state', () async {
    geo.permission = LocationPermission.whileInUse;
    await service.start();
    expect(service.status.value, LocationStatus.tracking);

    geo.permission = LocationPermission.denied;
    geo.positions.addError(const PermissionDeniedException('revoked'));
    await settle();

    expect(service.status.value, LocationStatus.denied);
    expect(service.isRunning, isFalse);
  });

  test('stop() ends sharing and goes back to idle (logout)', () async {
    geo.permission = LocationPermission.whileInUse;
    await service.start();
    await service.stop();
    expect(service.status.value, LocationStatus.idle);
    expect(service.isRunning, isFalse);
  });

  test('never starts the foreground service while the app is in the background (Android 12+)', () async {
    final binding = TestWidgetsFlutterBinding.instance;
    geo.permission = LocationPermission.whileInUse;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await service.start();
    expect(geo.streamsOpened, 0);
    expect(service.status.value, LocationStatus.idle);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await service.start();
    expect(geo.streamsOpened, 1);
  });
}
