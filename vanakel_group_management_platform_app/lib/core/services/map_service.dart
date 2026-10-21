import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapService {
  static const String userAgent = 'com.vanakelgroup.app';

  static final Map<String, LatLng?> _geocodeCache = {};
  static final Dio _nominatim = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': userAgent},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Convert an address to coordinates using OpenStreetMap Nominatim (free, no key).
  /// Results are cached for the app session.
  static Future<LatLng?> geocode(String address) {
    if (_geocodeCache.containsKey(address)) return Future.value(_geocodeCache[address]);
    return _pending[address] ??= _enqueue(address);
  }

  static final Map<String, Future<LatLng?>> _pending = {};
  static Future<void> _queue = Future.value();

  /// Nominatim allows ~1 request per second, so lookups run one after another.
  static Future<LatLng?> _enqueue(String address) {
    final result = _queue.then((_) => _lookup(address));
    _queue = result.then((_) => Future.delayed(const Duration(milliseconds: 1100)));
    return result.whenComplete(() => _pending.remove(address));
  }

  static Future<LatLng?> _lookup(String address) async {
    if (_geocodeCache.containsKey(address)) return _geocodeCache[address];

    try {
      final response = await _nominatim.get('/search', queryParameters: {
        'q': address,
        'format': 'json',
        'limit': 1,
      });
      final results = response.data as List;
      final point = results.isEmpty
          ? null
          : LatLng(double.parse(results[0]['lat']), double.parse(results[0]['lon']));
      _geocodeCache[address] = point;
      return point;
    } catch (e) {
      debugPrint('Geocoding failed for "$address": $e');
      return null;
    }
  }

  /// Open turn-by-turn navigation from the user's current position to [address]
  /// (Google Maps; Apple Maps as fallback).
  static Future<void> openDirections(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$encodedAddress&dirflg=d');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening directions: $e');
    }
  }

  /// Generate a static map image URL for a given address using
  /// staticmap.openstreetmap.de — free, no API key required.
  static String getStaticMapUrl(
    String address, {
    int width = 600,
    int height = 300,
  }) {
    if (address == 'No Address' || address.isEmpty) {
      // Generic OSM overview of Brussels (sensible default for Belgian app)
      return 'https://staticmap.openstreetmap.de/staticmap.php?center=50.85,4.35&zoom=12&size=${width}x$height';
    }

    final encodedAddress = Uri.encodeComponent(address);
    // staticmap.openstreetmap.de accepts a `search` query that auto-geocodes.
    // The `markers` param drops a pin at the same location.
    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?search=$encodedAddress'
        '&zoom=15'
        '&size=${width}x$height'
        '&maptype=mapnik'
        '&markers=$encodedAddress,red-pushpin';
  }
}
