import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/services/auth_token_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenService = ref.watch(authTokenServiceProvider);
  return AuthRepositoryImpl(dio, tokenService);
});
