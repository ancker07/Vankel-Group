import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/dio_client.dart';
import '../../core/services/map_service.dart';
import '../../core/theme/app_theme.dart';

/// Team member assigned to an intervention, who assigned them, and their
/// live position (refreshed every 10 seconds).
class TeamMemberTracker extends ConsumerStatefulWidget {
  final String interventionId;

  const TeamMemberTracker({super.key, required this.interventionId});

  @override
  ConsumerState<TeamMemberTracker> createState() => _TeamMemberTrackerState();
}

class _TeamMemberTrackerState extends ConsumerState<TeamMemberTracker> {
  static const _refreshInterval = Duration(seconds: 10);

  Timer? _timer;
  Map<String, dynamic>? _data;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_refreshInterval, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(dioProvider).get('/interventions/${widget.interventionId}/tracking');
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res.data as Map);
      final point = _point(data['member']);
      final oldPoint = _point(_data?['member']);
      setState(() => _data = data);
      if (point != null && oldPoint != null && point != oldPoint) {
        _mapController.move(point, _mapController.camera.zoom);
      }
    } catch (_) {
      // Keep the last known data on a failed refresh
    }
  }

  LatLng? _point(dynamic member) {
    if (member is! Map) return null;
    final lat = double.tryParse('${member['latitude']}');
    final lng = double.tryParse('${member['longitude']}');
    return (lat == null || lng == null) ? null : LatLng(lat, lng);
  }

  String _timeAgo(DateTime time) {
    final d = DateTime.now().difference(time);
    if (d.inSeconds < 60) return '${d.inSeconds.clamp(0, 59)}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final member = _data?['member'];
    if (member is! Map) return const SizedBox.shrink();

    final assignedBy = _data?['assigned_by'];
    final assignedAt = DateTime.tryParse('${_data?['assigned_at']}')?.toLocal();
    final updatedAt = DateTime.tryParse('${member['location_updated_at']}')?.toLocal();
    final fresh = updatedAt != null && DateTime.now().difference(updatedAt).inMinutes < 5;
    final point = _point(member);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.person_pin_circle_outlined, color: AppTheme.brandGreen, size: 18),
            SizedBox(width: 8),
            Text('TEAM MEMBER',
                style: TextStyle(color: AppTheme.zinc400, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('${member['name'] ?? '-'}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          if (member['phone'] != null && '${member['phone']}'.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${member['phone']}')),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${member['phone']}', style: const TextStyle(color: AppTheme.zinc400, fontSize: 13)),
              ),
            ),
          if (assignedBy is Map) ...[
            const SizedBox(height: 10),
            Text(
              'Assigned by ${assignedBy['name']}'
              '${assignedAt != null ? ' · ${assignedAt.day}/${assignedAt.month}/${assignedAt.year} ${assignedAt.hour.toString().padLeft(2, '0')}:${assignedAt.minute.toString().padLeft(2, '0')}' : ''}',
              style: const TextStyle(color: AppTheme.zinc400, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fresh ? AppTheme.brandGreen : AppTheme.zinc800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              updatedAt != null ? 'Location updated ${_timeAgo(updatedAt)}' : 'No location shared yet',
              style: const TextStyle(color: AppTheme.zinc400, fontSize: 12),
            ),
          ]),
          if (point != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    onTap: (_, __) => _openInMaps(point),
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
                        child: const Icon(Icons.person_pin_circle, size: 40, color: AppTheme.brandGreen),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInMaps(point),
                icon: const Icon(Icons.map_outlined, size: 16, color: AppTheme.brandGreen),
                label: const Text('OPEN IN GOOGLE MAPS',
                    style: TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.w900, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.brandGreen)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openInMaps(LatLng p) {
    launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}'),
      mode: LaunchMode.externalApplication,
    );
  }
}
