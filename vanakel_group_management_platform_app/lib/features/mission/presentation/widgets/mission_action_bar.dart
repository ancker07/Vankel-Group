import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/mission.dart';

/// Who may approve / reject a mission, and when: the user needs the missions.approve permission and the mission
/// must still be waiting for a decision (the same rule as on the website).
bool canReviewMission(User? user, Mission mission) =>
    (user?.can('missions.approve') ?? false) &&
    (mission.status == MissionStatus.pending || mission.status == MissionStatus.needsReview);

/// "Approve & assign" / "Reject", pinned to the bottom of the mission screen so they are always in reach, however
/// long the mission is. Approving opens the dialog where the date is set and the mission is assigned to a technician.
class MissionActionBar extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const MissionActionBar({super.key, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.zinc950,
        border: Border(top: BorderSide(color: AppTheme.zinc800)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  key: const Key('approve-mission'),
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(l10n.approveAndAssign, overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  key: const Key('reject-mission'),
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(l10n.reject, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: Colors.red),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
