import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];
  String _searchQuery = '';
  
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load courses
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Load all courses
      final courses = await dbHelper.query(
        DBConstants.coursesTable,
        where: 'active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
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
  
  // Filter courses by search query
  void _filterCourses() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }
  
  // Toggle course status
  Future<void> _toggleCourseStatus(Map<String, dynamic> course) async {
    final currentStatus = course['active'] == 1;
    final newStatus = !currentStatus;
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Update course status
      await dbHelper.update(
        DBConstants.coursesTable,
        {
          'active': newStatus ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
        where: 'id = ?',
        whereArgs: [course['id']],
      );
      
      if (mounted) {
        // Refresh the list
        _loadCourses();
        
        showSuccessSnackbar(
          context,
          'Course ${newStatus ? 'activated' : 'deactivated'} successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to update course status: ${e.toString()}');
      }
    }
  }
  
  // Build course list item
  Widget _buildCourseItem(Map<String, dynamic> course) {
    final name = course['name'];
    final code = course['code'];
    final isActive = course['active'] == 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Course icon
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                name.substring(0, 1),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Course info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Code: $code',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            // Status and actions
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        color: isActive ? Colors.red : Colors.green,
                      ),
                      onPressed: () => _toggleCourseStatus(course),
                      tooltip: isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Navigate to edit course screen
                        // This would be implemented in a real app
                        showSuccessSnackbar(context, 'Edit course functionality would be implemented in a real app');
                      },
                      color: Colors.blue,
                      tooltip: 'Edit',
                    ),
                  ],
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
    // Filter courses based on search query
    final filteredCourses = _searchQuery.isEmpty
        ? _courses
        : _courses.where((course) {
            final name = course['name'].toString().toLowerCase();
            final code = course['code'].toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            
            return name.contains(query) || code.contains(query);
          }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
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
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _filterCourses(),
            ),
          ),
          
          // Course count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredCourses.length} course${filteredCourses.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Course list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.library_books_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No courses found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new course to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredCourses.length,
                        itemBuilder: (context, index) {
                          return _buildCourseItem(filteredCourses[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createCourse);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}