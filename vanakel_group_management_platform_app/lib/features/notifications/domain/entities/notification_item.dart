class NotificationItem {
  final int id;
  final int? userId;
  final String? role;
  final String title;
  final String? titleEn;
  final String? titleFr;
  final String? titleNl;
  final String body;
  final String? bodyEn;
  final String? bodyFr;
  final String? bodyNl;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    this.userId,
    this.role,
    required this.title,
    this.titleEn,
    this.titleFr,
    this.titleNl,
    required this.body,
    this.bodyEn,
    this.bodyFr,
    this.bodyNl,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      userId: json['user_id'],
      role: json['role'],
      title: json['title'],
      titleEn: json['title_en'],
      titleFr: json['title_fr'],
      titleNl: json['title_nl'],
      body: json['body'],
      bodyEn: json['body_en'],
      bodyFr: json['body_fr'],
      bodyNl: json['body_nl'],
      type: json['type'] ?? 'general',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
