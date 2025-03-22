import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditHoursController = TextEditingController();
  final _scheduleController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Department and Section dropdowns
  int? _selectedDepartmentId;
  int? _selectedSectionId;
  
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _sections = [];
  
  @override
  void initState() {
    super.initState();
    _loadDepartmentsAndSections();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _creditHoursController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }
  
  // Load departments and sections
  Future<void> _loadDepartmentsAndSections() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final instituteId = authProvider.instituteId;
      if (instituteId == null) {
        throw Exception('Institute ID not found');
      }
      
      // Load active departments
      final departments = await dbHelper.query(
        DBConstants.departmentsTable,
        where: 'active = ? AND instituteId = ?',
        whereArgs: [1, instituteId],
        orderBy: 'name ASC',
      );
      
      // Load active sections
      final sections = await dbHelper.query(
        DBConstants.sectionsTable,
        where: 'active = ? AND instituteId = ?',
        whereArgs: [1, instituteId],
        orderBy: 'name ASC',
      );
      
      if (mounted) {
        setState(() {
          _departments = departments;
          _sections = sections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load departments and sections: ${e.toString()}');
      }
    }
  }
  
  // Save course
  Future<void> _saveCourse() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check department and section selection
    if (_selectedDepartmentId == null) {
      showErrorSnackbar(context, 'Please select a department');
      return;
    }
    
    if (_selectedSectionId == null) {
      showErrorSnackbar(context, 'Please select a section');
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
      
      // Check if course code already exists
      final existingCourse = await dbHelper.query(
        DBConstants.coursesTable,
        where: 'code = ? AND instituteId = ?',
        whereArgs: [_codeController.text, instituteId],
      );
      
      if (existingCourse.isNotEmpty) {
        throw Exception('A course with this code already exists');
      }
      
      // Insert course
      await dbHelper.insert(
        DBConstants.coursesTable,
        {
          'name': _nameController.text,
          'code': _codeController.text,
          'description': _descriptionController.text,
          'creditHours': double.parse(_creditHoursController.text),
          'schedule': _scheduleController.text,
          'departmentId': _selectedDepartmentId,
          'sectionId': _selectedSectionId,
          'instituteId': instituteId,
          'active': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
      );
      
      if (mounted) {
        showSuccessSnackbar(context, 'Course created successfully');
        
        // Navigate back to course list
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
        title: const Text('Create Course'),
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
                    // Course information section
                    Text(
                      'Course Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Course name
                    CustomTextField(
                      controller: _nameController,
                      label: 'Course Name',
                      hint: 'Enter course name',
                      prefixIcon: Icons.book,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Course code
                    CustomTextField(
                      controller: _codeController,
                      label: 'Course Code',
                      hint: 'Enter course code',
                      prefixIcon: Icons.code,
                      validator: Validators.courseCode,
                    ),
                    const SizedBox(height: 16),
                    
                    // Department dropdown
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      hint: const Text('Select Department'),
                      value: _selectedDepartmentId,
                      items: _departments.map((department) {
                        return DropdownMenuItem<int>(
                          value: department['id'],
                          child: Text(department['name']),
                        );
                      }).toList(),
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
                    
                    // Section dropdown
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Section',
                        prefixIcon: const Icon(Icons.group),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      hint: const Text('Select Section'),
                      value: _selectedSectionId,
                      items: _sections.map((section) {
                        return DropdownMenuItem<int>(
                          value: section['id'],
                          child: Text(section['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSectionId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a section';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Credit hours
                    CustomTextField(
                      controller: _creditHoursController,
                      label: 'Credit Hours',
                      hint: 'Enter credit hours',
                      prefixIcon: Icons.calculate,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Schedule
                    CustomTextField(
                      controller: _scheduleController,
                      label: 'Schedule (Optional)',
                      hint: 'Enter course schedule',
                      prefixIcon: Icons.schedule,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Course description
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Enter course description',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Create Course',
                        icon: Icons.save,
                        isLoading: _isSaving,
                        onPressed: _saveCourse,
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