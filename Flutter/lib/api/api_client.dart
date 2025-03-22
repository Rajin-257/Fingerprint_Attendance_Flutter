import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  late Dio _dio;
  final String baseUrl;
  final String licenseKey;
  
  ApiClient({String? baseUrl, String? licenseKey})
      : baseUrl = baseUrl ?? ApiConstants.baseUrl,
        licenseKey = licenseKey ?? ApiConstants.licenseKey {
    _init();
  }
  
  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-license-key': licenseKey,
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
    
    // Add logging interceptor in debug mode
    if (dotenv.env['ENV'] == 'development') {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }
  
  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  // Get auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.token);
  }
  
  // Handle API errors
  dynamic _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.error is SocketException) {
      throw Exception(MessageConstants.networkError);
    } else if (error.response != null) {
      // Server returned an error response
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      if (statusCode == 401) {
        throw Exception(MessageConstants.authError);
      } else if (statusCode == 403) {
        throw Exception(MessageConstants.permissionError);
      } else if (statusCode == 404) {
        throw Exception(MessageConstants.notFoundError);
      } else if (statusCode == 409) {
        throw Exception(MessageConstants.duplicateError);
      } else if (statusCode == 422) {
        // Validation error
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        } else {
          throw Exception(MessageConstants.validationError);
        }
      } else {
        // General server error
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        } else {
          throw Exception(MessageConstants.serverError);
        }
      }
    } else {
      // Something happened in setting up or sending the request
      throw Exception(error.message ?? MessageConstants.serverError);
    }
  }
  
  // GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Check internet connection
      final isConnected = await isOnline();
      if (!isConnected) {
        throw Exception(MessageConstants.noInternet);
      }
      
      // Get token for auth header
      final token = await _getAuthToken();
      final headers = options?.headers ?? {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options?.copyWith(headers: headers) ?? Options(headers: headers),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  
  // POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Check internet connection
      final isConnected = await isOnline();
      if (!isConnected) {
        throw Exception(MessageConstants.noInternet);
      }
      
      // Get token for auth header
      final token = await _getAuthToken();
      final headers = options?.headers ?? {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(headers: headers) ?? Options(headers: headers),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  
  // PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Check internet connection
      final isConnected = await isOnline();
      if (!isConnected) {
        throw Exception(MessageConstants.noInternet);
      }
      
      // Get token for auth header
      final token = await _getAuthToken();
      final headers = options?.headers ?? {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(headers: headers) ?? Options(headers: headers),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  
  // DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      // Check internet connection
      final isConnected = await isOnline();
      if (!isConnected) {
        throw Exception(MessageConstants.noInternet);
      }
      
      // Get token for auth header
      final token = await _getAuthToken();
      final headers = options?.headers ?? {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(headers: headers) ?? Options(headers: headers),
        cancelToken: cancelToken,
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  
  // Upload file
  Future<dynamic> uploadFile(
    String path, {
    required File file,
    String fileName = 'file',
    Map<String, dynamic>? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      // Check internet connection
      final isConnected = await isOnline();
      if (!isConnected) {
        throw Exception(MessageConstants.noInternet);
      }
      
      // Get token for auth header
      final token = await _getAuthToken();
      final headers = options?.headers ?? {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // Create form data
      final formData = FormData.fromMap({
        ...?data,
        fileName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      
      final response = await _dio.post(
        path,
        data: formData,
        options: options?.copyWith(headers: headers) ?? Options(headers: headers),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}