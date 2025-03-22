import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class CreateSectionScreen extends StatefulWidget {
  const CreateSectionScreen({super.key});

  @override
  State<CreateSectionScreen> createState() => _CreateSectionScreenState();
}

class _CreateSectionScreenState extends State<CreateSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _departments = [];
  int? _selectedDepartmentId;
  
  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Load departments
  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Load departments
      final departments = await dbHelper.query(
        DBConstants.departmentsTable,
        where: 'active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      
      if (mounted) {
        setState(() {
          _departments = departments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load departments: ${e.toString()}');
      }
    }
  }
  
  // Save section
  Future<void> _saveSection() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDepartmentId == null) {
      showErrorSnackbar(context, 'Please select a department');
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
      
      // Check if section code already exists
      final existingSection = await dbHelper.query(
        DBConstants.sectionsTable,
        where: 'code = ? AND departmentId = ?',
        whereArgs: [_codeController.text, _selectedDepartmentId],
      );
      
      if (existingSection.isNotEmpty) {
        throw Exception('A section with this code already exists in the selected department');
      }
      
      // Insert section
      await dbHelper.insert(
        DBConstants.sectionsTable,
        {
          'name': _nameController.text,
          'code': _codeController.text,
          'description': _descriptionController.text,
          'departmentId': _selectedDepartmentId,
          'instituteId': instituteId,
          'active': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
      );
      
      if (mounted) {
        showSuccessSnackbar(context, 'Section created successfully');
        
        // Navigate back to section list
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
        title: const Text('Create Section'),
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
                    // Section information section
                    Text(
                      'Section Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Department dropdown
                    DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDepartmentId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Select Department'),
                        ),
                        ..._departments.map((department) {
                          return DropdownMenuItem<int?>(
                            value: department['id'],
                            child: Text('${department['name']} (${department['code']})'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Section name
                    CustomTextField(
                      controller: _nameController,
                      label: 'Section Name',
                      hint: 'Enter section name',
                      prefixIcon: Icons.group_work,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Section code
                    CustomTextField(
                      controller: _codeController,
                      label: 'Section Code',
                      hint: 'Enter section code',
                      prefixIcon: Icons.code,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 16),
                    
                    // Section description
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Enter section description',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Create Section',
                        icon: Icons.save,
                        isLoading: _isSaving,
                        onPressed: _saveSection,
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
