import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _departments = [];
  String _searchQuery = '';
  
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load departments
  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Load all departments
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
  
  // Filter departments by search query
  void _filterDepartments() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }
  
  // Toggle department status
  Future<void> _toggleDepartmentStatus(Map<String, dynamic> department) async {
    final currentStatus = department['active'] == 1;
    final newStatus = !currentStatus;
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Update department status
      await dbHelper.update(
        DBConstants.departmentsTable,
        {
          'active': newStatus ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
        where: 'id = ?',
        whereArgs: [department['id']],
      );
      
      if (mounted) {
        // Refresh the list
        _loadDepartments();
        
        showSuccessSnackbar(
          context,
          'Department ${newStatus ? 'activated' : 'deactivated'} successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to update department status: ${e.toString()}');
      }
    }
  }
  
  // Build department list item
  Widget _buildDepartmentItem(Map<String, dynamic> department) {
    final name = department['name'];
    final code = department['code'];
    final isActive = department['active'] == 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Department icon
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
            
            // Department info
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
                      onPressed: () => _toggleDepartmentStatus(department),
                      tooltip: isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Navigate to edit department screen
                        // This would be implemented in a real app
                        showSuccessSnackbar(context, 'Edit department functionality would be implemented in a real app');
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
    // Filter departments based on search query
    final filteredDepartments = _searchQuery.isEmpty
        ? _departments
        : _departments.where((department) {
            final name = department['name'].toString().toLowerCase();
            final code = department['code'].toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            
            return name.contains(query) || code.contains(query);
          }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartments,
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
                hintText: 'Search departments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _filterDepartments(),
            ),
          ),
          
          // Department count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredDepartments.length} department${filteredDepartments.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Department list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDepartments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No departments found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new department to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDepartments.length,
                        itemBuilder: (context, index) {
                          return _buildDepartmentItem(filteredDepartments[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createDepartment);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
