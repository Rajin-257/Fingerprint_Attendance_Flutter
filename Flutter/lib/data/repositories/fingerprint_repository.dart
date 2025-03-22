import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/models.dart';
import '../local/database_helper.dart';
import '../../api/api_client.dart';
import '../../config/constants.dart';
import '../../core/biometrics/biometric_service.dart';
import '../../utils/logger.dart';

class FingerprintRepository {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient;
  final BiometricService _biometricService;
  
  FingerprintRepository({
    required DatabaseHelper dbHelper,
    required ApiClient apiClient,
    required BiometricService biometricService,
  })  : _dbHelper = dbHelper,
        _apiClient = apiClient,
        _biometricService = biometricService;
  
  // Check if biometrics are available on device
  Future<bool> isBiometricAvailable() async {
    try {
      return await _biometricService.isBiometricAvailable();
    } catch (e) {
      Log.e('FingerprintRepository - isBiometricAvailable', e);
      return false;
    }
  }
  
  // Register fingerprint
  Future<Fingerprint> registerFingerprint({
    required int studentId,
    String position = 'right_thumb',
  }) async {
    try {
      // Register fingerprint
      final result = await _biometricService.registerFingerprint(
        studentId: studentId.toString(),
        position: position,
      );
      
      if (!result['success']) {
        throw Exception(result['message'] ?? 'Fingerprint registration failed');
      }
      
      final now = DateTime.now().toIso8601String();
      
      // Save to database
      final fingerprintData = {
        'studentId': studentId,
        'templateData': result['template'],
        'fingerPosition': position,
        'quality': result['quality'],
        'createdAt': now,
        'synced': 0,
      };
      
      // Check if fingerprint already exists
      final existingFingerprint = await _dbHelper.query(
        DBConstants.fingerprintsTable,
        where: 'studentId = ? AND fingerPosition = ?',
        whereArgs: [studentId, position],
      );
      
      int fingerprintId;
      
      if (existingFingerprint.isNotEmpty) {
        // Update existing
        fingerprintId = existingFingerprint.first['id'];
        fingerprintData['updatedAt'] = now;
        
        await _dbHelper.update(
          DBConstants.fingerprintsTable,
          fingerprintData,
          where: 'id = ?',
          whereArgs: [fingerprintId],
        );
      } else {
        // Insert new
        fingerprintId = await _dbHelper.insert(
          DBConstants.fingerprintsTable,
          fingerprintData,
        );
      }
      
      // Also update student record
      await _dbHelper.update(
        DBConstants.studentsTable,
        {
          'fingerprint': result['template'],
          'updatedAt': now,
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );
      
      // Try to sync if online
      _syncFingerprintIfOnline(studentId, result['template']);
      
      // Return the fingerprint object
      return Fingerprint(
        id: fingerprintId,
        studentId: studentId,
        templateData: result['template'],
        fingerPosition: position,
        quality: result['quality'],
        createdAt: now,
        synced: false,
      );
    } catch (e) {
      Log.e('FingerprintRepository - registerFingerprint', e);
      rethrow;
    }
  }
  
  // Verify fingerprint
  Future<Map<String, dynamic>> verifyFingerprint({
    required int studentId,
  }) async {
    try {
      // Get stored template
      final student = await _dbHelper.getById(
        DBConstants.studentsTable,
        studentId,
      );
      
      if (student == null) {
        throw Exception('Student not found');
      }
      
      if (student['fingerprint'] == null) {
        throw Exception('No fingerprint registered for this student');
      }
      
      // Verify fingerprint
      final result = await _biometricService.verifyFingerprint(
        studentId: studentId.toString(),
        storedTemplate: student['fingerprint'],
      );
      
      return result;
    } catch (e) {
      Log.e('FingerprintRepository - verifyFingerprint', e);
      rethrow;
    }
  }
  
  // Get fingerprints for student
  Future<List<Fingerprint>> getFingerprintsForStudent(int studentId) async {
    try {
      final results = await _dbHelper.query(
        DBConstants.fingerprintsTable,
        where: 'studentId = ?',
        whereArgs: [studentId],
      );
      
      return results.map((data) => Fingerprint.fromMap(data)).toList();
    } catch (e) {
      Log.e('FingerprintRepository - getFingerprintsForStudent', e);
      rethrow;
    }
  }
  
  // Sync fingerprint if online
  Future<void> _syncFingerprintIfOnline(int studentId, String template) async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return; // Skip sync if offline
    }
    
    try {
      // Get server student ID
      final student = await _dbHelper.getById(
        DBConstants.studentsTable,
        studentId,
      );
      
      if (student == null || student['serverStudentId'] == null) {
        return; // Skip if no server ID
      }
      
      // Prepare data for API
      final data = {
        'studentId': student['serverStudentId'],
        'fingerprint': template,
      };
      
      // Send to API
      final response = await _apiClient.put(
        '${ApiConstants.teacherStudents}/${student['serverStudentId']}',
        data: data,
      );
      
      if (response['success'] == true) {
        // Mark as synced
        await _dbHelper.update(
          DBConstants.fingerprintsTable,
          {
            'synced': 1,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'studentId = ?',
          whereArgs: [studentId],
        );
        
        // Also mark student as synced
        await _dbHelper.update(
          DBConstants.studentsTable,
          {
            'synced': 1,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [studentId],
        );
      }
    } catch (e) {
      // Log error but don't rethrow
      Log.e('FingerprintRepository - _syncFingerprintIfOnline', e);
      // Error handled silently as this is a background sync
    }
  }
  
  // Get all unsynced fingerprints
  Future<List<Fingerprint>> getUnsyncedFingerprints() async {
    try {
      final results = await _dbHelper.query(
        DBConstants.fingerprintsTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      return results.map((data) => Fingerprint.fromMap(data)).toList();
    } catch (e) {
      Log.e('FingerprintRepository - getUnsyncedFingerprints', e);
      rethrow;
    }
  }
}