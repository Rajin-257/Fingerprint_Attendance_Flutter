import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/themes.dart';
import 'core/auth/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/common/splash_screen.dart';

class EducationApp extends StatelessWidget {
  const EducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Education Attendance System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default to light theme
      routes: appRoutes,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show splash screen when checking authentication
          if (authProvider.isLoading) {
            return const SplashScreen();
          }
          
          // Redirect based on authentication status
          if (authProvider.isAuthenticated) {
            // Redirect to appropriate dashboard based on user role
            switch (authProvider.userType) {
              case 'superAdmin':
                return appRoutes[AppRoutes.superAdminDashboard]!(context);
              case 'institute':
                return appRoutes[AppRoutes.instituteDashboard]!(context);
              case 'teacher':
                return appRoutes[AppRoutes.teacherDashboard]!(context);
              default:
                return const LoginScreen();
            }
          } else {
            // Not authenticated, show login screen
            return const LoginScreen();
          }
        },
      ),
    );
  }
}