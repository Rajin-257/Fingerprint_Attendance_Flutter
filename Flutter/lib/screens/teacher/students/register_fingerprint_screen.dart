import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../core/biometrics/biometric_service.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/snackbar_utils.dart';

class RegisterFingerprintScreen extends StatefulWidget {
  const RegisterFingerprintScreen({super.key});

  @override
  State<RegisterFingerprintScreen> createState() => _RegisterFingerprintScreenState();
}

class _RegisterFingerprintScreenState extends State<RegisterFingerprintScreen> {
  Map<String, dynamic>? _student;
  bool _isRegistering = false;
  String _selectedFinger = 'right_thumb';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentData();
    });
  }
  
  // Load student data from route arguments
  void _loadStudentData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      setState(() {
        _student = args['student'];
      });
    } else {
      // If no student data provided, go back
      Navigator.pop(context);
      showErrorSnackbar(context, 'No student data provided');
    }
  }
  
  // Register fingerprint
  Future<void> _registerFingerprint() async {
    if (_student == null) return;
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      final biometricService = Provider.of<BiometricService>(context, listen: false);
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // First, check if device supports biometrics
      final isBiometricAvailable = await biometricService.isBiometricAvailable();
      if (!isBiometricAvailable) {
        throw Exception('This device does not support biometric authentication');
      }
      
      // Get available biometrics
      final availableBiometrics = await biometricService.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        throw Exception('No biometric methods available on this device');
      }
      
      // Get the student ID
      final studentId = _student!['id'];
      
      // Register the fingerprint
      final result = await biometricService.registerFingerprint(
        studentId: studentId.toString(),
        position: _selectedFinger,
      );
      
      if (!result['success']) {
        throw Exception(result['message']);
      }
      
      // Save template to database
      final fingerprintData = {
        'studentId': studentId,
        'templateData': result['template'],
        'fingerPosition': _selectedFinger,
        'quality': result['quality'],
        'createdAt': DateTime.now().toIso8601String(),
        'synced': 0,
      };
      
      // Check if the student already has a fingerprint of this type
      final existingFingerprint = await dbHelper.query(
        DBConstants.fingerprintsTable,
        where: 'studentId = ? AND fingerPosition = ?',
        whereArgs: [studentId, _selectedFinger],
      );
      
      if (existingFingerprint.isNotEmpty) {
        // Update existing record
        await dbHelper.update(
          DBConstants.fingerprintsTable,
          fingerprintData,
          where: 'id = ?',
          whereArgs: [existingFingerprint.first['id']],
        );
      } else {
        // Insert new record
        await dbHelper.insert(DBConstants.fingerprintsTable, fingerprintData);
      }
      
      // Update student record to reference the fingerprint
      await dbHelper.update(
        DBConstants.studentsTable,
        {
          'fingerprint': result['template'],
          'updatedAt': DateTime.now().toIso8601String(),
          'synced': 0, // Mark for sync
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );
      
      if (mounted) {
        showSuccessSnackbar(context, 'Fingerprint registered successfully');
        
        // Return success to previous screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_student == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final fullName = '${_student!['firstName']} ${_student!['lastName']}';
    final regNumber = _student!['registrationNumber'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Fingerprint'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student info card
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          fullName.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 32,
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
                              fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              regNumber,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Fingerprint registration section
              Text(
                'Fingerprint Registration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please select which finger to register and scan the student\'s fingerprint.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              // Finger selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Finger',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fingerprint),
                ),
                value: _selectedFinger,
                items: [
                  DropdownMenuItem(
                    value: 'right_thumb',
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/finger_right_thumb.png',
                          width: 24,
                          height: 24,
                          // Fallback to icon if image not available
                          errorBuilder: (_, __, ___) => const Icon(Icons.thumb_up),
                        ),
                        const SizedBox(width: 8),
                        const Text('Right Thumb'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'right_index',
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/finger_right_index.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fingerprint),
                        ),
                        const SizedBox(width: 8),
                        const Text('Right Index'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'left_thumb',
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/finger_left_thumb.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(Icons.thumb_up),
                        ),
                        const SizedBox(width: 8),
                        const Text('Left Thumb'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'left_index',
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/finger_left_index.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fingerprint),
                        ),
                        const SizedBox(width: 8),
                        const Text('Left Index'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFinger = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              
              // Fingerprint scan visualization
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: 100,
                      color: _isRegistering
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRegistering
                          ? 'Scanning fingerprint...'
                          : 'Place finger on the sensor',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure the finger is clean and dry\n'
                      '2. Place the finger on the fingerprint sensor\n'
                      '3. Press firmly but not too hard\n'
                      '4. Hold the finger steady until scan completes\n'
                      '5. Repeat if necessary for better quality',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Scan button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Scan Fingerprint',
                  icon: Icons.fingerprint,
                  isLoading: _isRegistering,
                  onPressed: _registerFingerprint,
                ),
              ),
              const SizedBox(height: 16),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Cancel',
                  isOutlined: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}