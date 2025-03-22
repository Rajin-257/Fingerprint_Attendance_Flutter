import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class SuperAdminProfileScreen extends StatefulWidget {
  const SuperAdminProfileScreen({super.key});

  @override
  State<SuperAdminProfileScreen> createState() => _SuperAdminProfileScreenState();
}

class _SuperAdminProfileScreenState extends State<SuperAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUpdating = false;
  // bool _isChangingPassword = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Load user data
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      setState(() {
        _nameController.text = authProvider.userName ?? '';
        _emailController.text = authProvider.userEmail ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load profile data: ${e.toString()}');
      }
    }
  }
  
  // Update profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isUpdating = true;
    });
    
  }
  
  // Change password
  // Future<void> _changePassword() async {
  //   if (_currentPasswordController.text.isEmpty) {
  //     showErrorSnackbar(context, 'Please enter your current password');
  //     return;
  //   }
    
  //   if (_newPasswordController.text.isEmpty) {
  //     showErrorSnackbar(context, 'Please enter a new password');
  //     return;
  //   }
    
  //   if (_newPasswordController.text != _confirmPasswordController.text) {
  //     showErrorSnackbar(context, 'Passwords do not match');
  //     return;
  //   }
    
  //   setState(() {
  //     _isChangingPassword = true;
  //   });
  // }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile section
                  Text(
                    'Profile Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter your name',
                          prefixIcon: Icons.person,
                          validator: Validators.name,
                        ),
                        const SizedBox(height: 16),
                        
                        // Email
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 24),
                        
                        // Update button
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            label: 'Update Profile',
                            icon: Icons.save,
                            isLoading: _isUpdating,
                            onPressed: _updateProfile,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Change password section
                  Text(
                    'Change Password',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Current password
                  CustomTextField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    hint: 'Enter your current password',
                    prefixIcon: Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // New password
                  CustomTextField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    hint: 'Enter your new password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm password
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm your new password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Change password button
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: CustomButton(
                  //     label: 'Change Password',
                  //     icon: Icons.vpn_key,
                  //     isLoading: _isChangingPassword,
                  //     onPressed: _changePassword,
                  //   ),
                  // ),
                ],
              ),
            ),
    );
  }
}
