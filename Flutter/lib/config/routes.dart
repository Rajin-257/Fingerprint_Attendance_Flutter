import 'package:flutter/material.dart';

// Auth Screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// Super Admin Screens
import '../screens/super_admin/dashboard_screen.dart';
import '../screens/super_admin/institutes/create_institute_screen.dart';
import '../screens/super_admin/institutes/institute_list_screen.dart';
import '../screens/super_admin/institutes/institute_details_screen.dart';
import '../screens/super_admin/profile/profile_screen.dart';

// Institute Screens
import '../screens/institute/dashboard_screen.dart';
import '../screens/institute/departments/department_list_screen.dart';
import '../screens/institute/departments/create_department_screen.dart';
import '../screens/institute/sections/section_list_screen.dart';
import '../screens/institute/sections/create_section_screen.dart';
import '../screens/institute/courses/course_list_screen.dart';
import '../screens/institute/courses/create_course_screen.dart';
import '../screens/institute/teachers/teacher_list_screen.dart';
import '../screens/institute/teachers/create_teacher_screen.dart';
import '../screens/institute/profile/profile_screen.dart';
import '../screens/institute/reports/attendance_report_screen.dart';

// Teacher Screens
import '../screens/teacher/dashboard_screen.dart';
import '../screens/teacher/students/student_list_screen.dart';
import '../screens/teacher/students/create_student_screen.dart';
import '../screens/teacher/students/register_fingerprint_screen.dart';
import '../screens/teacher/attendance/take_attendance_screen.dart';
import '../screens/teacher/attendance/attendance_history_screen.dart';
import '../screens/teacher/profile/profile_screen.dart';
import '../screens/teacher/sync/sync_data_screen.dart';

// Common Screens
import '../screens/common/splash_screen.dart';
import '../screens/common/settings_screen.dart';
import '../screens/common/error_screen.dart';

// Route names as constants
class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  
  // Super Admin Routes
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String createInstitute = '/super-admin/institutes/create';
  static const String instituteList = '/super-admin/institutes';
  static const String instituteDetails = '/super-admin/institutes/details';
  static const String superAdminProfile = '/super-admin/profile';
  
  // Institute Routes
  static const String instituteDashboard = '/institute/dashboard';
  static const String departmentList = '/institute/departments';
  static const String createDepartment = '/institute/departments/create';
  static const String sectionList = '/institute/sections';
  static const String createSection = '/institute/sections/create';
  static const String courseList = '/institute/courses';
  static const String createCourse = '/institute/courses/create';
  static const String teacherList = '/institute/teachers';
  static const String createTeacher = '/institute/teachers/create';
  static const String instituteProfile = '/institute/profile';
  static const String attendanceReport = '/institute/reports/attendance';
  
  // Teacher Routes
  static const String teacherDashboard = '/teacher/dashboard';
  static const String studentList = '/teacher/students';
  static const String createStudent = '/teacher/students/create';
  static const String registerFingerprint = '/teacher/students/register-fingerprint';
  static const String takeAttendance = '/teacher/attendance/take';
  static const String attendanceHistory = '/teacher/attendance/history';
  static const String teacherProfile = '/teacher/profile';
  static const String syncData = '/teacher/sync';
  
  // Common Routes
  static const String settings = '/settings';
  static const String error = '/error';
}

// Map of all routes
final Map<String, WidgetBuilder> appRoutes = {
  // Auth Routes
  AppRoutes.login: (context) => const LoginScreen(),
  AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
  
  // Super Admin Routes
  AppRoutes.superAdminDashboard: (context) => const SuperAdminDashboardScreen(),
  AppRoutes.createInstitute: (context) => const CreateInstituteScreen(),
  AppRoutes.instituteList: (context) => const InstituteListScreen(),
  AppRoutes.instituteDetails: (context) => const InstituteDetailsScreen(),
  AppRoutes.superAdminProfile: (context) => const SuperAdminProfileScreen(),
  
  // Institute Routes
  AppRoutes.instituteDashboard: (context) => const InstituteDashboardScreen(),
  AppRoutes.departmentList: (context) => const DepartmentListScreen(),
  AppRoutes.createDepartment: (context) => const CreateDepartmentScreen(),
  AppRoutes.sectionList: (context) => const SectionListScreen(),
  AppRoutes.createSection: (context) => const CreateSectionScreen(),
  AppRoutes.courseList: (context) => const CourseListScreen(),
  AppRoutes.createCourse: (context) => const CreateCourseScreen(),
  AppRoutes.teacherList: (context) => const TeacherListScreen(),
  AppRoutes.createTeacher: (context) => const CreateTeacherScreen(),
  AppRoutes.instituteProfile: (context) => const InstituteProfileScreen(),
  AppRoutes.attendanceReport: (context) => const AttendanceReportScreen(),
  
  // Teacher Routes
  AppRoutes.teacherDashboard: (context) => const TeacherDashboardScreen(),
  AppRoutes.studentList: (context) => const StudentListScreen(),
  AppRoutes.createStudent: (context) => const CreateStudentScreen(),
  AppRoutes.registerFingerprint: (context) => const RegisterFingerprintScreen(),
  AppRoutes.takeAttendance: (context) => const TakeAttendanceScreen(),
  AppRoutes.attendanceHistory: (context) => const AttendanceHistoryScreen(),
  AppRoutes.teacherProfile: (context) => const TeacherProfileScreen(),
  AppRoutes.syncData: (context) => const SyncDataScreen(),
  
  // Common Routes
  AppRoutes.settings: (context) => const SettingsScreen(),
  AppRoutes.error: (context) => const ErrorScreen(),
};