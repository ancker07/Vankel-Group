import 'package:go_router/go_router.dart';
import '../enums/user_role_enum.dart';
import '../../features/auth/domain/entities/user.dart';

/// Deep-link to the mission/intervention a notification refers to, under the
/// current user's portal (admin vs syndic). Technician-role users have no
/// mission/intervention screens yet, so their notifications are a no-op here.
void navigateForNotificationData(
  GoRouter router,
  User? user,
  String type,
  Map<String, dynamic>? data,
) {
  if (user == null || user.role == UserRole.technician) return;

  final base = user.role == UserRole.admin ? '/admin' : '/syndic';
  final missionId = data?['mission_id'];
  final interventionId = data?['intervention_id'];

  if (type == 'mission' && missionId != null) {
    router.go('$base/missions/details/$missionId');
  } else if (type == 'intervention' && interventionId != null) {
    router.go('$base/interventions/details/$interventionId');
  }
}
