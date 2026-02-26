import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/user_role_enum.dart';

class UserState {
  final UserRole role;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String? profileImageUrl;
  final String? companyName;
  final int? propertyCount;

  const UserState({
    this.role = UserRole.admin,
    this.name = 'John Doe',
    this.email = 'john.doe@example.com',
    this.phone = '+212 600 000 000',
    this.bio = 'Property management professional with 5+ years of experience.',
    this.profileImageUrl,
    this.companyName,
    this.propertyCount,
  });

  UserState copyWith({
    UserRole? role,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? profileImageUrl,
    String? companyName,
    int? propertyCount,
  }) {
    return UserState(
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      companyName: companyName ?? this.companyName,
      propertyCount: propertyCount ?? this.propertyCount,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState(
      role: UserRole.admin,
      companyName: 'Vanakel Group Admin',
    );
  }

  void setRole(UserRole role) {
    state = state.copyWith(
      role: role,
      companyName: role == UserRole.admin ? 'Vanakel Group Admin' : null,
      propertyCount: role == UserRole.syndic ? 12 : null,
    );
  }

  void updateProfile(UserState newState) {
    state = newState;
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
