import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../config/constants.dart';
import '../../../config/themes.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _attendance = [];
  int? _selectedCourseId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
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
      
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
        
        // If there's at least one course, select it and load attendance
        if (courses.isNotEmpty) {
          setState(() {
            _selectedCourseId = courses.first['id'];
          });
          _loadAttendance();
        }
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
  
  // Load attendance records for the selected course
  Future<void> _loadAttendance() async {
    if (_selectedCourseId == null) return;
    
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
      
      // Format dates for SQL query
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);
      
      // Get attendance records
      final attendanceRecords = await dbHelper.rawQuery('''
        SELECT 
          a.id, a.date, a.status, a.timeIn, a.fingerprintVerified, a.synced,
          s.id as studentId, s.firstName, s.lastName, s.registrationNumber,
          c.id as courseId, c.name as courseName, c.code as courseCode
        FROM ${DBConstants.attendanceTable} a
        JOIN ${DBConstants.studentsTable} s ON a.studentId = s.id
        JOIN ${DBConstants.coursesTable} c ON a.courseId = c.id
        WHERE a.teacherId = ? AND a.courseId = ? AND a.date BETWEEN ? AND ?
        ORDER BY a.date DESC, s.firstName ASC, s.lastName ASC
      ''', [teacherId, _selectedCourseId, startDateStr, endDateStr]);
      
      if (mounted) {
        setState(() {
          _attendance = attendanceRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load attendance: ${e.toString()}');
      }
    }
  }
  
  // Group attendance records by date
  Map<String, List<Map<String, dynamic>>> _groupAttendanceByDate() {
    final groupedAttendance = <String, List<Map<String, dynamic>>>{};
    
    for (final record in _attendance) {
      final date = record['date'];
      if (!groupedAttendance.containsKey(date)) {
        groupedAttendance[date] = [];
      }
      groupedAttendance[date]!.add(record);
    }
    
    return groupedAttendance;
  }
  
  // Calculate attendance statistics for a date
  Map<String, int> _calculateStats(List<Map<String, dynamic>> records) {
    final stats = {'Present': 0, 'Late': 0, 'Absent': 0};
    
    for (final record in records) {
      final status = record['status'];
      stats[status] = (stats[status] ?? 0) + 1;
    }
    
    return stats;
  }
  
  // Select date range
  Future<void> _selectDateRange() async {
    final initialDateRange = DateTimeRange(
      start: _startDate,
      end: _endDate,
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
      _loadAttendance();
    }
  }
  
  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return AppTheme.presentColor;
      case 'Late':
        return AppTheme.lateColor;
      case 'Absent':
        return AppTheme.absentColor;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Group attendance records by date
    final groupedAttendance = _groupAttendanceByDate();
    final dateKeys = groupedAttendance.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Column(
        children: [
          // Course selection and date range
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Course dropdown
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCourseId,
                  items: _courses.map((course) {
                    return DropdownMenuItem<int>(
                      value: course['id'],
                      child: Text('${course['name']} (${course['code']})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCourseId = value;
                      });
                      _loadAttendance();
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Date range selection
                InkWell(
                  onTap: _selectDateRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Range',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    child: Text(
                      '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Attendance records
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendance.isEmpty
                    ? const Center(
                        child: Text('No attendance records found for the selected criteria'),
                      )
                    : ListView.builder(
                        itemCount: dateKeys.length,
                        itemBuilder: (context, index) {
                          final date = dateKeys[index];
                          final records = groupedAttendance[date]!;
                          final stats = _calculateStats(records);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ExpansionTile(
                              title: Text(
                                DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.parse(date)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: AppTheme.presentColor),
                                  Text(' ${stats['Present'] ?? 0} Present, '),
                                  Icon(Icons.watch_later, size: 16, color: AppTheme.lateColor),
                                  Text(' ${stats['Late'] ?? 0} Late, '),
                                  Icon(Icons.person_off, size: 16, color: AppTheme.absentColor),
                                  Text(' ${stats['Absent'] ?? 0} Absent'),
                                ],
                              ),
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: records.length,
                                  itemBuilder: (context, recordIndex) {
                                    final record = records[recordIndex];
                                    final studentName = '${record['firstName']} ${record['lastName']}';
                                    final regNumber = record['registrationNumber'];
                                    final status = record['status'];
                                    final timeIn = record['timeIn'] != null
                                        ? TimeOfDay.fromDateTime(
                                            DateFormat('HH:mm:ss').parse(record['timeIn']),
                                          ).format(context)
                                        : '-';
                                    
                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: _getStatusColor(status),
                                        child: Icon(
                                          status == 'Present'
                                              ? Icons.check
                                              : status == 'Late'
                                                  ? Icons.watch_later
                                                  : Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      title: Text(studentName),
                                      subtitle: Text(regNumber),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            status,
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            timeIn,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            record['fingerprintVerified'] == 1
                                                ? Icons.verified_user
                                                : Icons.fingerprint,
                                            size: 16,
                                            color: record['fingerprintVerified'] == 1
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            record['synced'] == 1
                                                ? Icons.cloud_done
                                                : Icons.cloud_off,
                                            size: 16,
                                            color: record['synced'] == 1
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}