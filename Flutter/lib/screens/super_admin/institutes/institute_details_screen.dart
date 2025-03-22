import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/snackbar_utils.dart';

class InstituteDetailsScreen extends StatefulWidget {
  const InstituteDetailsScreen({super.key});

  @override
  State<InstituteDetailsScreen> createState() => _InstituteDetailsScreenState();
}

class _InstituteDetailsScreenState extends State<InstituteDetailsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _institute;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  
  @override
  void initState() {
    super.initState();
    // Load data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  // Load institute data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args == null || args is! Map<String, dynamic>) {
        throw Exception('Invalid institute data');
      }
      
      _institute = args;
      final instituteId = _institute!['id'];
      
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Load departments
      final departments = await dbHelper.query(
        DBConstants.departmentsTable,
        where: 'instituteId = ? AND active = ?',
        whereArgs: [instituteId, 1],
        orderBy: 'name ASC',
      );
      
      // Load teachers
      final teachers = await dbHelper.query(
        DBConstants.teachersTable,
        where: 'instituteId = ? AND active = ?',
        whereArgs: [instituteId, 1],
        orderBy: 'name ASC',
      );
      
      // Load students
      final students = await dbHelper.query(
        DBConstants.studentsTable,
        where: 'instituteId = ? AND active = ?',
        whereArgs: [instituteId, 1],
        orderBy: 'firstName ASC, lastName ASC',
      );
      
      if (mounted) {
        setState(() {
          _departments = departments;
          _teachers = teachers;
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load institute data: ${e.toString()}');
      }
    }
  }
  
  // Toggle institute status
  Future<void> _toggleInstituteStatus() async {
    if (_institute == null) return;
    
    final currentStatus = _institute!['active'] == 1;
    final newStatus = !currentStatus;
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Update institute status
      await dbHelper.update(
        'institutes',
        {
          'active': newStatus ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
        where: 'id = ?',
        whereArgs: [_institute!['id']],
      );
      
      if (mounted) {
        setState(() {
          _institute!['active'] = newStatus ? 1 : 0;
        });
        
        showSuccessSnackbar(
          context,
          'Institute ${newStatus ? 'activated' : 'deactivated'} successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to update institute status: ${e.toString()}');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_institute == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Institute Details'),
        ),
        body: const Center(
          child: Text('No institute data provided'),
        ),
      );
    }
    
    final name = _institute!['name'];
    final code = _institute!['code'];
    final email = _institute!['email'];
    final phone = _institute!['phone'];
    final address = _institute!['address'];
    final isActive = _institute!['active'] == 1;
    final createdAt = _institute!['createdAt'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(_institute!['createdAt']))
        : 'Unknown';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Institute: $name'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Institute header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          name.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              'Code: $code',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Institute details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Institute Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Email
                          _buildDetailRow(
                            context,
                            icon: Icons.email,
                            label: 'Email',
                            value: email,
                          ),
                          const SizedBox(height: 12),
                          
                          // Phone
                          _buildDetailRow(
                            context,
                            icon: Icons.phone,
                            label: 'Phone',
                            value: phone,
                          ),
                          const SizedBox(height: 12),
                          
                          // Address
                          _buildDetailRow(
                            context,
                            icon: Icons.location_on,
                            label: 'Address',
                            value: address,
                          ),
                          const SizedBox(height: 12),
                          
                          // Created at
                          _buildDetailRow(
                            context,
                            icon: Icons.calendar_today,
                            label: 'Created',
                            value: createdAt,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                context,
                                icon: Icons.business,
                                label: 'Departments',
                                value: _departments.length.toString(),
                                color: Colors.blue,
                              ),
                              _buildStatCard(
                                context,
                                icon: Icons.person,
                                label: 'Teachers',
                                value: _teachers.length.toString(),
                                color: Colors.green,
                              ),
                              _buildStatCard(
                                context,
                                icon: Icons.school,
                                label: 'Students',
                                value: _students.length.toString(),
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: isActive ? 'Deactivate Institute' : 'Activate Institute',
                          icon: isActive ? Icons.block : Icons.check_circle,
                          onPressed: _toggleInstituteStatus,
                          isOutlined: isActive,
                          color: isActive ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
