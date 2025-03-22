import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';

class ErrorScreen extends StatelessWidget {
  final String? message;
  final String? errorCode;
  
  const ErrorScreen({
    super.key,
    this.message,
    this.errorCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Error icon
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              
              // Error title
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Error message
              Text(
                message ?? 'An unexpected error occurred. Please try again later.',
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Error code if available
              if (errorCode != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error code: $errorCode',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Go back button
              CustomButton(
                label: 'Go Back',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
              
              const SizedBox(height: 16),
              
              // Go to home button
              CustomButton(
                label: 'Go to Home',
                icon: Icons.home,
                isOutlined: true,
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
