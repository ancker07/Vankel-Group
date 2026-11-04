import '../../features/intervention/domain/intervention.dart';
import '../../features/mission/domain/mission.dart';
import '../../l10n/app_localizations.dart';

/// The sector ids offered when creating a request (each one once).
const sectorIds = ['GENERAL', 'ELECTRICITY', 'TILING', 'SANITARY', 'HEATING', 'PLUMBING', 'PAINTING', 'WOODWORK', 'OTHER'];

/// Older records store the French id (ÉLECTRICITÉ, CARRELAGE...): map any id to the canonical English one.
String canonicalSector(String? value) {
  switch (value?.toUpperCase()) {
    case 'GÉNÉRAL':
      return 'GENERAL';
    case 'ELECTRICITE':
    case 'ÉLECTRICITÉ':
      return 'ELECTRICITY';
    case 'CARRELAGE':
      return 'TILING';
    case 'SANITAIRE':
      return 'SANITARY';
    case 'CHAUFFAGE':
      return 'HEATING';
    case 'PLOMBERIE':
      return 'PLUMBING';
    case 'PEINTURE':
      return 'PAINTING';
    case 'MENUISERIE':
      return 'WOODWORK';
    case 'AUTRE':
      return 'OTHER';
    default:
      final upper = value?.toUpperCase() ?? '';
      return sectorIds.contains(upper) ? upper : 'GENERAL';
  }
}

/// Words for the values the server sends (status, urgency, sector, frequency).
/// Every screen must use these instead of printing `status.name` / the raw server value.
extension AppLabels on AppLocalizations {
  String interventionStatusLabel(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.pending:
        return inProgress;
      case InterventionStatus.delayed:
        return delayed;
      case InterventionStatus.completed:
        return completed;
    }
  }

  String missionStatusLabel(MissionStatus status) {
    switch (status) {
      case MissionStatus.pending:
        return pendingRequest;
      case MissionStatus.approved:
        return accepted;
      case MissionStatus.rejected:
        return rejected;
      case MissionStatus.completed:
        return completed;
      case MissionStatus.needsReview:
        return needsReview;
    }
  }

  String missionUrgencyLabel(MissionUrgency urgency) {
    switch (urgency) {
      case MissionUrgency.low:
        return low;
      case MissionUrgency.normal:
        return normal;
      case MissionUrgency.urgent:
        return urgent;
    }
  }

  /// LOW / MEDIUM / NORMAL / HIGH / URGENT / CRITICAL (any case). Unknown values are shown as they are.
  String urgencyLabel(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOW':
        return low;
      case 'MEDIUM':
        return medium;
      case 'NORMAL':
        return normal;
      case 'HIGH':
        return high;
      case 'URGENT':
        return urgent;
      case 'CRITICAL':
        return critical;
      default:
        return value ?? '';
    }
  }

  /// Sector ids exist in English and French (ELECTRICITY / ELECTRICITE / ÉLECTRICITÉ ...).
  String sectorLabel(String? value) {
    switch (value?.toUpperCase()) {
      case 'GENERAL':
      case 'GÉNÉRAL':
        return general;
      case 'ELECTRICITY':
      case 'ELECTRICITE':
      case 'ÉLECTRICITÉ':
        return electricity;
      case 'TILING':
      case 'CARRELAGE':
        return tiling;
      case 'SANITARY':
      case 'SANITAIRE':
        return sanitary;
      case 'HEATING':
      case 'CHAUFFAGE':
        return heating;
      case 'PLUMBING':
      case 'PLOMBERIE':
        return plumbing;
      case 'PAINTING':
      case 'PEINTURE':
        return painting;
      case 'WOODWORK':
      case 'MENUISERIE':
        return woodwork;
      case 'OTHER':
      case 'AUTRE':
        return other;
      default:
        return value ?? '';
    }
  }

  String frequencyLabel(String? value) {
    switch (value?.toUpperCase()) {
      case 'DAILY':
        return daily;
      case 'WEEKLY':
        return weekly;
      case 'MONTHLY':
        return monthly;
      case 'QUARTERLY':
        return quarterly;
      case 'YEARLY':
        return yearly;
      default:
        return value ?? '';
    }
  }

  /// Email-processing status sent by the server (PROCESSED, NEEDS_REVIEW, IGNORED ...).
  String ingestionStatusLabel(String? value) {
    switch (value?.toUpperCase()) {
      case 'PROCESSED':
        return statusProcessed;
      case 'NEEDS_REVIEW':
        return needsReview;
      case 'IGNORED':
        return statusIgnored;
      case 'SKIPPED':
        return statusSkipped;
      case 'DEFERRED':
        return statusDeferred;
      case 'ERROR':
        return statusError;
      case 'PENDING':
        return statusPending;
      default:
        return value ?? '';
    }
  }

  /// Account / request status sent by the server (PENDING, APPROVED, REJECTED, DEACTIVATED).
  String accountStatusLabel(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return statusPending;
      case 'APPROVED':
      case 'ACTIVE':
        return statusApproved;
      case 'REJECTED':
        return rejected;
      case 'DEACTIVATED':
        return statusDeactivated;
      default:
        return value ?? '';
    }
  }

  /// The four built-in roles are translated; a custom role keeps the name its creator typed.
  String roleLabelFor(String roleName, String serverLabel) {
    switch (roleName.toUpperCase()) {
      case 'SUPERADMIN':
        return roleSuperAdmin;
      case 'ADMIN':
        return admin;
      case 'PROFESSIONAL':
        return technician;
      case 'SYNDIC':
        return syndic;
      default:
        return serverLabel;
    }
  }
}
