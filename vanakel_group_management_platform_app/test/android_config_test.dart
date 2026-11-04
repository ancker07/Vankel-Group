import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// The Android project settings the app depends on (Android 9 and newer, location, permissions).
/// These fail if someone changes them in a way that breaks a supported Android version.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  Set<String> declared() => RegExp(r'<uses-permission\s+android:name="([^"]+)"(?![^>]*tools:node="remove")')
      .allMatches(manifest)
      .map((m) => m[1]!.replaceFirst('android.permission.', ''))
      .toSet();

  test('supports Android 9 (API 28) and newer', () {
    expect(RegExp(r'minSdk\s*=\s*28\b').hasMatch(gradle), isTrue, reason: 'minSdk must be 28 (Android 9)');
  });

  test('location permissions work on every version, in the right form', () {
    final p = declared();
    expect(p, containsAll(['ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION']));
    // Android 14+: a foreground service of type "location" needs this permission or it crashes at start
    expect(p, contains('FOREGROUND_SERVICE_LOCATION'));
    expect(p, contains('FOREGROUND_SERVICE'));
    // Android 13+: without it the push alerts and the "sharing location" notification never show
    expect(p, contains('POST_NOTIFICATIONS'));
    // keeps uploading while the screen is off
    expect(p, contains('WAKE_LOCK'));
    // lets the user exempt the app from battery optimisation (OEM phones stop tracking otherwise)
    expect(p, contains('REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'));
  });

  test('no permission the app does not need', () {
    final p = declared();
    // the foreground service keeps location working in the background: "Allow all the time" is not needed
    expect(p, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
    // photos come from the camera app / system picker: no CAMERA permission and no storage access
    expect(p, isNot(contains('CAMERA')));
    for (final storage in ['READ_EXTERNAL_STORAGE', 'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']) {
      expect(p, isNot(contains(storage)));
      expect(manifest, contains('android.permission.$storage" tools:node="remove"'),
          reason: '$storage is added by a plugin and must be removed from the merged manifest');
    }
  });

  test('phones without GPS / camera / telephony are not excluded', () {
    for (final feature in ['location.gps', 'camera', 'telephony', 'microphone']) {
      expect(manifest, contains('android.hardware.$feature" android:required="false"'));
    }
  });

  test('Android 11+ package visibility: links, phone, mail, maps and PDFs can be opened', () {
    for (final scheme in ['https', 'http', 'tel', 'mailto', 'geo']) {
      expect(manifest, contains('android:scheme="$scheme"'));
    }
    expect(manifest, contains('android.speech.RecognitionService')); // voice dictation
  });

  test('live traffic over http is only allowed in debug builds', () {
    expect(manifest, isNot(contains('usesCleartextTraffic')));
    expect(File('android/app/src/debug/AndroidManifest.xml').readAsStringSync(), contains('usesCleartextTraffic="true"'));
  });

  test('canLaunchUrl() is not used to decide whether a button works (always false on Android 11+ without queries)', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (file.path.endsWith('core/utils/launcher.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('canLaunchUrl(') && !lines[i].trimLeft().startsWith('//')) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'Use launchExternal() / openLink() from core/utils/launcher.dart:\n${offenders.join('\n')}');
  });

  test('location permission is requested in one place only', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (file.path.endsWith('core/services/location_service.dart')) continue;
      if (file.readAsStringSync().contains('Geolocator.requestPermission')) offenders.add(file.path);
    }
    expect(offenders, isEmpty, reason: 'Go through LocationService so every outcome is shown to the user');
  });
}
