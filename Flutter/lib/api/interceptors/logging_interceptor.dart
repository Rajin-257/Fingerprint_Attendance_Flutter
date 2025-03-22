import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final method = options.method;
      final baseUrl = options.baseUrl;
      final path = options.path;
      final queryParameters = options.queryParameters;
      final headers = options.headers;
      final data = options.data;
      
      print('┌─────────────────────────────────────────────────────────────────');
      print('│ REQUEST[$method] => $baseUrl$path');
      
      if (queryParameters.isNotEmpty) {
        print('│ Query Parameters: $queryParameters');
      }
      
      if (headers.isNotEmpty) {
        print('│ Headers:');
        headers.forEach((key, value) {
          // Don't print Authorization token in full
          if (key == 'Authorization' && value.toString().startsWith('Bearer ')) {
            print('│   $key: Bearer ${value.toString().substring(7, 15)}...');
          } else {
            print('│   $key: $value');
          }
        });
      }
      
      if (data != null) {
        print('│ Body: $data');
      }
      
      print('└─────────────────────────────────────────────────────────────────');
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final statusCode = response.statusCode;
      final method = response.requestOptions.method;
      final baseUrl = response.requestOptions.baseUrl;
      final path = response.requestOptions.path;
      
      print('┌─────────────────────────────────────────────────────────────────');
      print('│ RESPONSE[$statusCode] => $method $baseUrl$path');
      
      // Log response data, but limit size to avoid console flooding
      final responseData = response.data;
      if (responseData != null) {
        final dataStr = responseData.toString();
        if (dataStr.length > 1000) {
          print('│ Body: ${dataStr.substring(0, 1000)}... (truncated)');
        } else {
          print('│ Body: $dataStr');
        }
      }
      
      print('└─────────────────────────────────────────────────────────────────');
    }
    
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final method = err.requestOptions.method;
      final baseUrl = err.requestOptions.baseUrl;
      final path = err.requestOptions.path;
      final statusCode = err.response?.statusCode;
      
      print('┌─────────────────────────────────────────────────────────────────');
      print('│ ERROR[$statusCode] => $method $baseUrl$path');
      print('│ ${err.message}');
      
      if (err.response?.data != null) {
        print('│ Response: ${err.response!.data}');
      }
      
      print('└─────────────────────────────────────────────────────────────────');
    }
    
    super.onError(err, handler);
  }
}