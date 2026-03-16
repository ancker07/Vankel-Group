class MapService {
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
