import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/services/auth_token_service.dart';
import '../../domain/entities/notification_item.dart';

class NotificationNotifier extends Notifier<AsyncValue<List<NotificationItem>>> {
  late final Dio _dio;
  late final AuthTokenService _tokenService;

  @override
  AsyncValue<List<NotificationItem>> build() {
    _dio = ref.watch(dioProvider);
    _tokenService = ref.watch(authTokenServiceProvider);
    
    // Auto-fetch on initialization
    Future.microtask(() => fetchNotifications());
    
    return const AsyncValue.loading();
  }

  Future<void> fetchNotifications() async {
    // If already loading, don't set to loading again to avoid flicker on silent refresh
    // but the screen uses .when so we might want it.
    if (state is! AsyncLoading) {
       state = const AsyncValue.loading();
    }
    
    try {
      final email = _tokenService.getEmail();
      final response = await _dio.get('/notifications', queryParameters: {'email': email});
      
      final List<dynamic> data = response.data;
      final notifications = data.map((json) => NotificationItem.fromJson(json)).toList();
      
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dio.post('/notifications/$id/read');
      
      // Update local state
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          if (n.id == id) {
            return NotificationItem(
              id: n.id,
              userId: n.userId,
              role: n.role,
              title: n.title,
              body: n.body,
              type: n.type,
              isRead: true,
              data: n.data,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Non-blocking error
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final email = _tokenService.getEmail();
      await _dio.post('/notifications/read-all', data: {'email': email});
      
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          return NotificationItem(
            id: n.id,
            userId: n.userId,
            role: n.role,
            title: n.title,
            body: n.body,
            type: n.type,
            isRead: true,
            data: n.data,
            createdAt: n.createdAt,
          );
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Non-blocking error
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, AsyncValue<List<NotificationItem>>>(
  NotificationNotifier.new,
);
