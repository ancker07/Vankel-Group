import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../l10n/app_localizations.dart';
import '../utils/launcher.dart';

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

  /// Opens navigation to [address] in whatever maps app the phone has, trying in order:
  /// Google Maps turn-by-turn, the Google Maps link (app or browser), then any app that handles
  /// a generic geo: link. Tells the user when none of them could be opened (it used to do nothing).
  static Future<bool> openDirections(BuildContext context, String address) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final query = address.trim();
    if (query.isEmpty || query == 'No Address') {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noAddress), backgroundColor: Colors.red));
      return false;
    }

    final encoded = Uri.encodeComponent(query);
    final attempts = <Uri>[
      Uri.parse('google.navigation:q=$encoded&mode=d'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving'),
      Uri.parse('geo:0,0?q=$encoded'),
    ];
    for (final uri in attempts) {
      if (await launchExternal(uri)) return true;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenMaps), backgroundColor: Colors.red));
    return false;
  }

  /// Opens a position (latitude / longitude) in a maps app, with the same fallbacks and the same
  /// visible message as [openDirections].
  static Future<bool> openPoint(BuildContext context, double latitude, double longitude) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.couldNotOpenMaps;
    final attempts = <Uri>[
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'),
      Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude'),
    ];
    for (final uri in attempts) {
      if (await launchExternal(uri)) return true;
    }
    messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    return false;
  }

  /// Generate a static map image URL for a given address using
  /// staticmap.openstreetmap.de — free, no API key required.
  static String getStaticMapUrl(
    String address, {
    int width = 600,
    int height = 300,
  }) {
    if (address == 'No Address' || address.trim().isEmpty) {
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
