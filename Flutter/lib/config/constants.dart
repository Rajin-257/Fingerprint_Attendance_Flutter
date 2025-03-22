import 'package:flutter_dotenv/flutter_dotenv.dart';

// API Constants
class ApiConstants {
  static String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
  static String licenseKey = dotenv.env['LICENSE_KEY'] ?? 'DEMO-LICENSE-KEY-2025';
  
  // Endpoints
  static const String login = '/auth';
  static const String superAdminLogin = '/auth/super-admin/login';
  static const String instituteLogin = '/auth/institute/login';
  static const String teacherLogin = '/auth/teacher/login';
  
  // Super Admin Endpoints
  static const String institutes = '/super-admin/institutes';
  static const String superAdminProfile = '/super-admin/profile';
  static const String superAdminDashboard = '/super-admin/dashboard';
  
  // Institute Endpoints
  static const String teachers = '/institutes/teachers';
  static const String departments = '/departments';
  static const String sections = '/sections';
  static const String courses = '/courses';
  static const String instituteProfile = '/institutes/profile';
  static const String instituteDashboard = '/institutes/dashboard';
  static const String students = '/students/institute';
  static const String attendanceReport = '/students/institute/attendance/report';
  
  // Teacher Endpoints
  static const String teacherStudents = '/teachers/students';
  static const String teacherAttendance = '/teachers/attendance';
  static const String teacherSync = '/teachers/attendance/sync';
  static const String teacherProfile = '/teachers/profile';
  static const String teacherDashboard = '/teachers/dashboard';
  static const String teacherAttendanceReport = '/teachers/attendance/report';
}

// Storage Keys
class StorageKeys {
  static const String token = 'auth_token';
  static const String userType = 'user_type';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String userCode = 'user_code';
  static const String instituteId = 'institute_id';
  static const String instituteName = 'institute_name';
  static const String theme = 'app_theme';
  static const String language = 'app_language';
  static const String lastSyncTime = 'last_sync_time';
  static const String deviceId = 'device_id';
  static const String offlineMode = 'offline_mode';
}

// Database Constants
class DBConstants {
  static String databaseName = dotenv.env['DATABASE_NAME'] ?? 'edu_attendance_system.db';
  static const int databaseVersion = 1;
  
  // Tables
  static const String usersTable = 'users';
  static const String departmentsTable = 'departments';
  static const String sectionsTable = 'sections';
  static const String coursesTable = 'courses';
  static const String teachersTable = 'teachers';
  static const String studentsTable = 'students';
  static const String attendanceTable = 'attendance';
  static const String syncQueueTable = 'sync_queue';
  static const String fingerprintsTable = 'fingerprints';
}

// Message Constants
class MessageConstants {
  // Success Messages
  static const String loginSuccessful = 'Login successful';
  static const String logoutSuccessful = 'Logout successful';
  static const String createSuccessful = 'Created successfully';
  static const String updateSuccessful = 'Updated successfully';
  static const String deleteSuccessful = 'Deleted successfully';
  static const String syncSuccessful = 'Sync completed successfully';
  static const String fingerprintSuccessful = 'Fingerprint registered successfully';
  static const String attendanceSuccessful = 'Attendance recorded successfully';
  
  // Error Messages
  static const String networkError = 'Network error. Please check your connection';
  static const String serverError = 'Server error. Please try again later';
  static const String authError = 'Authentication failed';
  static const String permissionError = 'Permission denied';
  static const String validationError = 'Please check the entered information';
  static const String duplicateError = 'This record already exists';
  static const String notFoundError = 'Record not found';
  static const String syncError = 'Sync failed. Please try again';
  static const String biometricError = 'Fingerprint operation failed';
  static const String attendanceError = 'Failed to record attendance';
  
  // Info Messages
  static const String offlineModeActive = 'Offline mode active. Data will sync when online';
  static const String syncRequired = 'Please sync your data';
  static const String noInternet = 'No internet connection';
  static const String fingerprintPrompt = 'Please scan your fingerprint';
}

// UI Constants
class UIConstants {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeExtraLarge = 18.0;
  
  static const int splashDuration = 2000; // in milliseconds
}