import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../storage/shared_prefs.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final SharedPrefs _prefs;
  String? _token;
  String? _userType;
  int? _userId;
  String? _userName;
  String? _userEmail;
  String? _userCode;
  int? _instituteId;
  String? _instituteName;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = true;

  AuthProvider(this._prefs) {
    _loadUserData();
  }

  // Getters
  String? get token => _token;
  String? get userType => _userType;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userCode => _userCode;
  int? get instituteId => _instituteId;
  String? get instituteName => _instituteName;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;

  // Load user data from shared preferences
  Future<void> _loadUserData() async {
    _token = await _prefs.getString(StorageKeys.token);
    _userType = await _prefs.getString(StorageKeys.userType);
    final userIdStr = await _prefs.getString(StorageKeys.userId);
    _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
    _userName = await _prefs.getString(StorageKeys.userName);
    _userEmail = await _prefs.getString(StorageKeys.userEmail);
    _userCode = await _prefs.getString(StorageKeys.userCode);
    final instituteIdStr = await _prefs.getString(StorageKeys.instituteId);
    _instituteId = instituteIdStr != null ? int.tryParse(instituteIdStr) : null;
    _instituteName = await _prefs.getString(StorageKeys.instituteName);

    if (_token != null && _userType != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login for different user types
  Future<Map<String, dynamic>> login({
    required String userType,
    required Map<String, dynamic> credentials,
    String? deviceId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String endpoint;
      switch (userType) {
        case 'superAdmin':
          endpoint = ApiConstants.superAdminLogin;
          break;
        case 'institute':
          endpoint = ApiConstants.instituteLogin;
          break;
        case 'teacher':
          endpoint = ApiConstants.teacherLogin;
          // Add device ID for teacher login if provided
          if (deviceId != null) {
            credentials['deviceId'] = deviceId;
          }
          break;
        default:
          throw Exception('Invalid user type');
      }

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-license-key': ApiConstants.licenseKey,
        },
        body: jsonEncode(credentials),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Extract user data from response
        final userData = data['data'];
        final user = userData['user'];
        
        // Save token and user data to shared preferences
        await _prefs.setString(StorageKeys.token, userData['token']);
        await _prefs.setString(StorageKeys.userType, userType);
        await _prefs.setString(StorageKeys.userId, user['id'].toString());
        
        // Handle different user type data
        if (userType == 'superAdmin') {
          await _prefs.setString(StorageKeys.userName, user['fullName']);
          await _prefs.setString(StorageKeys.userEmail, user['email']);
        } else if (userType == 'institute') {
          await _prefs.setString(StorageKeys.userName, user['name']);
          await _prefs.setString(StorageKeys.userEmail, user['email']);
          await _prefs.setString(StorageKeys.userCode, user['code']);
        } else if (userType == 'teacher') {
          final fullName = '${user['firstName']} ${user['lastName']}';
          await _prefs.setString(StorageKeys.userName, fullName);
          await _prefs.setString(StorageKeys.userEmail, user['email']);
          await _prefs.setString(StorageKeys.userCode, user['employeeId']);
          await _prefs.setString(StorageKeys.instituteId, user['instituteId'].toString());
          await _prefs.setString(StorageKeys.instituteName, user['instituteName']);
          
          // Save device ID if provided
          if (deviceId != null) {
            await _prefs.setString(StorageKeys.deviceId, deviceId);
          }
        }
        
        // Update state
        await _loadUserData();
        
        return {
          'success': true,
          'message': MessageConstants.loginSuccessful,
        };
      } else {
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
        
        return {
          'success': false,
          'message': data['message'] ?? MessageConstants.authError,
        };
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Logout
  Future<void> logout() async {
    // Clear all stored data
    await _prefs.clear();
    
    // Reset state
    _token = null;
    _userType = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userCode = null;
    _instituteId = null;
    _instituteName = null;
    _status = AuthStatus.unauthenticated;
    
    notifyListeners();
  }

  // Check if token is valid
  Future<bool> validateToken() async {
    if (_token == null) return false;
    
    try {
      // Endpoint depends on user type
      String endpoint;
      switch (_userType) {
        case 'superAdmin':
          endpoint = ApiConstants.superAdminProfile;
          break;
        case 'institute':
          endpoint = ApiConstants.instituteProfile;
          break;
        case 'teacher':
          endpoint = ApiConstants.teacherProfile;
          break;
        default:
          return false;
      }
      
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
          'x-license-key': ApiConstants.licenseKey,
        },
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        // Token is invalid, logout
        await logout();
        return false;
      }
    } catch (e) {
      // Keep user logged in when offline, we'll validate when back online
      return true;
    }
  }
}