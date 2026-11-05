import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';

/// Whether the super admin has switched the whole mobile app off. While it is off the server refuses every
/// request from the phone, the HTTP client reports it here, and the router shows the "switched off" screen.
class MobileAccessState {
  final bool disabled;
  const MobileAccessState({this.disabled = false});
}

class MobileAccessNotifier extends Notifier<MobileAccessState> {
  @override
  MobileAccessState build() => const MobileAccessState();

  void disable() => state = const MobileAccessState(disabled: true);
  void enable() => state = const MobileAccessState();

  /// Asks the server (the status endpoint stays open while the app is off). True and back to normal when it is on again.
  Future<bool> recheck() async {
    try {
      final response = await ref.read(dioProvider).get('/app-status');
      final data = response.data;
      if (data is Map && data['mobile_enabled'] == true) {
        enable();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final mobileAccessProvider = NotifierProvider<MobileAccessNotifier, MobileAccessState>(
  MobileAccessNotifier.new,
);
