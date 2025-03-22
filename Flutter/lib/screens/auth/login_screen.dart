import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../core/auth/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/logo_widget.dart';
import '../../utils/validators.dart';
import '../../utils/snackbar_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedUserType = 'teacher'; // Default to teacher login
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Prepare credentials based on user type
      Map<String, dynamic> credentials;
      
      switch (_selectedUserType) {
        case 'superAdmin':
          credentials = {
            'username': _usernameController.text,
            'password': _passwordController.text,
          };
          break;
        case 'institute':
          credentials = {
            'email': _emailController.text,
            'password': _passwordController.text,
          };
          break;
        case 'teacher':
          credentials = {
            'email': _emailController.text,
            'password': _passwordController.text,
          };
          break;
        default:
          throw Exception('Invalid user type');
      }
      
      // Attempt login
      final result = await authProvider.login(
        userType: _selectedUserType,
        credentials: credentials,
      );
      
      if (!mounted) return;
      
      if (result['success']) {
        // Login successful - navigation will be handled by the app's router
        // based on the auth provider's state
      } else {
        // Show error message
        showErrorSnackbar(context, result['message']);
      }
    } catch (e) {
      showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  const LogoWidget(size: 120),
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Title
                  Text(
                    'Education Attendance System',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  
                  // Subtitle
                  Text(
                    'Login to your account',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: UIConstants.paddingLarge * 2),
                  
                  // User type selector
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        _buildUserTypeOption('Teacher', 'teacher'),
                        _buildUserTypeOption('Institute', 'institute'),
                        _buildUserTypeOption('Admin', 'superAdmin'),
                      ],
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Login fields based on user type
                  if (_selectedUserType == 'superAdmin') ...[
                    // Username field for super admin
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'Enter your username',
                      prefixIcon: Icons.person,
                      validator: Validators.required,
                    ),
                  ] else ...[
                    // Email field for institute and teacher
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                  ],
                  const SizedBox(height: UIConstants.paddingMedium),
                  
                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock,
                    isPassword: true,
                    validator: Validators.required,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to forgot password screen
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Login button
                  CustomButton(
                    label: 'Login',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  
                  const SizedBox(height: UIConstants.paddingLarge * 2),
                  
                  // App version
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(String label, String value) {
    final isSelected = _selectedUserType == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUserType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: UIConstants.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}