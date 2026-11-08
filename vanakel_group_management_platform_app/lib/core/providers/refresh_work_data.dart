import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/intervention/presentation/providers/intervention_list_provider.dart';
import '../../features/mission/presentation/providers/mission_detail_provider.dart' as mission_detail;
import '../../features/mission/presentation/providers/mission_list_provider.dart';

/// The one place that brings the work data up to date from the server. Every screen (Ongoing, Reports, End of mission,
/// the dashboards, Missions) reads these lists, so they all follow. Never throws; only the refresh button ([force])
/// replaces what is on screen with the spinner.
class WorkDataRefresher {
  final Ref _ref;
  WorkDataRefresher(this._ref);

  /// Something changed elsewhere, or may have: fetch the lists the app has already loaded.
  void lists() {
    // a list nobody opened yet is fetched fresh when it is opened
    if (_ref.exists(interventionListProvider)) _ref.read(interventionListProvider.notifier).refreshQuietly();
    if (_ref.exists(missionListProvider)) _ref.read(missionListProvider.notifier).refreshQuietly();
  }

  /// The refresh button: the lists are fetched again from the server whatever state they are in, with the spinner on
  /// screen until the new data is in. Completes when the data (or the error, with its retry button) is on screen.
  Future<void> force() async {
    await Future.wait([
      _ref.read(interventionListProvider.notifier).reloadFromServer(),
      _ref.read(missionListProvider.notifier).reloadFromServer(),
    ]);
  }

  /// Pull to refresh: the lists stay on screen while the server is asked (an error leaves them as they are);
  /// completes when the answer is in, so the pull indicator keeps turning until then.
  Future<void> pull() async {
    await Future.wait([
      _ref.read(interventionListProvider.notifier).refreshQuietly(),
      _ref.read(missionListProvider.notifier).refreshQuietly(),
    ]);
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
