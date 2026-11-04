/// Light models for the admin screens that mirror the website's admin area
/// (inbox, contacts, team, users & roles, push notifications, AI settings).

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class EmailAttachment {
  final String fileName;
  final String filePath;
  final String? mimeType;
  const EmailAttachment({required this.fileName, required this.filePath, this.mimeType});

  factory EmailAttachment.fromJson(Map<String, dynamic> j) => EmailAttachment(
        fileName: _str(j['file_name']) ?? 'file',
        filePath: _str(j['file_path']) ?? '',
        mimeType: _str(j['mime_type']),
      );
}

class AdminEmail {
  final int id;
  final String? threadId;
  final String? fromName;
  final String fromAddress;
  final String? toAddress;
  final String? subject;
  final String body;
  final DateTime? receivedAt;
  final bool isRead;
  final String? ingestionStatus;
  final String? ingestionReason;
  final int threadCount;
  final List<EmailAttachment> attachments;
  final List<AdminEmail> thread;

  const AdminEmail({
    required this.id,
    this.threadId,
    this.fromName,
    required this.fromAddress,
    this.toAddress,
    this.subject,
    this.body = '',
    this.receivedAt,
    this.isRead = false,
    this.ingestionStatus,
    this.ingestionReason,
    this.threadCount = 1,
    this.attachments = const [],
    this.thread = const [],
  });

  String get sender => fromName ?? fromAddress;

  factory AdminEmail.fromJson(Map<String, dynamic> j) => AdminEmail(
        id: (j['id'] as num).toInt(),
        threadId: _str(j['thread_id']),
        fromName: _str(j['from_name']),
        fromAddress: _str(j['from_address']) ?? '',
        toAddress: _str(j['to_address']),
        subject: _str(j['subject']),
        body: j['body_text']?.toString() ?? '',
        receivedAt: _date(j['received_at']),
        isRead: j['is_read'] == true || j['is_read'] == 1,
        ingestionStatus: _str(j['ingestion_status']),
        ingestionReason: _str(j['ingestion_reason']),
        threadCount: (j['thread_count'] as num?)?.toInt() ?? 1,
        attachments: (j['attachments'] as List? ?? [])
            .map((a) => EmailAttachment.fromJson(Map<String, dynamic>.from(a)))
            .toList(),
        thread: (j['thread'] as List? ?? [])
            .map((e) => AdminEmail.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class AdminContact {
  final int id;
  final String name;
  final String email;
  final String? subject;
  final String message;
  final String status;
  final int? missionId;
  final DateTime? createdAt;
  const AdminContact({
    required this.id,
    required this.name,
    required this.email,
    this.subject,
    required this.message,
    required this.status,
    this.missionId,
    this.createdAt,
  });

  factory AdminContact.fromJson(Map<String, dynamic> j) => AdminContact(
        id: (j['id'] as num).toInt(),
        name: _str(j['name']) ?? '',
        email: _str(j['email']) ?? '',
        subject: _str(j['subject']),
        message: j['message']?.toString() ?? '',
        status: _str(j['status']) ?? 'PENDING',
        missionId: (j['mission_id'] as num?)?.toInt(),
        createdAt: _date(j['created_at']),
      );
}

class TeamMember {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: (j['id'] as num).toInt(),
        name: _str(j['name']) ?? '',
        email: _str(j['email']) ?? '',
        phone: _str(j['phone']),
        role: _str(j['role']) ?? '',
        status: _str(j['status']) ?? '',
        latitude: double.tryParse('${j['latitude'] ?? ''}'),
        longitude: double.tryParse('${j['longitude'] ?? ''}'),
        locationUpdatedAt: _date(j['location_updated_at']),
      );
}

class AdminUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String roleLabel;
  final String status;
  final String? companyName;
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.roleLabel,
    required this.status,
    this.companyName,
  });

  bool get isPending => status == 'PENDING';

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: (j['id'] as num).toInt(),
        name: _str(j['name']) ?? '',
        email: _str(j['email']) ?? '',
        phone: _str(j['phone']),
        role: _str(j['role']) ?? '',
        roleLabel: _str(j['role_label']) ?? _str(j['role']) ?? '',
        status: _str(j['status']) ?? '',
        companyName: _str(j['company_name']),
      );
}

class AdminRole {
  final int id;
  final String name;
  final String label;
  final String? description;
  final int usersCount;
  final int permissionsCount;
  final bool assignable;
  final bool full;
  const AdminRole({
    required this.id,
    required this.name,
    required this.label,
    this.description,
    this.usersCount = 0,
    this.permissionsCount = 0,
    this.assignable = true,
    this.full = false,
  });

  factory AdminRole.fromJson(Map<String, dynamic> j) => AdminRole(
        id: (j['id'] as num).toInt(),
        name: _str(j['name']) ?? '',
        label: _str(j['label']) ?? _str(j['name']) ?? '',
        description: _str(j['description']),
        usersCount: (j['users_count'] as num?)?.toInt() ?? 0,
        permissionsCount: (j['permissions'] as List?)?.length ?? 0,
        assignable: j['assignable'] != false,
        full: j['full'] == true,
      );
}

class BroadcastLog {
  final int id;
  final String title;
  final String body;
  final String target;
  final int totalRecipients;
  final int successCount;
  final DateTime? createdAt;
  const BroadcastLog({
    required this.id,
    required this.title,
    required this.body,
    required this.target,
    required this.totalRecipients,
    required this.successCount,
    this.createdAt,
  });

  factory BroadcastLog.fromJson(Map<String, dynamic> j) => BroadcastLog(
        id: (j['id'] as num).toInt(),
        title: _str(j['title']) ?? '',
        body: j['body']?.toString() ?? '',
        target: _str(j['target']) ?? 'all',
        totalRecipients: (j['total_recipients'] as num?)?.toInt() ?? 0,
        successCount: (j['success_count'] as num?)?.toInt() ?? 0,
        createdAt: _date(j['created_at']),
      );
}

class SystemStats {
  final Map<String, int> values;
  const SystemStats(this.values);

  int get(String key) => values[key] ?? 0;

  factory SystemStats.fromJson(Map<String, dynamic> j) => SystemStats({
        for (final e in j.entries)
          if (e.value is num) e.key: (e.value as num).toInt(),
      });
}

class AiSettings {
  final String model;
  final String apiKey;
  const AiSettings({required this.model, required this.apiKey});

  factory AiSettings.fromJson(Map<String, dynamic> j) =>
      AiSettings(model: j['model']?.toString() ?? '', apiKey: j['apiKey']?.toString() ?? '');
}
