import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/local/database_helper.dart';
import '../../../utils/snackbar_utils.dart';

class SectionListScreen extends StatefulWidget {
  const SectionListScreen({super.key});

  @override
  State<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends State<SectionListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _departments = [];
  String _searchQuery = '';
  int? _selectedDepartmentId;
  
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
  
  // Load departments and sections
  Future<void> _loadData() async {
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
      
      // Load all sections
      final sections = await dbHelper.query(
        DBConstants.sectionsTable,
        where: 'active = ?',
        whereArgs: [1],
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
        showErrorSnackbar(context, 'Failed to load data: ${e.toString()}');
      }
    }
  }
  
  // Load sections for selected department
  Future<void> _loadSectionsForDepartment(int? departmentId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      if (departmentId == null) {
        // Load all sections
        final sections = await dbHelper.query(
          DBConstants.sectionsTable,
          where: 'active = ?',
          whereArgs: [1],
          orderBy: 'name ASC',
        );
        
        if (mounted) {
          setState(() {
            _sections = sections;
            _isLoading = false;
          });
        }
      } else {
        // Load sections for selected department
        final sections = await dbHelper.query(
          DBConstants.sectionsTable,
          where: 'departmentId = ? AND active = ?',
          whereArgs: [departmentId, 1],
          orderBy: 'name ASC',
        );
        
        if (mounted) {
          setState(() {
            _sections = sections;
            _isLoading = false;
          });
        }
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
  
  // Filter sections by search query
  void _filterSections() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }
  
  // Toggle section status
  Future<void> _toggleSectionStatus(Map<String, dynamic> section) async {
    final currentStatus = section['active'] == 1;
    final newStatus = !currentStatus;
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Update section status
      await dbHelper.update(
        DBConstants.sectionsTable,
        {
          'active': newStatus ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
        where: 'id = ?',
        whereArgs: [section['id']],
      );
      
      if (mounted) {
        // Refresh the list
        _loadSectionsForDepartment(_selectedDepartmentId);
        
        showSuccessSnackbar(
          context,
          'Section ${newStatus ? 'activated' : 'deactivated'} successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to update section status: ${e.toString()}');
      }
    }
  }
  
  // Get department name by ID
  String _getDepartmentName(int departmentId) {
    final department = _departments.firstWhere(
      (dept) => dept['id'] == departmentId,
      orElse: () => {'name': 'Unknown'},
    );
    
    return department['name'];
  }
  
  // Build section list item
  Widget _buildSectionItem(Map<String, dynamic> section) {
    final name = section['name'];
    final code = section['code'];
    final departmentId = section['departmentId'];
    final departmentName = _getDepartmentName(departmentId);
    final isActive = section['active'] == 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Section icon
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
            
            // Section info
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
                  Text(
                    'Department: $departmentName',
                    style: Theme.of(context).textTheme.bodySmall,
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
                      onPressed: () => _toggleSectionStatus(section),
                      tooltip: isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Navigate to edit section screen
                        // This would be implemented in a real app
                        showSuccessSnackbar(context, 'Edit section functionality would be implemented in a real app');
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
    // Filter sections based on search query
    final filteredSections = _searchQuery.isEmpty
        ? _sections
        : _sections.where((section) {
            final name = section['name'].toString().toLowerCase();
            final code = section['code'].toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            
            return name.contains(query) || code.contains(query);
          }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Department filter
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Department',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDepartmentId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Departments'),
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
                    _loadSectionsForDepartment(value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search sections...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => _filterSections(),
                ),
              ],
            ),
          ),
          
          // Section count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredSections.length} section${filteredSections.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_selectedDepartmentId != null)
                  Text(
                    'Filtered by department',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Section list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.group_work_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sections found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new section to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSections.length,
                        itemBuilder: (context, index) {
                          return _buildSectionItem(filteredSections[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createSection);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
