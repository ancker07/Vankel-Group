import 'package:flutter_test/flutter_test.dart';
import 'package:vanakel_group_management_platform_app/features/admin/data/admin_models.dart';
import 'package:vanakel_group_management_platform_app/features/auth/data/models/user_model.dart';

Map<String, dynamic> _json(String role) => {
      'id': 1,
      'name': 'Test',
      'email': 'test@test.be',
      'role': role,
      'portal': role == 'SYNDIC' ? 'syndic' : 'admin',
      'status': 'APPROVED',
      'permissions': <String>[],
    };

void main() {
  test('only admins and technicians may use the phone app', () {
    expect(UserModel.fromJson(_json('ADMIN')).toEntity().mayUseMobileApp, isTrue);
    expect(UserModel.fromJson(_json('PROFESSIONAL')).toEntity().mayUseMobileApp, isTrue);
    expect(UserModel.fromJson(_json('PROFESSIONAL')).toEntity().isTechnician, isTrue);
    expect(UserModel.fromJson(_json('SUPERADMIN')).toEntity().mayUseMobileApp, isFalse);
    expect(UserModel.fromJson(_json('SYNDIC')).toEntity().mayUseMobileApp, isFalse);
  });

  test('technician accounts show @username instead of the internal e-mail', () {
    AdminUser user(String email) => AdminUser.fromJson({
          'id': 5,
          'name': 'Jean',
          'email': email,
          'role': 'PROFESSIONAL',
          'status': 'APPROVED',
        });
    expect(user('jean.tech@technician.vankel').loginLabel, '@jean.tech');
    expect(user('someone@company.be').loginLabel, 'someone@company.be');
  });
}
