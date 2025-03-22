import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class InstituteProfileScreen extends StatefulWidget {
  const InstituteProfileScreen({super.key});

  @override
  State<InstituteProfileScreen> createState() => _InstituteProfileScreenState();
}

class _InstituteProfileScreenState extends State<InstituteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isChangingPassword = false;
  
  @override
  void initState() {
    super.initState();
    _loadInstituteData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Load institute data
  Future<void> _loadInstituteData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      setState(() {
        _nameController.text = authProvider.instituteName ?? '';
        _emailController.text = authProvider.userEmail ?? '';
        _phoneController.text = ''; // This would come from the institute data
        _addressController.text = ''; // This would come from the institute data
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
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // In a real app, this would update the institute profile
      // For now, we'll just show a success message
      
      if (mounted) {
        showSuccessSnackbar(context, 'Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to update profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
  
  // Change password
  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      showErrorSnackbar(context, 'Please enter your current password');
      return;
    }
    
    if (_newPasswordController.text.isEmpty) {
      showErrorSnackbar(context, 'Please enter a new password');
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      showErrorSnackbar(context, 'Passwords do not match');
      return;
    }
    
    setState(() {
      _isChangingPassword = true;
    });
    
    try {
      // In a real app, this would change the password
      // For now, we'll just show a success message
      
      if (mounted) {
        showSuccessSnackbar(context, 'Password changed successfully');
        
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to change password: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute Profile'),
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
                    'Institute Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Institute name
                        CustomTextField(
                          controller: _nameController,
                          label: 'Institute Name',
                          hint: 'Enter institute name',
                          prefixIcon: Icons.business,
                          validator: Validators.name,
                        ),
                        const SizedBox(height: 16),
                        
                        // Email
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter institute email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          hint: 'Enter institute phone number',
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        // Address
                        CustomTextField(
                          controller: _addressController,
                          label: 'Address',
                          hint: 'Enter institute address',
                          prefixIcon: Icons.location_on,
                          maxLines: 2,
                          validator: Validators.required,
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
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: 'Change Password',
                      icon: Icons.vpn_key,
                      isLoading: _isChangingPassword,
                      onPressed: _changePassword,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
