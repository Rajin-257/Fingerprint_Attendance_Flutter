import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  
  DateTime? _dateOfBirth;
  String _gender = 'Male';
  int? _selectedDepartmentId;
  int? _selectedSectionId;
  List<int> _selectedCourseIds = [];
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Data lists
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _courses = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _regNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  // Load departments, sections, and courses
  Future<void> _loadData() async {
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
      
      // Load departments
      final departments = await dbHelper.query(
        DBConstants.departmentsTable,
        where: 'instituteId = ? AND active = ?',
        whereArgs: [instituteId, 1],
        orderBy: 'name ASC',
      );
      
      // Load teacher's courses
      final teacherId = authProvider.userId;
      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }
      
      final courses = await dbHelper.query(
        DBConstants.coursesTable,
        where: 'teacherId = ? AND active = ?',
        whereArgs: [teacherId, 1],
        orderBy: 'name ASC',
      );
      
      if (mounted) {
        setState(() {
          _departments = departments;
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load data: ${e.toString()}');
      }
    }
  }
  
  // Load sections for selected department
  Future<void> _loadSections() async {
    if (_selectedDepartmentId == null) {
      setState(() {
        _sections = [];
        _selectedSectionId = null;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Load sections for selected department
      final sections = await dbHelper.query(
        DBConstants.sectionsTable,
        where: 'departmentId = ? AND active = ?',
        whereArgs: [_selectedDepartmentId, 1],
        orderBy: 'name ASC',
      );
      
      if (mounted) {
        setState(() {
          _sections = sections;
          _selectedSectionId = sections.isNotEmpty ? sections[0]['id'] : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load sections: ${e.toString()}');
      }
    }
  }
  
  // Save student data
  Future<void> _saveStudent() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDepartmentId == null) {
      showErrorSnackbar(context, 'Please select a department');
      return;
    }
    
    if (_selectedSectionId == null) {
      showErrorSnackbar(context, 'Please select a section');
      return;
    }
    
    if (_selectedCourseIds.isEmpty) {
      showErrorSnackbar(context, 'Please select at least one course');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final instituteId = authProvider.instituteId;
      final teacherId = authProvider.userId;
      
      if (instituteId == null || teacherId == null) {
        throw Exception('User information is incomplete');
      }
      
      // Check if registration number already exists
      final existingStudent = await dbHelper.query(
        DBConstants.studentsTable,
        where: 'registrationNumber = ? AND instituteId = ?',
        whereArgs: [_regNumberController.text, instituteId],
      );
      
      if (existingStudent.isNotEmpty) {
        throw Exception('A student with this registration number already exists');
      }
      
      // Start transaction
      await dbHelper.transaction((txn) async {
        // Insert student
        final studentId = await txn.insert(
          DBConstants.studentsTable,
          {
            'registrationNumber': _regNumberController.text,
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
            'email': _emailController.text,
            'dateOfBirth': _dateOfBirth != null
                ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                : null,
            'gender': _gender,
            'contactNumber': _contactNumberController.text,
            'address': _addressController.text,
            'active': 1,
            'instituteId': instituteId,
            'departmentId': _selectedDepartmentId,
            'sectionId': _selectedSectionId,
            'addedBy': teacherId,
            'createdAt': DateTime.now().toIso8601String(),
            'synced': 0, // Mark for sync
          },
        );
        
        // Insert course enrollments
        for (final courseId in _selectedCourseIds) {
          await txn.insert(
            'student_course',
            {
              'studentId': studentId,
              'courseId': courseId,
              'enrollmentDate': DateTime.now().toIso8601String(),
              'status': 'Active',
              'createdAt': DateTime.now().toIso8601String(),
              'synced': 0, // Mark for sync
            },
          );
        }
        
        return studentId;
      });
      
      if (mounted) {
        showSuccessSnackbar(context, 'Student created successfully');
        
        // Ask if user wants to register fingerprint now
        final registerFingerprint = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Register Fingerprint'),
            content: const Text(
              'Do you want to register the student\'s fingerprint now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Register Now'),
              ),
            ],
          ),
        );
        
        if (registerFingerprint == true) {
          // Get the newly created student
          final student = await dbHelper.query(
            DBConstants.studentsTable,
            where: 'registrationNumber = ? AND instituteId = ?',
            whereArgs: [_regNumberController.text, instituteId],
          );
          
          if (student.isNotEmpty) {
            // Navigate to fingerprint registration screen
            if (mounted) {
              Navigator.pushNamed(
                context,
                AppRoutes.registerFingerprint,
                arguments: {
                  'student': student.first,
                },
              );
            }
          }
        } else {
          // Go back to student list
          if (mounted) {
            Navigator.pop(context);
          }
        }
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
        title: const Text('Create Student'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic information section
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Registration number
                      CustomTextField(
                        controller: _regNumberController,
                        label: 'Registration Number',
                        hint: 'Enter student registration number',
                        prefixIcon: Icons.pin,
                        validator: Validators.registrationNumber,
                      ),
                      const SizedBox(height: 16),
                      
                      // First name
                      CustomTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hint: 'Enter student first name',
                        prefixIcon: Icons.person,
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 16),
                      
                      // Last name
                      CustomTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Enter student last name',
                        prefixIcon: Icons.person,
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 16),
                      
                      // Email (optional)
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email (Optional)',
                        hint: 'Enter student email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // Email is optional
                          }
                          return Validators.email(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date of birth and gender
                      Row(
                        children: [
                          // Date of birth
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
                                  lastDate: DateTime.now(),
                                );
                                
                                if (picked != null) {
                                  setState(() {
                                    _dateOfBirth = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date of Birth (Optional)',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _dateOfBirth != null
                                      ? DateFormat('MMM dd, yyyy').format(_dateOfBirth!)
                                      : 'Select Date',
                                  style: TextStyle(
                                    color: _dateOfBirth != null
                                        ? Theme.of(context).textTheme.bodyLarge?.color
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Gender
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              value: _gender,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _gender = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Contact number (optional)
                      CustomTextField(
                        controller: _contactNumberController,
                        label: 'Contact Number (Optional)',
                        hint: 'Enter contact number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      
                      // Address (optional)
                      CustomTextField(
                        controller: _addressController,
                        label: 'Address (Optional)',
                        hint: 'Enter address',
                        prefixIcon: Icons.home,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                      
                      // Academic information section
                      Text(
                        'Academic Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Department
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDepartmentId,
                        items: _departments.map((department) {
                          return DropdownMenuItem<int>(
                            value: department['id'],
                            child: Text('${department['name']} (${department['code']})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                          });
                          _loadSections();
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Section
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSectionId,
                        items: _sections.map((section) {
                          return DropdownMenuItem<int>(
                            value: section['id'],
                            child: Text('${section['name']} (${section['code']})'),
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
                      
                      // Courses
                      Text(
                        'Courses',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      // Course selection
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            if (_courses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No courses available. You can only enroll students in courses assigned to you.'),
                              )
                            else
                              ..._courses.map((course) {
                                final courseId = course['id'];
                                final isSelected = _selectedCourseIds.contains(courseId);
                                
                                return CheckboxListTile(
                                  title: Text('${course['name']}'),
                                  subtitle: Text('${course['code']}'),
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedCourseIds.add(courseId);
                                      } else {
                                        _selectedCourseIds.remove(courseId);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'Create Student',
                          icon: Icons.save,
                          isLoading: _isSaving,
                          onPressed: _saveStudent,
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
      ),
    );
  }
}
