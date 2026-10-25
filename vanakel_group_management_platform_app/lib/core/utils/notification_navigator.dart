import 'package:go_router/go_router.dart';
import '../enums/user_role_enum.dart';
import '../../features/auth/domain/entities/user.dart';

/// Deep-link to the mission/intervention a notification refers to, under the
/// current user's portal (admin vs syndic). Skips navigation if the user's
/// role doesn't actually grant access to that screen (e.g. a role with
/// interventions.view only, notified about a mission).
void navigateForNotificationData(
  GoRouter router,
  User? user,
  String type,
  Map<String, dynamic>? data,
) {
  if (user == null) return;

  final base = user.role == UserRole.syndic ? '/syndic' : '/admin';
  final missionId = data?['mission_id'];
  final interventionId = data?['intervention_id'];

  if (type == 'mission' && missionId != null && user.can('missions.view')) {
    router.go('$base/missions/details/$missionId');
  } else if (type == 'intervention' &&
      interventionId != null &&
      user.can('interventions.view')) {
    router.go('$base/interventions/details/$interventionId');
  }
}
