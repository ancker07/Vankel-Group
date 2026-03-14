import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications for UI demonstration
    final notifications = [
      _NotificationItem(
        title: 'New Mission Request',
        message: 'A new mission "Leak in Hallway" has been created.',
        time: '5m ago',
        icon: Icons.assignment_outlined,
        iconColor: AppTheme.brandOrange,
        isUnread: true,
      ),
      _NotificationItem(
        title: 'Intervention Scheduled',
        message: 'The intervention for "Roof Repair" is scheduled for tomorrow.',
        time: '1h ago',
        icon: Icons.engineering_outlined,
        iconColor: AppTheme.brandGreen,
        isUnread: true,
      ),
      _NotificationItem(
        title: 'Account Approved',
        message: 'Your account has been approved by the administrator.',
        time: '2d ago',
        icon: Icons.verified_user_outlined,
        iconColor: Colors.blue,
        isUnread: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.brandBlack,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        centerTitle: true,
      ),
      body: notifications.isEmpty
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
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.isUnread ? AppTheme.zinc900 : AppTheme.zinc950,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isUnread ? AppTheme.brandGreen.withOpacity(0.3) : AppTheme.zinc800,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 20),
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
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  item.time,
                                  style: const TextStyle(
                                    color: AppTheme.zinc500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: const TextStyle(
                                color: AppTheme.zinc400,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.isUnread,
  });
}
