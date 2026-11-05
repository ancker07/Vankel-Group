import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/core/router/mobile_access.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';
import 'package:vanakel_group_management_platform_app/features/auth/domain/entities/user.dart';

// The permissions the server gives each role (see PermissionCatalog on the backend)
const _technicianPermissions = [
  'interventions.view', 'interventions.update', 'maintenance.view', 'buildings.view', 'location.share', 'ai.use',
];
const _adminPermissions = [
  'missions.view', 'missions.create', 'missions.update', 'missions.approve', 'missions.delete',
  'interventions.view', 'interventions.create', 'interventions.update', 'interventions.reopen', 'interventions.send_report',
  'buildings.view', 'buildings.manage', 'reports.view', 'emails.view', 'emails.manage',
  'team.view', 'location.share', 'users.view', 'users.create', 'users.update', 'stats.view', 'ai.use',
];

User _user(String role, List<String> permissions) => UserModel.fromJson({
      'id': 1,
      'name': 'Test',
      'email': 'test@test.be',
      'role': role,
      'portal': 'admin',
      'status': 'APPROVED',
      'permissions': permissions,
    }).toEntity();

void main() {
  final admin = _user('ADMIN', _adminPermissions);
  final technician = _user('PROFESSIONAL', _technicianPermissions);

  test('admin menu: Missions, Interventions, End of mission, Reports, Inbox, Team, Users', () {
    expect(
      [admin.seesMissions, admin.seesInterventions, admin.seesEndOfMission, admin.seesReports, admin.seesInbox, admin.seesTeam, admin.seesUsers],
      everyElement(isTrue),
    );
    expect(admin.seesOnlyOpenInterventions, isFalse);
  });

  test('technician menu: only Interventions (the ones still to do)', () {
    expect(technician.seesInterventions, isTrue);
    expect(technician.seesOnlyOpenInterventions, isTrue);
    expect(
      [technician.seesMissions, technician.seesEndOfMission, technician.seesReports, technician.seesInbox, technician.seesTeam, technician.seesUsers],
      everyElement(isFalse),
    );
  });

  test('nobody has Management, Maintenance, Contacts, Push, AI settings or System on the phone', () {
    for (final user in [admin, technician]) {
      for (final area in ['management', 'maintenance', 'contacts', 'push', 'ai-settings', 'system']) {
        expect(mobileAccessRedirect('/admin/dashboard/$area', user), '/admin/dashboard', reason: area);
      }
    }
  });

  test('routes follow the same rules as the menu', () {
    const adminAreas = ['reports', 'completed', 'emails', 'emails/5', 'team', 'users'];
    for (final area in adminAreas) {
      expect(mobileAccessRedirect('/admin/dashboard/$area', admin), isNull, reason: 'admin $area');
      expect(mobileAccessRedirect('/admin/dashboard/$area', technician), '/admin/dashboard', reason: 'technician $area');
    }
    expect(mobileAccessRedirect('/admin/missions', admin), isNull);
    expect(mobileAccessRedirect('/admin/missions/details/3', technician), '/admin/dashboard');
    expect(mobileAccessRedirect('/admin/interventions/details/3', technician), isNull);
    expect(mobileAccessRedirect('/admin/interventions', admin), isNull);
    for (final user in [admin, technician]) {
      expect(mobileAccessRedirect('/admin/dashboard', user), isNull);
      expect(mobileAccessRedirect('/admin/profile', user), isNull);
      expect(mobileAccessRedirect('/notifications', user), isNull);
      expect(mobileAccessRedirect('/syndic/dashboard', user), '/admin/dashboard');
    }
  });

  test('a super admin or client account has no phone access at all', () {
    final superAdmin = _user('SUPERADMIN', _adminPermissions);
    final syndic = _user('SYNDIC', ['missions.view']);
    expect(superAdmin.mayUseMobileApp, isFalse);
    expect(syndic.mayUseMobileApp, isFalse);
    expect(superAdmin.seesInterventions, isFalse);
    expect(syndic.seesMissions, isFalse);
  });
}
