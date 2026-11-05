import '../../features/intervention/presentation/providers/intervention_filter_provider.dart';
import '../../features/intervention/presentation/providers/intervention_list_provider.dart';
import '../../features/intervention/presentation/providers/intervention_provider.dart';
import '../../features/maintenance/presentation/providers/maintenance_list_provider.dart';
import '../../features/mission/presentation/providers/mission_detail_provider.dart' as mission_detail;
import '../../features/mission/presentation/providers/mission_filter_provider.dart';
import '../../features/mission/presentation/providers/mission_list_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

/// Forgets everything that belongs to the account that was signed in: its missions, interventions,
/// notifications, lists and filters. Called when the account changes or the user logs out, so the next
/// user never sees (or tries to act on) the previous user's data, e.g. an intervention that is not theirs.
/// Pass `(p) => ref.invalidate(p)` (works with a WidgetRef or a Ref).
void resetUserData(void Function(dynamic provider) invalidate) {
  invalidate(interventionListProvider);
  invalidate(interventionDetailProvider);
  invalidate(missionListProvider);
  invalidate(missionDetailProvider);
  invalidate(mission_detail.missionDetailProvider);
  invalidate(notificationProvider);
  invalidate(syndicListProvider);
  invalidate(buildingListProvider);
  invalidate(professionalListProvider);
  invalidate(maintenanceListProvider);
  invalidate(interventionFilterProvider);
  invalidate(missionFilterProvider);
}
