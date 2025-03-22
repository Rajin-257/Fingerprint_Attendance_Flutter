import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../config/constants.dart';
import '../../../core/offline/sync_service.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/snackbar_utils.dart';

class SyncDataScreen extends StatefulWidget {
  const SyncDataScreen({super.key});

  @override
  State<SyncDataScreen> createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends State<SyncDataScreen> {
  bool _isLoading = false;
  String _lastSyncTime = 'Never';
  bool _isConnected = true;
  int _pendingStudents = 0;
  int _pendingFingerprints = 0;
  int _pendingAttendance = 0;
  double _syncProgress = 0.0;
  String _syncStatus = '';
  
  StreamSubscription? _syncProgressSubscription;
  StreamSubscription? _syncStatusSubscription;
  StreamSubscription? _syncMessageSubscription;
  StreamSubscription? _connectivitySubscription;
  
  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadSyncStatus();
    _setupSyncListeners();
  }
  
  @override
  void dispose() {
    _syncProgressSubscription?.cancel();
    _syncStatusSubscription?.cancel();
    _syncMessageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  // Check connectivity
  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }
  
  // Load sync status
  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Get last sync time
      final lastSync = await syncService.getLastSyncTime();
      
      // Count unsynced records
      final unsyncedStudents = await dbHelper.count(
        DBConstants.studentsTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      final unsyncedFingerprints = await dbHelper.count(
        DBConstants.fingerprintsTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      final unsyncedAttendance = await dbHelper.count(
        DBConstants.attendanceTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      if (mounted) {
        setState(() {
          if (lastSync != null) {
            final dateTime = DateTime.parse(lastSync);
            _lastSyncTime = DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
          } else {
            _lastSyncTime = 'Never';
          }
          
          _pendingStudents = unsyncedStudents;
          _pendingFingerprints = unsyncedFingerprints;
          _pendingAttendance = unsyncedAttendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load sync status: ${e.toString()}');
      }
    }
  }
  
  // Setup listeners for sync status updates
  void _setupSyncListeners() {
    final syncService = Provider.of<SyncService>(context, listen: false);
    
    _syncProgressSubscription = syncService.syncProgressStream.listen((progress) {
      setState(() {
        _syncProgress = progress;
      });
    });
    
    _syncStatusSubscription = syncService.syncStatusStream.listen((status) {
      setState(() {
        switch (status) {
          case SyncStatus.idle:
            _syncStatus = 'Idle';
            break;
          case SyncStatus.syncing:
            _syncStatus = 'Syncing';
            break;
          case SyncStatus.completed:
            _syncStatus = 'Completed';
            _loadSyncStatus(); // Refresh counts
            break;
          case SyncStatus.failed:
            _syncStatus = 'Failed';
            break;
        }
      });
    });
    
    _syncMessageSubscription = syncService.syncMessageStream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        
        if (_syncStatus == 'Syncing') {
          showLoadingSnackbar(context, message);
        } else if (_syncStatus == 'Completed') {
          showSuccessSnackbar(context, message);
        } else if (_syncStatus == 'Failed') {
          showErrorSnackbar(context, message);
        }
      }
    });
  }
  
  // Sync data
  Future<void> _syncData() async {
    if (!_isConnected) {
      showErrorSnackbar(context, MessageConstants.noInternet);
      return;
    }
    
    final syncService = Provider.of<SyncService>(context, listen: false);
    await syncService.syncAll();
  }
  
  // Toggle offline mode
  Future<void> _toggleOfflineMode() async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    
    // If turning off offline mode and there's connection, ask if user wants to sync
    if (syncService.isOfflineMode && _isConnected) {
      final shouldSync = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sync Data'),
          content: const Text(
            'You are turning off offline mode. Do you want to sync your data now?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      
      if (shouldSync == true && mounted) {
        await _syncData();
      }
    }
    
    await syncService.setOfflineMode(!syncService.isOfflineMode);
    
    if (mounted) {
      setState(() {}); // Refresh UI
      showInfoSnackbar(
        context,
        syncService.isOfflineMode
            ? 'Offline mode enabled. Data will be stored locally.'
            : 'Offline mode disabled. Data will be synced when possible.',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<SyncService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Data'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connectivity status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isConnected ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isConnected ? Colors.green : Colors.red,
                                ),
                              ),
                              Text(
                                _isConnected
                                    ? 'You can sync your data with the server'
                                    : 'Connect to a network to sync data',
                                style: TextStyle(
                                  color: _isConnected
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Offline mode toggle
                  SwitchListTile(
                    title: const Text('Offline Mode'),
                    subtitle: Text(
                      syncService.isOfflineMode
                          ? 'Enabled - Data is stored locally only'
                          : 'Disabled - Data will sync when possible',
                    ),
                    value: syncService.isOfflineMode,
                    onChanged: (_) => _toggleOfflineMode(),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(),
                  
                  // Sync status
                  ListTile(
                    title: const Text('Last Sync'),
                    subtitle: Text(_lastSyncTime),
                    leading: const Icon(Icons.access_time),
                  ),
                  
                  // Pending items count
                  ListTile(
                    title: const Text('Pending Items'),
                    subtitle: Text(
                      'Students: $_pendingStudents, '
                      'Fingerprints: $_pendingFingerprints, '
                      'Attendance: $_pendingAttendance',
                    ),
                    leading: const Icon(Icons.pending_actions),
                  ),
                  const SizedBox(height: 24),
                  
                  // Sync progress
                  if (_syncStatus == 'Syncing') ...[
                    Text(
                      'Sync Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _syncProgress,
                      backgroundColor: Colors.grey[300],
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_syncProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Sync button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: 'Sync Now',
                      icon: Icons.sync,
                      isLoading: _syncStatus == 'Syncing',
                      onPressed: _syncData,
                      color: _isConnected ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Information card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'About Data Synchronization',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Data synchronization ensures that your local data is backed up to the '
                            'server and available on other devices. When you\'re offline, your data '
                            'is stored locally and will be synchronized when you reconnect.',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sync Process:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            '• Student data syncs first\n'
                            '• Fingerprint templates sync second\n'
                            '• Attendance records sync last\n'
                            '• Failed items will be retried automatically',
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
}