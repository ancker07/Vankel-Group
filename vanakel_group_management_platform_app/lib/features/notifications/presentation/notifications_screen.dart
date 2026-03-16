import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/notification_provider.dart';
import '../domain/entities/notification_item.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/translation_helper.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.brandGreen),
            onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $err', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) => notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: AppTheme.zinc800,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(color: AppTheme.zinc500),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                color: AppTheme.brandGreen,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _NotificationTile(item: item);
                  },
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconData = _getIconForType(item.type);
    final iconColor = _getColorForType(item.type);
    
    return GestureDetector(
      onTap: () {
        if (!item.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(item.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: !item.isRead ? AppTheme.zinc900 : AppTheme.zinc950,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !item.isRead ? iconColor.withOpacity(0.3) : AppTheme.zinc800,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationHelper.getLocalizedField(
                          context: context,
                          enValue: item.titleEn,
                          frValue: item.titleFr,
                          nlValue: item.titleNl,
                          fallback: item.title,
                        ),
                        style: TextStyle(
                          fontWeight: !item.isRead ? FontWeight.bold : FontWeight.normal,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(item.createdAt),
                        style: const TextStyle(
                          color: AppTheme.zinc500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TranslationHelper.getLocalizedField(
                      context: context,
                      enValue: item.bodyEn,
                      frValue: item.bodyFr,
                      nlValue: item.bodyNl,
                      fallback: item.body,
                    ),
                    style: TextStyle(
                      color: !item.isRead ? AppTheme.zinc300 : AppTheme.zinc500,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'mission':
        return Icons.assignment_outlined;
      case 'intervention':
        return Icons.engineering_outlined;
      case 'account':
        return Icons.verified_user_outlined;
      case 'broadcast':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'mission':
        return AppTheme.brandOrange;
      case 'intervention':
        return AppTheme.brandGreen;
      case 'account':
        return Colors.blue;
      case 'broadcast':
        return Colors.purple;
      default:
        return AppTheme.zinc500;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return DateFormat('dd/MM').format(date);
  }
}
