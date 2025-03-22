import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../local/database_helper.dart';
import '../../api/api_client.dart';
import '../../config/constants.dart';
import '../../utils/logger.dart';

class AttendanceRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  final _uuid = Uuid();
  
  AttendanceRepository({
    required DatabaseHelper dbHelper,
    required ApiClient apiClient,
  })  : _dbHelper = dbHelper,
        _apiClient = apiClient;
  
  // Get attendance records
  Future<List<Attendance>> getAttendance({
    required int courseId,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    int? studentId,
    String? status,
  }) async {
    try {
      // Build where clause
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];
      
      // Always filter by course
      whereConditions.add('courseId = ?');
      whereArgs.add(courseId);
      
      // Add teacher filter
      final teacherId = await _getCurrentTeacherId();
      if (teacherId != null) {
        whereConditions.add('teacherId = ?');
        whereArgs.add(teacherId);
      }
      
      // Optional filters
      if (date != null) {
        whereConditions.add('date = ?');
        whereArgs.add(DateFormat('yyyy-MM-dd').format(date));
      } else if (startDate != null && endDate != null) {
        whereConditions.add('date BETWEEN ? AND ?');
        whereArgs.add(DateFormat('yyyy-MM-dd').format(startDate));
        whereArgs.add(DateFormat('yyyy-MM-dd').format(endDate));
      }
      
      if (studentId != null) {
        whereConditions.add('studentId = ?');
        whereArgs.add(studentId);
      }
      
      if (status != null) {
        whereConditions.add('status = ?');
        whereArgs.add(status);
      }
      
      // Combine where conditions
      final whereClause = whereConditions.join(' AND ');
      
      // Get attendance records
      final results = await _dbHelper.rawQuery('''
        SELECT 
          a.*,
          s.firstName,
          s.lastName,
          s.registrationNumber,
          c.name as courseName,
          c.code as courseCode
        FROM ${DBConstants.attendanceTable} a
        JOIN ${DBConstants.studentsTable} s ON a.studentId = s.id
        JOIN ${DBConstants.coursesTable} c ON a.courseId = c.id
        WHERE $whereClause
        ORDER BY a.date DESC, s.firstName ASC, s.lastName ASC
      ''', whereArgs);
      
      // Convert to Attendance objects
      return results.map((data) {
        final attendance = Attendance.fromMap(data);
        // Add additional information that's not part of the model
        return attendance.copyWith(
          studentName: '${data['firstName']} ${data['lastName']}',
          studentRegNumber: data['registrationNumber'],
          courseName: data['courseName'],
          courseCode: data['courseCode'],
        );
      }).toList();
    } catch (e) {
      Log.e('AttendanceRepository - getAttendance', e);
      rethrow;
    }
  }
  
  // Take attendance
  Future<bool> takeAttendance({
    required int studentId,
    required int courseId,
    required DateTime date,
    required String status,
    String? timeIn,
    String? remarks,
    bool fingerprintVerified = false,
  }) async {
    try {
      // Get user information
      final teacherId = await _getCurrentTeacherId();
      final instituteId = await _getCurrentInstituteId();
      
      if (teacherId == null || instituteId == null) {
        throw Exception('User information is incomplete');
      }
      
      // Format date
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final timeString = timeIn ?? DateFormat('HH:mm:ss').format(DateTime.now());
      
      // Check if record already exists
      final existingRecord = await _dbHelper.query(
        DBConstants.attendanceTable,
        where: 'studentId = ? AND courseId = ? AND date = ?',
        whereArgs: [studentId, courseId, dateString],
      );
      
      final now = DateTime.now().toIso8601String();
      
      if (existingRecord.isNotEmpty) {
        // Update existing record
        await _dbHelper.update(
          DBConstants.attendanceTable,
          {
            'status': status,
            'timeIn': timeString,
            'remarks': remarks,
            'fingerprintVerified': fingerprintVerified ? 1 : 0,
            'updatedAt': now,
            'synced': 0, // Mark for sync
          },
          where: 'id = ?',
          whereArgs: [existingRecord.first['id']],
        );
      } else {
        // Create new record
        final offlineId = _uuid.v4();
        await _dbHelper.insert(
          DBConstants.attendanceTable,
          {
            'offlineId': offlineId,
            'studentId': studentId,
            'courseId': courseId,
            'teacherId': teacherId,
            'instituteId': instituteId,
            'date': dateString,
            'status': status,
            'timeIn': timeString,
            'remarks': remarks,
            'fingerprintVerified': fingerprintVerified ? 1 : 0,
            'verified': 1,
            'syncedFromOffline': 0,
            'createdAt': now,
            'synced': 0, // Mark for sync
          },
        );
      }
      
      // Try to sync if online
      await _syncAttendanceIfOnline(
        studentId: studentId,
        courseId: courseId,
        date: date,
        status: status,
        timeIn: timeString,
        remarks: remarks,
        fingerprintVerified: fingerprintVerified,
      );
      
      return true;
    } catch (e) {
      Log.e('AttendanceRepository - takeAttendance', e);
      rethrow;
    }
  }
  
  // Get attendance by date for a course
  Future<Map<int, Attendance>> getAttendanceByDate({
    required int courseId,
    required DateTime date,
  }) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      
      final results = await _dbHelper.rawQuery('''
        SELECT 
          a.*,
          s.firstName,
          s.lastName,
          s.registrationNumber
        FROM ${DBConstants.attendanceTable} a
        JOIN ${DBConstants.studentsTable} s ON a.studentId = s.id
        WHERE a.courseId = ? AND a.date = ?
      ''', [courseId, dateString]);
      
      // Create a map of student ID to attendance
      final attendanceMap = <int, Attendance>{};
      
      for (final data in results) {
        final attendance = Attendance.fromMap(data);
        // Add student name information
        final studentId = attendance.studentId;
        final studentName = '${data['firstName']} ${data['lastName']}';
        final studentRegNumber = data['registrationNumber'];
        
        attendanceMap[studentId] = attendance.copyWith(
          studentName: studentName,
          studentRegNumber: studentRegNumber,
        );
      }
      
      return attendanceMap;
    } catch (e) {
      Log.e('AttendanceRepository - getAttendanceByDate', e);
      rethrow;
    }
  }
  
  // Get attendance statistics
  Future<Map<String, dynamic>> getAttendanceStatistics({
    required int courseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Default date range if not provided
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      // Format dates
      final startDateString = DateFormat('yyyy-MM-dd').format(start);
      final endDateString = DateFormat('yyyy-MM-dd').format(end);
      
      // Get attendance records for date range
      final results = await _dbHelper.rawQuery('''
        SELECT date, status, COUNT(*) as count
        FROM ${DBConstants.attendanceTable}
        WHERE courseId = ? AND date BETWEEN ? AND ?
        GROUP BY date, status
        ORDER BY date ASC
      ''', [courseId, startDateString, endDateString]);
      
      // Process into statistics
      final dailyStats = <String, Map<String, int>>{};
      final overallStats = {'Present': 0, 'Late': 0, 'Absent': 0, 'Total': 0};
      
      for (final row in results) {
        final date = row['date'] as String;
        final status = row['status'] as String;
        final count = row['count'] as int;
        
        // Add to overall stats
        overallStats[status] = (overallStats[status] ?? 0) + count;
        overallStats['Total'] = (overallStats['Total'] ?? 0) + count;
        
        // Add to daily stats
        if (!dailyStats.containsKey(date)) {
          dailyStats[date] = {'Present': 0, 'Late': 0, 'Absent': 0, 'Total': 0};
        }
        dailyStats[date]![status] = count;
        dailyStats[date]!['Total'] = (dailyStats[date]!['Total'] ?? 0) + count;
      }
      
      // Calculate percentages
      final percentages = <String, double>{};
      if (overallStats['Total']! > 0) {
        percentages['PresentPercentage'] = 
            (overallStats['Present']! / overallStats['Total']!) * 100;
        percentages['LatePercentage'] = 
            (overallStats['Late']! / overallStats['Total']!) * 100;
        percentages['AbsentPercentage'] = 
            (overallStats['Absent']! / overallStats['Total']!) * 100;
      }
      
      return {
        'dailyStats': dailyStats,
        'overallStats': overallStats,
        'percentages': percentages,
      };
    } catch (e) {
      Log.e('AttendanceRepository - getAttendanceStatistics', e);
      rethrow;
    }
  }
  
  // Get unsynced attendance records
  Future<List<Attendance>> getUnsyncedAttendance() async {
    try {
      final results = await _dbHelper.query(
        DBConstants.attendanceTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      return results.map((data) => Attendance.fromMap(data)).toList();
    } catch (e) {
      Log.e('AttendanceRepository - getUnsyncedAttendance', e);
      rethrow;
    }
  }
  
  // Sync attendance if online
  Future<void> _syncAttendanceIfOnline({
    required int studentId,
    required int courseId,
    required DateTime date,
    required String status,
    String? timeIn,
    String? remarks,
    bool fingerprintVerified = false,
  }) async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return; // Skip sync if offline
    }
    
    try {
      // Get server IDs
      final studentRecord = await _dbHelper.getById(DBConstants.studentsTable, studentId);
      final courseRecord = await _dbHelper.getById(DBConstants.coursesTable, courseId);
      
      if (studentRecord == null || courseRecord == null) {
        return;
      }
      
      final serverStudentId = studentRecord['serverStudentId'];
      final serverCourseId = courseRecord['serverCourseId'];
      
      if (serverStudentId == null || serverCourseId == null) {
        return; // Skip if no server IDs
      }
      
      // Prepare data for API
      final attendanceData = {
        'studentId': serverStudentId,
        'courseId': serverCourseId,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'status': status,
        'timeIn': timeIn,
        'remarks': remarks,
        'fingerprintVerified': fingerprintVerified,
      };
      
      // Send to API
      final response = await _apiClient.post(
        ApiConstants.teacherAttendance,
        data: attendanceData,
      );
      
      if (response['success'] == true) {
        // Mark as synced in database
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        
        await _dbHelper.update(
          DBConstants.attendanceTable,
          {
            'serverAttendanceId': response['data']['id'],
            'synced': 1,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'studentId = ? AND courseId = ? AND date = ?',
          whereArgs: [studentId, courseId, dateString],
        );
      }
    } catch (e) {
      // Log error but don't rethrow
      Log.e('AttendanceRepository - _syncAttendanceIfOnline', e);
      // Error handled silently as this is a background sync
    }
  }
  
  // Get current teacher ID from shared prefs
  Future<int?> _getCurrentTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(StorageKeys.userId);
    if (userId == null) return null;
    return int.tryParse(userId);
  }
  
  // Get current institute ID from shared prefs
  Future<int?> _getCurrentInstituteId() async {
    final prefs = await SharedPreferences.getInstance();
    final instituteId = prefs.getString(StorageKeys.instituteId);
    if (instituteId == null) return null;
    return int.tryParse(instituteId);
  }
}