import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      // Clear token if session expired or invalid
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.token);
      
      // Optionally notify the app about authentication failure
      // This could be done via EventBus or a similar mechanism
    }
    
    // Forward the error
    return handler.next(err);
  }
}