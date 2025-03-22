import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class CreateTeacherScreen extends StatefulWidget {
  const CreateTeacherScreen({super.key});

  @override
  State<CreateTeacherScreen> createState() => _CreateTeacherScreenState();
}

class _CreateTeacherScreenState extends State<CreateTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  DateTime? _selectedJoiningDate;
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }
  
  // Open date picker for joining date
  Future<void> _selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedJoiningDate) {
      setState(() {
        _selectedJoiningDate = picked;
      });
    }
  }
  
  // Save teacher
  Future<void> _saveTeacher() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final instituteId = authProvider.instituteId;
      if (instituteId == null) {
        throw Exception('Institute ID not found');
      }
      
      // Check if employee ID already exists
      final existingTeacher = await dbHelper.query(
        DBConstants.teachersTable,
        where: 'employeeId = ? AND instituteId = ?',
        whereArgs: [_employeeIdController.text, instituteId],
      );
      
      if (existingTeacher.isNotEmpty) {
        throw Exception('A teacher with this employee ID already exists');
      }
      
      // Check if email already exists
      final existingEmail = await dbHelper.query(
        DBConstants.teachersTable,
        where: 'email = ? AND instituteId = ?',
        whereArgs: [_emailController.text, instituteId],
      );
      
      if (existingEmail.isNotEmpty) {
        throw Exception('A teacher with this email already exists');
      }
      
      // Insert teacher
      await dbHelper.insert(
        DBConstants.teachersTable,
        {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'employeeId': _employeeIdController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'qualification': _qualificationController.text,
          'joiningDate': _selectedJoiningDate?.toIso8601String(),
          'instituteId': instituteId,
          'active': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
      );
      
      if (mounted) {
        showSuccessSnackbar(context, 'Teacher created successfully');
        
        // Navigate back to teacher list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Teacher'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teacher information section
                    Text(
                      'Teacher Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // First name
                    CustomTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter first name',
                      prefixIcon: Icons.person,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Last name
                    CustomTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter last name',
                      prefixIcon: Icons.person,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Employee ID
                    CustomTextField(
                      controller: _employeeIdController,
                      label: 'Employee ID',
                      hint: 'Enter unique employee ID',
                      prefixIcon: Icons.badge,
                      validator: Validators.employeeId,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter email address',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone (optional)
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone (Optional)',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        // Optional phone number validation
                        if (value != null && value.isNotEmpty) {
                          return Validators.phone(value);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Joining Date
                    GestureDetector(
                      onTap: _selectJoiningDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Joining Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _selectedJoiningDate == null
                              ? 'Select Joining Date'
                              : '${_selectedJoiningDate!.day}/${_selectedJoiningDate!.month}/${_selectedJoiningDate!.year}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Qualification (optional)
                    CustomTextField(
                      controller: _qualificationController,
                      label: 'Qualification (Optional)',
                      hint: 'Enter highest qualification',
                      prefixIcon: Icons.school,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Create Teacher',
                        icon: Icons.save,
                        isLoading: _isSaving,
                        onPressed: _saveTeacher,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Cancel',
                        isOutlined: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}