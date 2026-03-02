import '../../../../core/enums/user_role_enum.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? bio;
  final String? profileImageUrl;
  final String? companyName;
  final int? propertyCount;
  final bool isApproved;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.bio,
    this.profileImageUrl,
    this.companyName,
    this.propertyCount,
    this.isApproved = false,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? bio,
    String? profileImageUrl,
    String? companyName,
    int? propertyCount,
    bool? isApproved,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      companyName: companyName ?? this.companyName,
      propertyCount: propertyCount ?? this.propertyCount,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
