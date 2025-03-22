import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class CreateDepartmentScreen extends StatefulWidget {
  const CreateDepartmentScreen({super.key});

  @override
  State<CreateDepartmentScreen> createState() => _CreateDepartmentScreenState();
}

class _CreateDepartmentScreenState extends State<CreateDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Save department
  Future<void> _saveDepartment() async {
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
      
      // Check if department code already exists
      final existingDepartment = await dbHelper.query(
        DBConstants.departmentsTable,
        where: 'code = ? AND instituteId = ?',
        whereArgs: [_codeController.text, instituteId],
      );
      
      if (existingDepartment.isNotEmpty) {
        throw Exception('A department with this code already exists');
      }
      
      // Insert department
      await dbHelper.insert(
        DBConstants.departmentsTable,
        {
          'name': _nameController.text,
          'code': _codeController.text,
          'description': _descriptionController.text,
          'instituteId': instituteId,
          'active': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
      );
      
      if (mounted) {
        showSuccessSnackbar(context, 'Department created successfully');
        
        // Navigate back to department list
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
        title: const Text('Create Department'),
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
                    // Department information section
                    Text(
                      'Department Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Department name
                    CustomTextField(
                      controller: _nameController,
                      label: 'Department Name',
                      hint: 'Enter department name',
                      prefixIcon: Icons.business,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Department code
                    CustomTextField(
                      controller: _codeController,
                      label: 'Department Code',
                      hint: 'Enter department code',
                      prefixIcon: Icons.code,
                      validator: Validators.departmentCode,
                    ),
                    const SizedBox(height: 16),
                    
                    // Department description
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Enter department description',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Create Department',
                        icon: Icons.save,
                        isLoading: _isSaving,
                        onPressed: _saveDepartment,
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
