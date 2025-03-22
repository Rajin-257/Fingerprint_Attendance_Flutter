import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _courses = [];
  int? _selectedCourseId;
  String _searchQuery = '';
  
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final teacherId = authProvider.userId;
      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }
      
      // Load teacher's courses
      final courses = await dbHelper.query(
        DBConstants.coursesTable,
        where: 'teacherId = ? AND active = ?',
        whereArgs: [teacherId, 1],
        orderBy: 'name ASC',
      );
      
      // Load all students added by this teacher
      final students = await dbHelper.query(
        DBConstants.studentsTable,
        where: 'addedBy = ? AND active = ?',
        whereArgs: [teacherId, 1],
        orderBy: 'firstName ASC, lastName ASC',
      );
      
      if (mounted) {
        setState(() {
          _courses = courses;
          _students = students;
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
  
  // Load students for a specific course
  Future<void> _loadStudentsForCourse(int courseId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Get students enrolled in this course
      final students = await dbHelper.rawQuery('''
        SELECT s.*
        FROM ${DBConstants.studentsTable} s
        JOIN student_course sc ON s.id = sc.studentId
        WHERE sc.courseId = ? AND s.active = 1
        ORDER BY s.firstName ASC, s.lastName ASC
      ''', [courseId]);
      
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load students: ${e.toString()}');
      }
    }
  }
  
  // Filter students by search query
  void _filterStudents() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }
  
  // Register fingerprint for a student
  void _registerFingerprint(Map<String, dynamic> student) {
    Navigator.pushNamed(
      context,
      AppRoutes.registerFingerprint,
      arguments: {
        'student': student,
      },
    );
  }
  
  // Build student list item
  Widget _buildStudentItem(Map<String, dynamic> student) {
    final fullName = '${student['firstName']} ${student['lastName']}';
    final regNumber = student['registrationNumber'];
    final hasFingerprint = student['fingerprint'] != null;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Student avatar/icon
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                fullName.substring(0, 1),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    regNumber,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (student['email'] != null && student['email'].toString().isNotEmpty)
                    Text(
                      student['email'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            
            // Fingerprint status and action
            Column(
              children: [
                Icon(
                  hasFingerprint ? Icons.verified_user : Icons.fingerprint,
                  color: hasFingerprint ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  hasFingerprint ? 'Registered' : 'Not Registered',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasFingerprint ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _registerFingerprint(student),
                  child: Text(
                    hasFingerprint ? 'Update' : 'Register',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Filter students based on search query
    final filteredStudents = _searchQuery.isEmpty
        ? _students
        : _students.where((student) {
            final fullName = '${student['firstName']} ${student['lastName']}'.toLowerCase();
            final regNumber = student['registrationNumber'].toLowerCase();
            final query = _searchQuery.toLowerCase();
            
            return fullName.contains(query) || regNumber.contains(query);
          }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Search field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => _filterStudents(),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Course filter dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: 'Filter by Course',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedCourseId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Courses'),
                      ),
                      ..._courses.map((course) {
                        return DropdownMenuItem<int?>(
                          value: course['id'],
                          child: Text(course['code']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCourseId = value;
                      });
                      
                      if (value == null) {
                        _loadData();
                      } else {
                        _loadStudentsForCourse(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Student count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredStudents.length} student${filteredStudents.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_selectedCourseId != null)
                  Text(
                    'Filtered by course',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Student list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No students found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedCourseId != null
                                  ? 'Try selecting a different course'
                                  : 'Create a new student to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          return _buildStudentItem(filteredStudents[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createStudent);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}