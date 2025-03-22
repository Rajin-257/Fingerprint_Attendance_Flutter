import 'dart:math';

import '../api_client.dart';
import '../../config/constants.dart';

class AuthService {
  final ApiClient _apiClient;
  
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  
  // Super admin login
  Future<Map<String, dynamic>> superAdminLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.superAdminLogin,
        data: {
          'username': username,
          'password': password,
        },
      );
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Institute login
  Future<Map<String, dynamic>> instituteLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.instituteLogin,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Teacher login
  Future<Map<String, dynamic>> teacherLogin({
    required String email,
    required String password,
  }) async {
    try {
      // Get device ID for teacher login
      final deviceId = await _getDeviceId();
      
      final response = await _apiClient.post(
        ApiConstants.teacherLogin,
        data: {
          'email': email,
          'password': password,
          'deviceId': deviceId,
        },
      );
      
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Generate a simple device ID
  Future<String> _getDeviceId() async {
    // Generate a random string as device ID
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final deviceId = List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
    
    return 'device-$deviceId-${DateTime.now().millisecondsSinceEpoch}';
  }
}
