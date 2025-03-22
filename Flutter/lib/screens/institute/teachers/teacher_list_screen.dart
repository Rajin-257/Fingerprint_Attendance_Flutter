import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final List<Map<String, dynamic>> _teachers = [];
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load teachers from database
  Future<void> _loadTeachers() async {
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      final teachers = await dbHelper.query(
        DBConstants.teachersTable,
        where: 'active = ?',
        whereArgs: [1],
        orderBy: 'lastName, firstName',
      );

      if (mounted) {
        setState(() {
          _teachers.clear();
          _teachers.addAll(teachers);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load teachers: ${e.toString()}');
      }
    }
  }

  // Filter teachers based on search query
  List<Map<String, dynamic>> _getFilteredTeachers() {
    if (_searchQuery.isEmpty) return _teachers;

    return _teachers.where((teacher) {
      final searchLower = _searchQuery.toLowerCase();
      final fullName = '${teacher['firstName']} ${teacher['lastName']}'.toLowerCase();
      
      return fullName.contains(searchLower) ||
             teacher['email'].toLowerCase().contains(searchLower) ||
             teacher['employeeId'].toLowerCase().contains(searchLower);
    }).toList();
  }

  // Toggle teacher active status
  Future<void> _toggleTeacherStatus(Map<String, dynamic> teacher) async {
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      final currentStatus = teacher['active'] == 1;
      final newStatus = currentStatus ? 0 : 1;

      await dbHelper.update(
        DBConstants.teachersTable,
        {
          'active': newStatus,
          'updatedAt': DateTime.now().toIso8601String(),
          'synced': 0
        },
        where: 'id = ?',
        whereArgs: [teacher['id']],
      );

      // Refresh the list
      await _loadTeachers();

      if (mounted) {
        showSuccessSnackbar(
          context, 
          'Teacher ${newStatus == 1 ? 'activated' : 'deactivated'} successfully'
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to update teacher status: ${e.toString()}');
      }
    }
  }

  // Build individual teacher list item
  Widget _buildTeacherItem(Map<String, dynamic> teacher) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            teacher['firstName'][0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          '${teacher['firstName']} ${teacher['lastName']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee ID: ${teacher['employeeId']}'),
            Text(teacher['email']),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: teacher['active'] == 1 ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                teacher['active'] == 1 ? 'Active' : 'Inactive',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Toggle status button
            IconButton(
              icon: Icon(
                teacher['active'] == 1 ? Icons.block : Icons.check_circle,
                color: teacher['active'] == 1 ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleTeacherStatus(teacher),
              tooltip: teacher['active'] == 1 ? 'Deactivate' : 'Activate',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = _getFilteredTeachers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Teacher count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredTeachers.length} teacher${filteredTeachers.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Teacher list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTeachers.isEmpty
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
                              'No teachers found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new teacher to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTeachers.length,
                        itemBuilder: (context, index) {
                          return _buildTeacherItem(filteredTeachers[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createTeacher);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}