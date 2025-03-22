import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../local/database_helper.dart';
import '../../api/api_client.dart';
import '../../config/constants.dart';
import '../../utils/logger.dart';

import 'dart:convert';

class CourseRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  
  CourseRepository({
    required DatabaseHelper dbHelper,
    required ApiClient apiClient,
  })  : _dbHelper = dbHelper,
        _apiClient = apiClient;
  
  // Get all courses for teacher
  Future<List<Course>> getCourses() async {
    try {
      final teacherId = await _getCurrentTeacherId();
      
      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }
      
      final results = await _dbHelper.rawQuery('''
        SELECT 
          c.*,
          d.name as departmentName,
          d.code as departmentCode,
          s.name as sectionName,
          s.code as sectionCode
        FROM ${DBConstants.coursesTable} c
        JOIN ${DBConstants.departmentsTable} d ON c.departmentId = d.id
        JOIN ${DBConstants.sectionsTable} s ON c.sectionId = s.id
        WHERE c.teacherId = ? AND c.active = 1
        ORDER BY c.name ASC
      ''', [teacherId]);
      
      return results.map((data) => Course.fromMap(data)).toList();
    } catch (e) {
      Log.e('CourseRepository - getCourses', e);
      rethrow;
    }
  }
  
  // Get course by ID
  Future<Course?> getCourseById(int id) async {
    try {
      final results = await _dbHelper.rawQuery('''
        SELECT 
          c.*,
          d.name as departmentName,
          d.code as departmentCode,
          s.name as sectionName,
          s.code as sectionCode
        FROM ${DBConstants.coursesTable} c
        JOIN ${DBConstants.departmentsTable} d ON c.departmentId = d.id
        JOIN ${DBConstants.sectionsTable} s ON c.sectionId = s.id
        WHERE c.id = ?
      ''', [id]);
      
      if (results.isEmpty) return null;
      
      return Course.fromMap(results.first);
    } catch (e) {
      Log.e('CourseRepository - getCourseById', e);
      rethrow;
    }
  }
  
  // Get students for course
  Future<List<Student>> getStudentsForCourse(int courseId) async {
    try {
      final results = await _dbHelper.rawQuery('''
        SELECT s.*
        FROM ${DBConstants.studentsTable} s
        JOIN student_course sc ON s.id = sc.studentId
        WHERE sc.courseId = ? AND s.active = 1
        ORDER BY s.firstName ASC, s.lastName ASC
      ''', [courseId]);
      
      return results.map((data) => Student.fromMap(data)).toList();
    } catch (e) {
      Log.e('CourseRepository - getStudentsForCourse', e);
      rethrow;
    }
  }
  
  // Count students in course
  Future<int> countStudentsInCourse(int courseId) async {
    try {
      final result = await _dbHelper.rawQuery('''
        SELECT COUNT(*) as count
        FROM student_course
        WHERE courseId = ?
      ''', [courseId]);
      
      return result.first['count'] as int;
    } catch (e) {
      Log.e('CourseRepository - countStudentsInCourse', e);
      rethrow;
    }
  }
  
  // Load course list from server and save to database
  Future<List<Course>> refreshCourses() async {
    try {
      final teacherId = await _getCurrentTeacherId();
      
      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }
      
      // Get courses from API
      final response = await _apiClient.get(ApiConstants.teacherProfile);
      
      if (response['success'] != true) {
        throw Exception('Failed to get courses: ${response['message']}');
      }
      
      final coursesData = response['data']['courses'] as List<dynamic>;
      
      // Process and save to database
      await _dbHelper.transaction((txn) async {
        for (final courseData in coursesData) {
          // Check if course exists
          final existingCourse = await txn.query(
            DBConstants.coursesTable,
            where: 'serverCourseId = ?',
            whereArgs: [courseData['id']],
          );
          
          final now = DateTime.now().toIso8601String();
          
          if (existingCourse.isEmpty) {
            // Insert new course
            await txn.insert(
              DBConstants.coursesTable,
              {
                'serverCourseId': courseData['id'],
                'name': courseData['name'],
                'code': courseData['code'],
                'description': courseData['description'],
                'creditHours': courseData['creditHours'] ?? 3.0,
                'schedule': courseData['schedule'] != null 
                    ? jsonEncode(courseData['schedule']) 
                    : null,
                'active': courseData['active'] == true ? 1 : 0,
                'departmentId': courseData['departmentId'],
                'sectionId': courseData['sectionId'],
                'teacherId': teacherId,
                'instituteId': await _getCurrentInstituteId(),
                'createdAt': now,
                'synced': 1,
              },
            );
          } else {
            // Update existing course
            await txn.update(
              DBConstants.coursesTable,
              {
                'name': courseData['name'],
                'code': courseData['code'],
                'description': courseData['description'],
                'creditHours': courseData['creditHours'] ?? 3.0,
                'schedule': courseData['schedule'] != null 
                    ? jsonEncode(courseData['schedule']) 
                    : null,
                'active': courseData['active'] == true ? 1 : 0,
                'updatedAt': now,
                'synced': 1,
              },
              where: 'serverCourseId = ?',
              whereArgs: [courseData['id']],
            );
          }
        }
      });
      
      // Get updated course list
      return await getCourses();
    } catch (e) {
      Log.e('CourseRepository - refreshCourses', e);
      rethrow;
    }
  }
  
  // Helper to get current teacher ID
  Future<int?> _getCurrentTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(StorageKeys.userId);
    if (userId == null) return null;
    return int.tryParse(userId);
  }
  
  // Helper to get current institute ID
  Future<int?> _getCurrentInstituteId() async {
    final prefs = await SharedPreferences.getInstance();
    final instituteId = prefs.getString(StorageKeys.instituteId);
    if (instituteId == null) return null;
    return int.tryParse(instituteId);
  }
}
