import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../config/constants.dart';
import '../../../config/themes.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/biometrics/biometric_service.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/snackbar_utils.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isVerifying = false;
  
  // Attendance records map
  Map<int, String> _attendanceStatus = {};
  Map<int, bool> _fingerprintVerified = {};
  
  final _uuid = Uuid();
  
  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  // Load teacher's courses
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get teacher ID
      final teacherId = authProvider.userId;
      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }
      
      // Query courses assigned to this teacher
      final courses = await dbHelper.query(
        DBConstants.coursesTable,
        where: 'teacherId = ?',
        whereArgs: [teacherId],
      );
      
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load courses: ${e.toString()}');
      }
    }
  }
  
  // Load students for selected course
  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;
    
    setState(() {
      _isLoading = true;
      _students = [];
      _attendanceStatus = {};
      _fingerprintVerified = {};
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Get course ID
      final courseId = _selectedCourse!['id'];
      
      // Get students enrolled in this course
      final students = await dbHelper.rawQuery('''
        SELECT s.*, sc.enrollmentDate, sc.status as enrollmentStatus
        FROM ${DBConstants.studentsTable} s
        JOIN student_course sc ON s.id = sc.studentId
        WHERE sc.courseId = ? AND s.active = 1
        ORDER BY s.firstName ASC, s.lastName ASC
      ''', [courseId]);
      
      // Check for existing attendance records for today
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final existingAttendance = await dbHelper.query(
        DBConstants.attendanceTable,
        where: 'courseId = ? AND date = ?',
        whereArgs: [courseId, dateString],
      );
      
      // Initialize attendance status map with existing data or 'Present' by default
      final attendanceMap = <int, String>{};
      final fingerprintMap = <int, bool>{};
      
      for (final student in students) {
        final studentId = student['id'];
        final existingRecord = existingAttendance.firstWhere(
          (record) => record['studentId'] == studentId,
          orElse: () => {},
        );
        
        if (existingRecord.isNotEmpty) {
          attendanceMap[studentId] = existingRecord['status'];
          fingerprintMap[studentId] = existingRecord['fingerprintVerified'] == 1;
        } else {
          attendanceMap[studentId] = 'Present';
          fingerprintMap[studentId] = false;
        }
      }
      
      if (mounted) {
        setState(() {
          _students = students;
          _attendanceStatus = attendanceMap;
          _fingerprintVerified = fingerprintMap;
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
  
  // Save attendance records
  Future<void> _saveAttendance() async {
    if (_selectedCourse == null || _students.isEmpty) {
      showErrorSnackbar(context, 'No students to record attendance for');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get IDs
      final courseId = _selectedCourse!['id'];
      final teacherId = authProvider.userId;
      final instituteId = authProvider.instituteId;
      
      if (teacherId == null || instituteId == null) {
        throw Exception('User information is incomplete');
      }
      
      // Format date
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeString = DateFormat('HH:mm:ss').format(DateTime.now());
      
      for (final student in _students) {
        final studentId = student['id'];
        final status = _attendanceStatus[studentId] ?? 'Present';
        final fingerprintVerified = _fingerprintVerified[studentId] ?? false;
        
        // Check if record already exists
        final existingRecord = await dbHelper.query(
          DBConstants.attendanceTable,
          where: 'studentId = ? AND courseId = ? AND date = ?',
          whereArgs: [studentId, courseId, dateString],
        );
        
        if (existingRecord.isNotEmpty) {
          // Update existing record
          await dbHelper.update(
            DBConstants.attendanceTable,
            {
              'status': status,
              'fingerprintVerified': fingerprintVerified ? 1 : 0,
              'updatedAt': DateTime.now().toIso8601String(),
              'synced': 0, // Mark as needing sync
            },
            where: 'id = ?',
            whereArgs: [existingRecord.first['id']],
          );
        } else {
          // Create new record
          final offlineId = _uuid.v4();
          await dbHelper.insert(
            DBConstants.attendanceTable,
            {
              'offlineId': offlineId,
              'studentId': studentId,
              'courseId': courseId,
              'teacherId': teacherId,
              'instituteId': instituteId,
              'date': dateString,
              'status': status,
              'timeIn': timeString,
              'fingerprintVerified': fingerprintVerified ? 1 : 0,
              'verified': 1,
              'syncedFromOffline': 0,
              'createdAt': DateTime.now().toIso8601String(),
              'synced': 0,
            },
          );
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSuccessSnackbar(context, 'Attendance saved successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to save attendance: ${e.toString()}');
      }
    }
  }
  
  // Verify fingerprint for a student
  Future<void> _verifyFingerprint(int studentId) async {
    if (_isVerifying) return;
    
    setState(() {
      _isVerifying = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final biometricService = Provider.of<BiometricService>(context, listen: false);
      
      // Get student fingerprint template
      final student = await dbHelper.getById(DBConstants.studentsTable, studentId);
      
      if (student == null) {
        throw Exception('Student not found');
      }
      
      if (student['fingerprint'] == null) {
        throw Exception('No fingerprint registered for this student');
      }
      
      // Verify fingerprint
      final result = await biometricService.verifyFingerprint(
        studentId: studentId.toString(),
        storedTemplate: student['fingerprint'],
      );
      
      if (mounted) {
        if (result['verified']) {
          setState(() {
            _fingerprintVerified[studentId] = true;
          });
          showSuccessSnackbar(context, 'Fingerprint verified successfully');
        } else {
          showErrorSnackbar(context, 'Fingerprint verification failed');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Course selector and date picker
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Course dropdown
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCourse,
                      items: _courses.map((course) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: course,
                          child: Text('${course['name']} (${course['code']})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourse = value;
                        });
                        _loadStudents();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Date picker
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now(),
                        );
                        
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                          _loadStudents();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Students list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? Center(
                          child: Text(
                            _selectedCourse == null
                                ? 'Please select a course'
                                : 'No students found for this course',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final studentId = student['id'];
                            final fullName = '${student['firstName']} ${student['lastName']}';
                            final regNumber = student['registrationNumber'];
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
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
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              // Fingerprint verification status
                                              Icon(
                                                _fingerprintVerified[studentId] ?? false
                                                    ? Icons.verified_user
                                                    : Icons.fingerprint,
                                                color: _fingerprintVerified[studentId] ?? false
                                                    ? Colors.green
                                                    : Colors.grey,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _fingerprintVerified[studentId] ?? false
                                                    ? 'Verified'
                                                    : 'Not Verified',
                                                style: TextStyle(
                                                  color: _fingerprintVerified[studentId] ?? false
                                                      ? Colors.green
                                                      : Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Attendance status selection
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        DropdownButton<String>(
                                          value: _attendanceStatus[studentId] ?? 'Present',
                                          items: ['Present', 'Late', 'Absent'].map((status) {
                                            return DropdownMenuItem<String>(
                                              value: status,
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  color: status == 'Present'
                                                      ? AppTheme.presentColor
                                                      : status == 'Late'
                                                          ? AppTheme.lateColor
                                                          : AppTheme.absentColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _attendanceStatus[studentId] = value;
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Fingerprint button
                                        TextButton.icon(
                                          onPressed: (_isVerifying || (_fingerprintVerified[studentId] ?? false))
                                              ? null
                                              : () => _verifyFingerprint(studentId),
                                          icon: Icon(
                                            Icons.fingerprint,
                                            color: _fingerprintVerified[studentId] ?? false
                                                ? Colors.green
                                                : Theme.of(context).primaryColor,
                                          ),
                                          label: Text(
                                            _fingerprintVerified[studentId] ?? false
                                                ? 'Verified'
                                                : 'Verify',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            // Save button
            if (_students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  label: 'Save Attendance',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: _saveAttendance,
                ),
              ),
          ],
        ),
      ),
    );
  }
}