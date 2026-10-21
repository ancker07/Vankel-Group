import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/map_service.dart';
import '../../core/theme/app_theme.dart';

/// Small OpenStreetMap preview of an address with a pin.
/// Tapping it opens GPS navigation to the address.
class MissionMap extends StatelessWidget {
  final String address;
  final double height;

  const MissionMap({super.key, required this.address, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FutureBuilder<LatLng?>(
        future: MapService.geocode(address),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _Placeholder(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final point = snapshot.data;
          if (point == null) {
            return const _Placeholder(child: Icon(Icons.map_outlined, size: 48, color: AppTheme.zinc800));
          }
          return FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              onTap: (_, __) => MapService.openDirections(address),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: MapService.userAgent,
              ),
              MarkerLayer(markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_on, size: 40, color: AppTheme.brandGreen),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Widget child;
  const _Placeholder({required this.child});

  @override
  Widget build(BuildContext context) => Container(color: AppTheme.zinc900, child: Center(child: child));
}
