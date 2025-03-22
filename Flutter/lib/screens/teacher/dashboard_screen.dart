import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/offline/sync_service.dart';
import '../../widgets/custom_button.dart';
import '../../utils/snackbar_utils.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool _isOffline = false;
  bool _isSyncing = false;
  String _lastSyncTime = 'Never';
  int _pendingSyncCount = 0;
  
  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _checkSyncStatus();
  }
  
  // Check internet connectivity
  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = result == ConnectivityResult.none;
    });
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() {
          _isOffline = result == ConnectivityResult.none;
        });
        
        if (result != ConnectivityResult.none) {
          _checkSyncStatus();
        }
      }
    });
  }
  
  // Check sync status
  Future<void> _checkSyncStatus() async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    
    // Get last sync time
    final lastSync = await syncService.getLastSyncTime();
    setState(() {
      if (lastSync != null) {
        final dateTime = DateTime.parse(lastSync);
        _lastSyncTime = DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
      } else {
        _lastSyncTime = 'Never';
      }
    });
    
    // Check if sync is needed
    final isSyncNeeded = await syncService.isSyncNeeded();
    if (isSyncNeeded) {
      // TODO: Implement method to count pending sync items
      setState(() {
        _pendingSyncCount = 10; // Placeholder
      });
    } else {
      setState(() {
        _pendingSyncCount = 0;
      });
    }
  }
  
  // Sync data
  Future<void> _syncData() async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    
    // Check internet connectivity
    final isConnected = await Connectivity().checkConnectivity() != ConnectivityResult.none;
    if (!isConnected) {
      showErrorSnackbar(context, MessageConstants.noInternet);
      return;
    }
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final success = await syncService.syncAll();
      
      if (mounted) {
        if (success) {
          showSuccessSnackbar(context, MessageConstants.syncSuccessful);
          _checkSyncStatus();
        } else {
          showErrorSnackbar(context, MessageConstants.syncError);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
  
  // Logout
  Future<void> _logout() async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    final isSyncNeeded = await syncService.isSyncNeeded();
    
    if (isSyncNeeded) {
      // Show warning dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsynchronized Data'),
          content: const Text(
            'You have unsynchronized data. If you logout now, '
            'some data may not be synchronized with the server. '
            'Do you want to sync before logging out?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Logout Anyway'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sync Data'),
            ),
          ],
        ),
      );
      
      if (shouldLogout == true) {
        // Sync data before logout
        await _syncData();
        return;
      }
    }
    
    // Logout
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
      showSuccessSnackbar(context, MessageConstants.logoutSuccessful);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userName ?? 'Teacher';
    
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
        child: Column(
          children: [
            // Offline mode indicator
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.orange,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Offline Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Sync status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last sync: $_lastSyncTime',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_pendingSyncCount > 0)
                        Text(
                          'Pending sync: $_pendingSyncCount items',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  CustomButton(
                    label: 'Sync Now',
                    icon: Icons.sync,
                    isLoading: _isSyncing,
                    onPressed: _syncData,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
            
            // Dashboard content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      context,
                      title: 'Take Attendance',
                      icon: Icons.fingerprint,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.takeAttendance);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Students',
                      icon: Icons.people,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.studentList);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Attendance History',
                      icon: Icons.history,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.attendanceHistory);
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Profile',
                      icon: Icons.person,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.teacherProfile);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                color: color.withValues(alpha: (0.2 * 255).round().toDouble()),
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