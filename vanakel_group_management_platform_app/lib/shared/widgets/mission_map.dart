import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/map_service.dart';
import '../../core/theme/app_theme.dart';

/// Small OpenStreetMap preview of an address with a pin.
/// Tapping it opens GPS navigation to the address.
class MissionMap extends StatefulWidget {
  final String address;
  final double height;

  const MissionMap({super.key, required this.address, this.height = 160});

  @override
  State<MissionMap> createState() => _MissionMapState();
}

class _MissionMapState extends State<MissionMap> {
  late Future<LatLng?> _geocode;

  @override
  void initState() {
    super.initState();
    _geocode = _lookup(widget.address);
  }

  @override
  void didUpdateWidget(covariant MissionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _geocode = _lookup(widget.address);
    }
  }

  Future<LatLng?> _lookup(String address) {
    return MapService.geocode(
      address,
    ).timeout(const Duration(seconds: 12), onTimeout: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FutureBuilder<LatLng?>(
        future: _geocode,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _Placeholder(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_searching,
                    size: 32,
                    color: AppTheme.zinc500,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Finding location…',
                    style: TextStyle(color: AppTheme.zinc500, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          final point = snapshot.data;
          if (point == null) {
            return const _Placeholder(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 40, color: AppTheme.zinc500),
                  SizedBox(height: 8),
                  Text(
                    'Map preview unavailable',
                    style: TextStyle(color: AppTheme.zinc500, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
              onTap: (_, __) =>
                  MapService.openDirections(context, widget.address),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: MapService.userAgent,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: AppTheme.brandGreen,
                    ),
                  ),
                ],
              ),
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
  Widget build(BuildContext context) => Container(
    color: AppTheme.zinc900,
    child: Center(child: child),
  );
}
