import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/models.dart';
import '../local/database_helper.dart';
import '../../api/api_client.dart';
import '../../config/constants.dart';
import '../../utils/logger.dart';

import 'package:shared_preferences/shared_preferences.dart';

class StudentRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  
  StudentRepository({
    required DatabaseHelper dbHelper,
    required ApiClient apiClient,
  })  : _dbHelper = dbHelper,
        _apiClient = apiClient;
  
  // Get all students for teacher
  Future<List<Student>> getStudents({
    int? courseId,
    String? search,
  }) async {
    try {
      List<Map<String, dynamic>> results;
      
      if (courseId != null) {
        // Students enrolled in specific course
        results = await _dbHelper.rawQuery('''
          SELECT s.*
          FROM ${DBConstants.studentsTable} s
          JOIN student_course sc ON s.id = sc.studentId
          WHERE sc.courseId = ? AND s.active = 1
          ORDER BY s.firstName ASC, s.lastName ASC
        ''', [courseId]);
      } else {
        // All students for teacher
        final teacherId = await _getCurrentTeacherId();
        
        if (teacherId == null) {
          throw Exception('Teacher ID not found');
        }
        
        // Filter by search term if provided
        String whereClause = 'addedBy = ? AND active = 1';
        List<dynamic> whereArgs = [teacherId];
        
        if (search != null && search.isNotEmpty) {
          whereClause += ' AND (firstName LIKE ? OR lastName LIKE ? OR registrationNumber LIKE ?)';
          final searchTerm = '%$search%';
          whereArgs.addAll([searchTerm, searchTerm, searchTerm]);
        }
        
        results = await _dbHelper.query(
          DBConstants.studentsTable,
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'firstName ASC, lastName ASC',
        );
      }
      
      // Convert to Student objects
      return results.map((data) => Student.fromMap(data)).toList();
    } catch (e) {
      Log.e('StudentRepository - getStudents', e);
      rethrow;
    }
  }
  
  // Get student by ID
  Future<Student?> getStudentById(int id) async {
    try {
      final result = await _dbHelper.query(
        DBConstants.studentsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      return Student.fromMap(result.first);
    } catch (e) {
      Log.e('StudentRepository - getStudentById', e);
      rethrow;
    }
  }
  
  // Create student
  Future<Student> createStudent(Student student, List<int> courseIds) async {
    try {
      // Start transaction
      int studentId = 0;
      
      await _dbHelper.transaction((txn) async {
        // Insert student
        studentId = await txn.insert(
          DBConstants.studentsTable,
          student.toMap(),
        );
        
        // Insert course enrollments
        for (final courseId in courseIds) {
          await txn.insert(
            'student_course',
            {
              'studentId': studentId,
              'courseId': courseId,
              'enrollmentDate': DateTime.now().toIso8601String(),
              'status': 'Active',
              'createdAt': DateTime.now().toIso8601String(),
              'synced': 0,
            },
          );
        }
      });
      
      // Get inserted student with ID
      final insertedStudent = await getStudentById(studentId);
      if (insertedStudent == null) {
        throw Exception('Failed to retrieve created student');
      }
      
      // Try to sync if online
      _syncStudentIfOnline(insertedStudent, courseIds);
      
      return insertedStudent;
    } catch (e) {
      Log.e('StudentRepository - createStudent', e);
      rethrow;
    }
  }
  
  // Update student
  Future<Student> updateStudent(Student student, List<int>? courseIds) async {
    try {
      if (student.id == null) {
        throw Exception('Student ID is required for update');
      }
      
      await _dbHelper.transaction((txn) async {
        // Update student
        await txn.update(
          DBConstants.studentsTable,
          student.toMap(),
          where: 'id = ?',
          whereArgs: [student.id],
        );
        
        // Update course enrollments if provided
        if (courseIds != null) {
          // Delete existing enrollments
          await txn.delete(
            'student_course',
            where: 'studentId = ?',
            whereArgs: [student.id],
          );
          
          // Insert new enrollments
          for (final courseId in courseIds) {
            await txn.insert(
              'student_course',
              {
                'studentId': student.id,
                'courseId': courseId,
                'enrollmentDate': DateTime.now().toIso8601String(),
                'status': 'Active',
                'createdAt': DateTime.now().toIso8601String(),
                'synced': 0,
              },
            );
          }
        }
      });
      
      // Get updated student
      final updatedStudent = await getStudentById(student.id!);
      if (updatedStudent == null) {
        throw Exception('Failed to retrieve updated student');
      }
      
      // Try to sync if online
      _syncStudentIfOnline(updatedStudent, courseIds);
      
      return updatedStudent;
    } catch (e) {
      Log.e('StudentRepository - updateStudent', e);
      rethrow;
    }
  }
  
  // Get course enrollments for student
  Future<List<int>> getStudentCourseIds(int studentId) async {
    try {
      final enrollments = await _dbHelper.query(
        'student_course',
        where: 'studentId = ?',
        whereArgs: [studentId],
      );
      
      return enrollments.map((e) => e['courseId'] as int).toList();
    } catch (e) {
      Log.e('StudentRepository - getStudentCourseIds', e);
      rethrow;
    }
  }
  
  // Sync student if online
  Future<void> _syncStudentIfOnline(Student student, List<int>? courseIds) async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return; // Skip sync if offline
    }
    
    try {
      final data = student.toApiMap();
      
      // Add course IDs if available
      if (courseIds != null && courseIds.isNotEmpty) {
        data['courseIds'] = courseIds;
      }
      
      // Send to API
      final response = await _apiClient.post(
        ApiConstants.teacherStudents,
        data: data,
      );
      
      if (response['success'] == true) {
        // Mark as synced
        await _dbHelper.update(
          DBConstants.studentsTable,
          {
            'serverStudentId': response['data']['id'],
            'synced': 1,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [student.id],
        );
        
        // Also mark course enrollments as synced
        await _dbHelper.update(
          'student_course',
          {'synced': 1},
          where: 'studentId = ?',
          whereArgs: [student.id],
        );
      }
    } catch (e) {
      // Log error but don't rethrow
      Log.e('StudentRepository - _syncStudentIfOnline', e);
      // Error handled silently as this is a background sync
    }
  }
  
  // Helper to get current teacher ID
  Future<int?> _getCurrentTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(StorageKeys.userId);
    if (userId == null) return null;
    return int.tryParse(userId);
  }
}

// Missing import at the top
