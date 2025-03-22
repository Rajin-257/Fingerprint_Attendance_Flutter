import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/shared_prefs.dart';
import '../../config/constants.dart';
import '../../utils/snackbar_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _isOfflineMode = false;
  bool _isBiometricEnabled = false;
  bool _isNotificationsEnabled = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = Provider.of<SharedPrefs>(context, listen: false);
      
      // Load theme setting
      final themeMode = await prefs.getString(StorageKeys.theme);
      
      // Load offline mode setting
      final offlineMode = await prefs.getBool(StorageKeys.offlineMode);
      
      // Load other settings (these would typically be stored in SharedPreferences)
      final sharedPrefs = await SharedPreferences.getInstance();
      final biometricEnabled = sharedPrefs.getBool('biometric_enabled') ?? false;
      final notificationsEnabled = sharedPrefs.getBool('notifications_enabled') ?? true;
      
      if (mounted) {
        setState(() {
          _isDarkMode = themeMode == 'dark';
          _isOfflineMode = offlineMode ?? false;
          _isBiometricEnabled = biometricEnabled;
          _isNotificationsEnabled = notificationsEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to load settings: ${e.toString()}');
      }
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = Provider.of<SharedPrefs>(context, listen: false);
      
      // Save theme setting
      await prefs.setString(StorageKeys.theme, _isDarkMode ? 'dark' : 'light');
      
      // Save offline mode setting
      await prefs.setBool(StorageKeys.offlineMode, _isOfflineMode);
      
      // Save other settings
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setBool('biometric_enabled', _isBiometricEnabled);
      await sharedPrefs.setBool('notifications_enabled', _isNotificationsEnabled);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSuccessSnackbar(context, 'Settings saved successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Failed to save settings: ${e.toString()}');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // App theme section
                  _buildSectionHeader('Appearance'),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme for the app'),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                      _saveSettings();
                    },
                    secondary: const Icon(Icons.dark_mode),
                  ),
                  const Divider(),
                  
                  // Connectivity section
                  _buildSectionHeader('Connectivity'),
                  SwitchListTile(
                    title: const Text('Offline Mode'),
                    subtitle: const Text('Work offline and sync data later'),
                    value: _isOfflineMode,
                    onChanged: (value) {
                      setState(() {
                        _isOfflineMode = value;
                      });
                      _saveSettings();
                    },
                    secondary: const Icon(Icons.wifi_off),
                  ),
                  const Divider(),
                  
                  // Security section
                  _buildSectionHeader('Security'),
                  SwitchListTile(
                    title: const Text('Biometric Authentication'),
                    subtitle: const Text('Use fingerprint to login'),
                    value: _isBiometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isBiometricEnabled = value;
                      });
                      _saveSettings();
                    },
                    secondary: const Icon(Icons.fingerprint),
                  ),
                  const Divider(),
                  
                  // Notifications section
                  _buildSectionHeader('Notifications'),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive app notifications'),
                    value: _isNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isNotificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                  const Divider(),
                  
                  // About section
                  _buildSectionHeader('About'),
                  ListTile(
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                    leading: const Icon(Icons.info),
                  ),
                  ListTile(
                    title: const Text('Terms of Service'),
                    leading: const Icon(Icons.description),
                    onTap: () {
                      // Show terms of service
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Terms of Service'),
                          content: const SingleChildScrollView(
                            child: Text(
                              'This is a placeholder for the terms of service. '
                              'In a real app, this would contain the actual terms of service text.',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    leading: const Icon(Icons.privacy_tip),
                    onTap: () {
                      // Show privacy policy
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Privacy Policy'),
                          content: const SingleChildScrollView(
                            child: Text(
                              'This is a placeholder for the privacy policy. '
                              'In a real app, this would contain the actual privacy policy text.',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
