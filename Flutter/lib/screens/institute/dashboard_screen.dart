import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/auth/auth_provider.dart';
import '../../utils/snackbar_utils.dart';

class InstituteDashboardScreen extends StatefulWidget {
  const InstituteDashboardScreen({super.key});

  @override
  State<InstituteDashboardScreen> createState() => _InstituteDashboardScreenState();
}

class _InstituteDashboardScreenState extends State<InstituteDashboardScreen> {
  // Logout
  Future<void> _logout() async {
    // Logout
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
      showSuccessSnackbar(context, 'Logged out successfully');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userName ?? 'Institute Admin';
    final instituteName = authProvider.instituteName ?? 'Institute';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instituteName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Institute Dashboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Dashboard content
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      context,
                      title: 'Departments',
                      icon: Icons.business,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.departmentList);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Sections',
                      icon: Icons.group_work,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.sectionList);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Courses',
                      icon: Icons.book,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.courseList);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Teachers',
                      icon: Icons.person,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.teacherList);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Attendance Reports',
                      icon: Icons.assessment,
                      color: Colors.red,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.attendanceReport);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Profile',
                      icon: Icons.account_circle,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.instituteProfile);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
