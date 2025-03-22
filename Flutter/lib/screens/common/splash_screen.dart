import 'package:flutter/material.dart';

import '../../widgets/logo_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const LogoWidget(size: 120),
            const SizedBox(height: 32),
            
            // App name
            Text(
              'Education Attendance System',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Loading animation
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 6,
              ),
            ),
            const SizedBox(height: 32),
            
            // Loading text
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}