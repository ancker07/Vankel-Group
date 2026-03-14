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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: _parseRole(json['role'] as String?),
      bio: json['bio'] as String?,
      profileImageUrl:
          json['profile_image_url'] as String? ?? json['image_url'] as String?,
      companyName: json['company_name'] as String?,
      propertyCount: json['property_count'] as int?,
      isApproved: json['is_approved'] == 1 ||
          json['is_approved'] == true ||
          json['status'] == 'APPROVED' ||
          json['status'] == 'ACTIVE',
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
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
      case 'SUPERADMIN':
        return UserRole.admin;
      case 'SYNDIC':
        return UserRole.syndic;
      case 'TECHNICIAN':
        return UserRole.technician;
      default:
        // Try case-insensitive fallback for safety
        final lowerRole = role?.toLowerCase();
        if (lowerRole == 'admin' || lowerRole == 'superadmin')
          return UserRole.admin;
        if (lowerRole == 'syndic') return UserRole.syndic;
        if (lowerRole == 'technician') return UserRole.technician;
        return UserRole.technician; // Default role
    }
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
    );
  }
}
