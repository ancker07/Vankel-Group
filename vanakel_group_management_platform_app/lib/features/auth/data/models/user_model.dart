import '../../../../core/enums/user_role_enum.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.bio,
    super.profileImageUrl,
    super.companyName,
    super.propertyCount,
    super.isApproved = false,
    super.isSuperAdmin = false,
    super.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      // The backend only has two portals: 'syndic' (client app) and 'admin'
      // (staff app). Any role the admin panel creates — built-in or custom —
      // lands in one of these two; what that role can actually see is driven
      // by `permissions`, not by its name.
      role: json['portal'] == 'syndic' ? UserRole.syndic : UserRole.admin,
      bio: json['bio'] as String?,
      profileImageUrl:
          json['profile_image_url'] as String? ?? json['image_url'] as String?,
      companyName: json['company_name'] as String?,
      propertyCount: json['property_count'] as int?,
      isApproved: json['is_approved'] == 1 ||
          json['is_approved'] == true ||
          json['status'] == 'APPROVED' ||
          json['status'] == 'ACTIVE',
      isSuperAdmin: (json['role'] as String?)?.toUpperCase() == 'SUPERADMIN' ||
          json['is_super_admin'] == true,
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'company_name': companyName,
      'property_count': propertyCount,
      'is_approved': isApproved ? 1 : 0,
      'is_super_admin': isSuperAdmin,
      'permissions': permissions,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      bio: bio,
      profileImageUrl: profileImageUrl,
      companyName: companyName,
      propertyCount: propertyCount,
      isApproved: isApproved,
      isSuperAdmin: isSuperAdmin,
      permissions: permissions,
    );
  }
}
