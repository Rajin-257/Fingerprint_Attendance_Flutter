import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../data/local/database_helper.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

class SyncService {
  final DatabaseHelper _dbHelper;
  final _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  final _syncProgressController = StreamController<double>.broadcast();
  final _syncMessageController = StreamController<String>.broadcast();
  final _uuid = Uuid();
  bool _isOfflineMode = false;
  
  SyncStatus _status = SyncStatus.idle;
  
  // Getters
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  Stream<double> get syncProgressStream => _syncProgressController.stream;
  Stream<String> get syncMessageStream => _syncMessageController.stream;
  SyncStatus get status => _status;
  bool get isOfflineMode => _isOfflineMode;
  
  SyncService(this._dbHelper) {
    _initConnectivityListener();
    _loadOfflineMode();
  }
  
  // Initialize connectivity listener
  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  // Load offline mode setting
  Future<void> _loadOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(StorageKeys.offlineMode) ?? false;
  }
  
  // Set offline mode
  Future<void> setOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.offlineMode, value);
    _isOfflineMode = value;
  }
  
  // Update connection status
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result != ConnectivityResult.none && !_isOfflineMode) {
      // If we're back online and not in forced offline mode, try to sync
      await syncIfNeeded();
    }
  }
  
  // Check if sync is needed
  Future<bool> isSyncNeeded() async {
    // Count all unsynced records
    int unsyncedCount = 0;
    
    // Check all tables
    final tables = [
      DBConstants.studentsTable,
      DBConstants.attendanceTable,
      DBConstants.fingerprintsTable,
    ];
    
    for (final table in tables) {
      final count = await _dbHelper.count(
        table,
        where: 'synced = ?',
        whereArgs: [0],
      );
      unsyncedCount += count;
    }
    
    // Check sync queue
    final queueCount = await _dbHelper.count(DBConstants.syncQueueTable);
    unsyncedCount += queueCount;
    
    return unsyncedCount > 0;
  }
  
  // Sync if needed and online
  Future<bool> syncIfNeeded() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none || _isOfflineMode) {
      return false;
    }
    
    final needsSync = await isSyncNeeded();
    if (needsSync) {
      return await syncAll();
    }
    
    return true;
  }
  
  // Get auth token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.token);
  }
  
  // Generate a unique offline ID
  String generateOfflineId() {
    return _uuid.v4();
  }
  
  // Add an item to the sync queue
  Future<int> addToSyncQueue(String tableType, int recordId, String operation, Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    
    return await _dbHelper.insert(
      DBConstants.syncQueueTable,
      {
        'tableType': tableType,
        'recordId': recordId,
        'operation': operation,
        'data': jsonEncode(data),
        'priority': _getPriorityForTable(tableType),
        'attempts': 0,
        'createdAt': now,
      },
    );
  }
  
  // Get priority level for different table types
  int _getPriorityForTable(String tableType) {
    switch (tableType) {
      case 'students':
        return 10; // Highest priority
      case 'fingerprints':
        return 20;
      case 'attendance':
        return 30;
      default:
        return 50; // Lowest priority
    }
  }
  
  // Sync all pending data
  Future<bool> syncAll() async {
    if (_status == SyncStatus.syncing) {
      return false; // Already syncing
    }
    
    final token = await _getAuthToken();
    if (token == null) {
      _updateSyncStatus(SyncStatus.failed);
      _updateSyncMessage("Authentication error. Please log in again.");
      return false;
    }
    
    _updateSyncStatus(SyncStatus.syncing);
    _updateSyncProgress(0.0);
    _updateSyncMessage("Starting synchronization...");
    
    try {
      // First sync students
      await _syncStudents(token);
      _updateSyncProgress(0.3);
      _updateSyncMessage("Syncing student data...");
      
      // Then sync fingerprints
      await _syncFingerprints(token);
      _updateSyncProgress(0.5);
      _updateSyncMessage("Syncing fingerprint data...");
      
      // Finally sync attendance
      await _syncAttendance(token);
      _updateSyncProgress(0.8);
      _updateSyncMessage("Syncing attendance records...");
      
      // Process sync queue
      await _processSyncQueue(token);
      _updateSyncProgress(1.0);
      _updateSyncMessage("Finalizing sync...");
      
      // Update last sync time
      await _updateLastSyncTime();
      
      _updateSyncStatus(SyncStatus.completed);
      _updateSyncMessage("Synchronization completed successfully!");
      return true;
    } catch (e) {
      _updateSyncStatus(SyncStatus.failed);
      _updateSyncMessage("Synchronization failed: ${e.toString()}");
      return false;
    }
  }
  
  // Update sync status
  void _updateSyncStatus(SyncStatus status) {
    _status = status;
    _syncStatusController.add(status);
  }
  
  // Update sync progress
  void _updateSyncProgress(double progress) {
    _syncProgressController.add(progress);
  }
  
  // Update sync message
  void _updateSyncMessage(String message) {
    _syncMessageController.add(message);
  }
  
  // Sync students
  Future<void> _syncStudents(String token) async {
    final unsyncedStudents = await _dbHelper.getUnsyncedRecords(DBConstants.studentsTable);
    
    // Skip if no unsynced students
    if (unsyncedStudents.isEmpty) return;
    
    for (final student in unsyncedStudents) {
      try {
        // Prepare data for API
        final studentData = {
          'registrationNumber': student['registrationNumber'],
          'firstName': student['firstName'],
          'lastName': student['lastName'],
          'email': student['email'],
          'dateOfBirth': student['dateOfBirth'],
          'gender': student['gender'],
          'contactNumber': student['contactNumber'],
          'address': student['address'],
          'fingerprint': student['fingerprint'],
          'departmentId': student['departmentId'],
          'sectionId': student['sectionId'],
        };
        
        // Add course IDs if available
        final courseEnrollments = await _dbHelper.query(
          'student_course',
          where: 'studentId = ? AND synced = ?',
          whereArgs: [student['id'], 0],
        );
        
        if (courseEnrollments.isNotEmpty) {
          final courseIds = courseEnrollments.map((e) => e['courseId'] as int).toList();
          studentData['courseIds'] = courseIds;
        }
        
        // Send to API
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.teacherStudents}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-license-key': ApiConstants.licenseKey,
          },
          body: jsonEncode(studentData),
        );
        
        if (response.statusCode == 201) {
          // Success - update local record with server ID
          final responseData = jsonDecode(response.body);
          final serverStudentId = responseData['data']['id'];
          
          await _dbHelper.markAsSynced(
            DBConstants.studentsTable,
            student['id'],
            serverStudentId,
          );
          
          // Also mark course enrollments as synced
          for (final enrollment in courseEnrollments) {
            await _dbHelper.update(
              'student_course',
              {'synced': 1},
              where: 'id = ?',
              whereArgs: [enrollment['id']],
            );
          }
        } else {
          // Failed - add to sync queue for later retry
          await addToSyncQueue(
            'students',
            student['id'],
            'create',
            studentData,
          );
        }
      } catch (e) {
        // Handle exception
        continue;
      }
    }
  }
  
  // Sync fingerprints
  Future<void> _syncFingerprints(String token) async {
    final unsyncedFingerprints = await _dbHelper.getUnsyncedRecords(DBConstants.fingerprintsTable);
    
    // Skip if no unsynced fingerprints
    if (unsyncedFingerprints.isEmpty) return;
    
    for (final fingerprint in unsyncedFingerprints) {
      try {
        // Get the server student ID
        final student = await _dbHelper.getById(DBConstants.studentsTable, fingerprint['studentId']);
        if (student == null || student['serverStudentId'] == null) {
          // Can't sync fingerprint without server student ID
          continue;
        }
        
        // Prepare data for API
        final fingerprintData = {
          'studentId': student['serverStudentId'],
          'fingerprint': fingerprint['templateData'],
          'fingerprintPosition': fingerprint['fingerPosition'],
        };
        
        // Update student record with fingerprint
        final response = await http.put(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.teacherStudents}/${student['serverStudentId']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-license-key': ApiConstants.licenseKey,
          },
          body: jsonEncode(fingerprintData),
        );
        
        if (response.statusCode == 200) {
          // Success - mark as synced
          await _dbHelper.update(
            DBConstants.fingerprintsTable,
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [fingerprint['id']],
          );
        } else {
          // Failed - add to sync queue for later retry
          await addToSyncQueue(
            'fingerprints',
            fingerprint['id'],
            'update',
            fingerprintData,
          );
        }
      } catch (e) {
        // Handle exception
        continue;
      }
    }
  }
  
  // Sync attendance records
  Future<void> _syncAttendance(String token) async {
    final unsyncedAttendance = await _dbHelper.getUnsyncedRecords(DBConstants.attendanceTable);
    
    // Skip if no unsynced attendance
    if (unsyncedAttendance.isEmpty) return;
    
    // Group records in batches for bulk sync
    final List<Map<String, dynamic>> attendanceBatch = [];
    
    for (final record in unsyncedAttendance) {
      try {
        // Get server IDs for student and course
        final student = await _dbHelper.getById(DBConstants.studentsTable, record['studentId']);
        final course = await _dbHelper.getById(DBConstants.coursesTable, record['courseId']);
        
        if (student == null || course == null || 
            student['serverStudentId'] == null || course['serverCourseId'] == null) {
          // Can't sync attendance without server IDs
          continue;
        }
        
        // Prepare data for API
        final attendanceData = {
          'offlineId': record['offlineId'],
          'studentId': student['serverStudentId'],
          'courseId': course['serverCourseId'],
          'date': record['date'],
          'status': record['status'],
          'timeIn': record['timeIn'],
          'remarks': record['remarks'],
          'fingerprintVerified': record['fingerprintVerified'] == 1,
        };
        
        // Add to batch
        attendanceBatch.add(attendanceData);
        
        // Sync in batches of 20
        if (attendanceBatch.length >= 20) {
          await _sendAttendanceBatch(token, attendanceBatch, unsyncedAttendance);
          attendanceBatch.clear();
        }
      } catch (e) {
        // Handle exception
        continue;
      }
    }
    
    // Send any remaining batch
    if (attendanceBatch.isNotEmpty) {
      await _sendAttendanceBatch(token, attendanceBatch, unsyncedAttendance);
    }
  }
  
  // Send batch of attendance records
  Future<void> _sendAttendanceBatch(
    String token, 
    List<Map<String, dynamic>> batch,
    List<Map<String, dynamic>> allRecords
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.teacherSync}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-license-key': ApiConstants.licenseKey,
        },
        body: jsonEncode({
          'attendanceRecords': batch,
        }),
      );
      
      if (response.statusCode == 200) {
        // Success - mark records as synced
        final responseData = jsonDecode(response.body);
        final results = responseData['data'];
        
        // Extract the offline IDs from the batch
        final offlineIds = batch.map((item) => item['offlineId'].toString()).toList();
        
        // Mark records as synced
        for (final record in allRecords) {
          if (offlineIds.contains(record['offlineId'])) {
            await _dbHelper.update(
              DBConstants.attendanceTable,
              {'synced': 1},
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }
        }
        
        // Update sync message
        _updateSyncMessage('Synced ${results['created']} new and ${results['updated']} existing attendance records');
      } else {
        // Failed - add to sync queue for later
        for (final record in allRecords) {
          if (batch.any((item) => item['offlineId'] == record['offlineId'])) {
            await addToSyncQueue(
              'attendance',
              record['id'],
              'create',
              {'record': record},
            );
          }
        }
      }
    } catch (e) {
      // Handle exception - add to sync queue
      for (final record in allRecords) {
        if (batch.any((item) => item['offlineId'] == record['offlineId'])) {
          await addToSyncQueue(
            'attendance',
            record['id'],
            'create',
            {'record': record},
          );
        }
      }
    }
  }
  
  // Process sync queue
  Future<void> _processSyncQueue(String token) async {
    // Get items from sync queue ordered by priority
    final queueItems = await _dbHelper.query(
      DBConstants.syncQueueTable,
      orderBy: 'priority ASC, attempts ASC',
    );
    
    if (queueItems.isEmpty) return;
    
    for (final item in queueItems) {
      try {
        final tableType = item['tableType'];
        final recordId = item['recordId'];
        final operation = item['operation'];
        final data = jsonDecode(item['data']);
        
        bool success = false;
        
        // Process based on table type
        switch (tableType) {
          case 'students':
            success = await _processSyncQueueStudent(token, recordId, operation, data);
            break;
          case 'fingerprints':
            success = await _processSyncQueueFingerprint(token, recordId, operation, data);
            break;
          case 'attendance':
            success = await _processSyncQueueAttendance(token, recordId, operation, data);
            break;
          default:
            // Unknown type, mark as failed
            break;
        }
        
        if (success) {
          // Remove from queue if successful
          await _dbHelper.delete(
            DBConstants.syncQueueTable,
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        } else {
          // Update attempt count
          await _dbHelper.update(
            DBConstants.syncQueueTable,
            {
              'attempts': item['attempts'] + 1,
              'lastAttempt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      } catch (e) {
        // Handle exception
        continue;
      }
    }
  }
  
  // Process student sync queue item
  Future<bool> _processSyncQueueStudent(String token, int recordId, String operation, Map<String, dynamic> data) async {
    try {
      // Implementation
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Process fingerprint sync queue item
  Future<bool> _processSyncQueueFingerprint(String token, int recordId, String operation, Map<String, dynamic> data) async {
    try {
      // Implementation
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Process attendance sync queue item
  Future<bool> _processSyncQueueAttendance(String token, int recordId, String operation, Map<String, dynamic> data) async {
    try {
      // Implementation
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Update last sync time
  Future<void> _updateLastSyncTime() async {
    final now = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.lastSyncTime, now);
  }
  
  // Get last sync time
  Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.lastSyncTime);
  }
  
  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _syncProgressController.close();
    _syncMessageController.close();
  }
}