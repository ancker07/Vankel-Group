import '../../features/auth/domain/entities/user.dart';

/// What each phone role may open. This mirrors the website exactly:
///
///  * Admin       Dashboard, Missions, Interventions, End of mission, Reports, Inbox, Team, Users, Profile
///  * Technician  Dashboard, Interventions (the ones still to do), Profile
///
/// Management, Maintenance, Contacts, Push notifications, AI settings and System statistics are not on the
/// phone for anyone (the website keeps them for the super admin). Every menu entry and every route goes
/// through these rules, so a deep link or a notification tap cannot open a screen the menu does not show.
extension MobileAccess on User {
  bool get seesMissions => isPlainAdmin && can('missions.view');
  bool get seesInterventions => mayUseMobileApp && can('interventions.view');
  bool get seesEndOfMission => isPlainAdmin && can('interventions.view');
  bool get seesReports => isPlainAdmin && can('reports.view');
  bool get seesInbox => isPlainAdmin && can('emails.view');
  bool get seesTeam => isPlainAdmin && can('team.view');
  bool get seesUsers => isPlainAdmin && can('users.view');

  /// Like the website: a technician only sees the interventions that are still to do.
  bool get seesOnlyOpenInterventions => isTechnician;
}

const _home = '/admin/dashboard';

/// The page to send the user to instead of [path], or null when [path] is allowed.
String? mobileAccessRedirect(String path, User? user) {
  if (user == null) return null;

  // the phone app has no client (syndic) area any more
  if (path.startsWith('/syndic')) return _home;

  bool allowed(bool rule) => rule;
  bool under(String prefix) => path == prefix || path.startsWith('$prefix/');

  if (under('$_home/management') ||
      under('$_home/maintenance') ||
      under('$_home/contacts') ||
      under('$_home/push') ||
      under('$_home/ai-settings') ||
      under('$_home/system')) {
    return _home;
  }
  if (under('$_home/reports')) return allowed(user.seesReports) ? null : _home;
  if (under('$_home/completed')) return allowed(user.seesEndOfMission) ? null : _home;
  if (under('$_home/emails')) return allowed(user.seesInbox) ? null : _home;
  if (under('$_home/team')) return allowed(user.seesTeam) ? null : _home;
  if (under('$_home/users')) return allowed(user.seesUsers) ? null : _home;
  if (under('/admin/missions')) return allowed(user.seesMissions) ? null : _home;
  if (under('/admin/interventions')) return allowed(user.seesInterventions) ? null : _home;
  return null;
}

const mobileDisabledPath = '/mobile-disabled';

/// While the super admin has the mobile app switched off every route leads to the "switched off" screen;
/// once it is on again that screen leads back into the app. Null when no redirect is needed.
String? mobileDisabledRedirect(String path, bool disabled) {
  if (disabled) return path == mobileDisabledPath ? null : mobileDisabledPath;
  return path == mobileDisabledPath ? '/splash' : null;
}
