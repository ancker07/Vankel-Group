class ApiConstants {
  // Use 10.0.2.2 for Android Emulator to access localhost
  // Use your local IP (e.g., 192.168.1.x) for physical devices
  static const String baseUrl = 'https://api.vanakelgroup.com/api';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Auth Endpoints
  static const String login = '/login';
  static const String signup = '/signup';
  static const String sendOtp = '/send-otp';
  static const String verifyOtp = '/verify-otp';
  static const String checkStatus = '/check-status';
  static const String profileUpdate = '/profile/update';
  static const String profileDetails = '/profile/details';
  static const String changePassword = '/change-password';
  static const String updateFcmToken = '/update-fcm-token';

  // User Endpoints
  static const String pendingUsers = '/users/pending';
  static const String approveUser = '/users/{id}/approve';
  static const String rejectUser = '/users/{id}/reject';

  // Intervention Endpoints
  static const String interventions = '/interventions';
  static const String interventionUpdate = '/interventions/{id}';
  static const String sendReport = '/interventions/{id}/send-report';
  static const String buildings = '/buildings';
  static const String syndics = '/syndics';

  // Mission Endpoints
  static const String missions = '/missions';
  static const String approveMission = '/missions/{id}/approve';
  static const String rejectMission = '/missions/{id}/reject';
  
  // AI Endpoints
  static const String improveNote = '/ai/improve';

  static String getStorageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) {
      // If it contains localhost, replace it with the live host
      if (path.contains('localhost')) {
        final relativePath = path
            .replaceFirst(RegExp(r'http://localhost(:\d+)?/storage/'), '')
            .replaceFirst(RegExp(r'http://localhost(:\d+)?/'), '');
        return 'https://api.vanakelgroup.com/storage/$relativePath';
      }
      return path;
    }
    return 'https://api.vanakelgroup.com/storage/$path';
  }
}
