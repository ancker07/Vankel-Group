import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/intervention/presentation/providers/intervention_list_provider.dart';
import '../../features/mission/presentation/providers/mission_detail_provider.dart' as mission_detail;
import '../../features/mission/presentation/providers/mission_list_provider.dart';

/// The one place that brings the work data up to date from the server. Every screen (Ongoing, Reports, End of mission,
/// the dashboards, Missions) reads these lists, so they all follow. Never throws and never replaces what is on
/// screen with a spinner or an error.
class WorkDataRefresher {
  final Ref _ref;
  WorkDataRefresher(this._ref);

  /// Something changed elsewhere, or may have: fetch the lists the app has already loaded.
  void lists() {
    // a list nobody opened yet is fetched fresh when it is opened
    if (_ref.exists(interventionListProvider)) _ref.read(interventionListProvider.notifier).refreshQuietly();
    if (_ref.exists(missionListProvider)) _ref.read(missionListProvider.notifier).refreshQuietly();
  }

  /// This user just changed something: detail screens fetch again too.
  void afterChange() {
    _ref.invalidate(interventionDetailProvider);
    _ref.invalidate(missionDetailProvider);
    _ref.invalidate(mission_detail.missionDetailProvider);
    lists();
  }
}

final workDataRefresherProvider = Provider<WorkDataRefresher>(WorkDataRefresher.new);
