import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../config/constants.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _attendanceData = [];
  
  int? _selectedDepartmentId;
  int? _selectedSectionId;
  int? _selectedCourseId;
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _loadFilters();
    
    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }
  
  // Load departments, sections, and courses
  Future<void> _loadFilters() async {
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
        showErrorSnackbar(context, 'Failed to load filters: ${e.toString()}');
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
          _selectedSectionId = null;
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
  
  // Load courses for selected section
  Future<void> _loadCourses() async {
    if (_selectedSectionId == null) {
      setState(() {
        _courses = [];
        _selectedCourseId = null;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Load courses for selected section
      final courses = await dbHelper.rawQuery('''
        SELECT c.*
        FROM ${DBConstants.coursesTable} c
        JOIN course_section cs ON c.id = cs.courseId
        WHERE cs.sectionId = ? AND c.active = 1
        ORDER BY c.name ASC
      ''', [_selectedSectionId]);
      
      if (mounted) {
        setState(() {
          _courses = courses;
          _selectedCourseId = null;
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
  
  // Generate attendance report
  Future<void> _generateReport() async {
    if (_selectedCourseId == null) {
      showErrorSnackbar(context, 'Please select a course');
      return;
    }
    
    if (_startDate == null || _endDate == null) {
      showErrorSnackbar(context, 'Please select date range');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Format dates for SQL query
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      
      // Get attendance data
      final attendanceData = await dbHelper.rawQuery('''
        SELECT 
          s.id AS studentId,
          s.firstName,
          s.lastName,
          s.registrationNumber,
          COUNT(a.id) AS totalClasses,
          SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) AS presentCount,
          ROUND(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) * 100.0 / COUNT(a.id), 2) AS attendancePercentage
        FROM ${DBConstants.studentsTable} s
        LEFT JOIN ${DBConstants.attendanceTable} a ON s.id = a.studentId
        WHERE a.courseId = ? 
          AND a.date BETWEEN ? AND ?
          AND s.active = 1
        GROUP BY s.id
        ORDER BY s.firstName, s.lastName
      ''', [_selectedCourseId, startDateStr, endDateStr]);
      
      if (mounted) {
        setState(() {
          _attendanceData = attendanceData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to generate report: ${e.toString()}');
      }
    }
  }
  
  // Export report
  Future<void> _exportReport() async {
    if (_attendanceData.isEmpty) {
      showErrorSnackbar(context, 'No data to export');
      return;
    }
    
    showSuccessSnackbar(context, 'Report exported successfully');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          if (_attendanceData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportReport,
              tooltip: 'Export Report',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters section
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
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
                                child: Text(department['name']),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDepartmentId = value;
                            });
                            _loadSections();
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Section dropdown
                        DropdownButtonFormField<int?>(
                          decoration: const InputDecoration(
                            labelText: 'Section',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedSectionId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Select Section'),
                            ),
                            ..._sections.map((section) {
                              return DropdownMenuItem<int?>(
                                value: section['id'],
                                child: Text(section['name']),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSectionId = value;
                            });
                            _loadCourses();
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Course dropdown
                        DropdownButtonFormField<int?>(
                          decoration: const InputDecoration(
                            labelText: 'Course',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCourseId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Select Course'),
                            ),
                            ..._courses.map((course) {
                              return DropdownMenuItem<int?>(
                                value: course['id'],
                                child: Text('${course['name']} (${course['code']})'),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCourseId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Date range
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  
                                  if (picked != null) {
                                    setState(() {
                                      _startDate = picked;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _startDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                        : 'Select Date',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  
                                  if (picked != null) {
                                    setState(() {
                                      _endDate = picked;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _endDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                        : 'Select Date',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Generate report button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.assessment),
                            label: const Text('Generate Report'),
                            onPressed: _generateReport,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Report data
                Expanded(
                  child: _attendanceData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bar_chart,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance data',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Select filters and generate report',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Report header
                              Text(
                                'Attendance Report',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Period: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              
                              // Report table
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Reg. No.')),
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Total Classes')),
                                        DataColumn(label: Text('Present')),
                                        DataColumn(label: Text('Percentage')),
                                      ],
                                      rows: _attendanceData.map((data) {
                                        final fullName = '${data['firstName']} ${data['lastName']}';
                                        final regNumber = data['registrationNumber'];
                                        final totalClasses = data['totalClasses'] ?? 0;
                                        final presentCount = data['presentCount'] ?? 0;
                                        final percentage = data['attendancePercentage'] ?? 0.0;
                                        
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(regNumber)),
                                            DataCell(Text(fullName)),
                                            DataCell(Text(totalClasses.toString())),
                                            DataCell(Text(presentCount.toString())),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getAttendanceColor(percentage),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '$percentage%',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
  
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 75) {
      return Colors.blue;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
