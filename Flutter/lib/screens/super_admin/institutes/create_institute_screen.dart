import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../data/local/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/validators.dart';
import '../../../utils/snackbar_utils.dart';

class CreateInstituteScreen extends StatefulWidget {
  const CreateInstituteScreen({super.key});

  @override
  State<CreateInstituteScreen> createState() => _CreateInstituteScreenState();
}

class _CreateInstituteScreenState extends State<CreateInstituteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }
  
  // Save institute
  Future<void> _saveInstitute() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
      
      // Check if institute code already exists
      final existingInstitute = await dbHelper.query(
        'institutes',
        where: 'code = ?',
        whereArgs: [_codeController.text],
      );
      
      if (existingInstitute.isNotEmpty) {
        throw Exception('An institute with this code already exists');
      }
      
      // Start transaction
      await dbHelper.transaction((txn) async {
        // Insert institute
        final instituteId = await txn.insert(
          'institutes',
          {
            'name': _nameController.text,
            'code': _codeController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'active': 1,
            'createdAt': DateTime.now().toIso8601String(),
            'synced': 0, // Mark for sync
          },
        );
        
        // Insert institute admin
        await txn.insert(
          'institute_admins',
          {
            'name': _adminNameController.text,
            'email': _adminEmailController.text,
            'password': _adminPasswordController.text, // Note: In a real app, this should be hashed
            'instituteId': instituteId,
            'active': 1,
            'createdAt': DateTime.now().toIso8601String(),
            'synced': 0, // Mark for sync
          },
        );
        
        return instituteId;
      });
      
      if (mounted) {
        showSuccessSnackbar(context, 'Institute created successfully');
        
        // Navigate back to institute list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Institute'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Institute information section
                    Text(
                      'Institute Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Institute name
                    CustomTextField(
                      controller: _nameController,
                      label: 'Institute Name',
                      hint: 'Enter institute name',
                      prefixIcon: Icons.business,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Institute code
                    CustomTextField(
                      controller: _codeController,
                      label: 'Institute Code',
                      hint: 'Enter institute code',
                      prefixIcon: Icons.code,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 16),
                    
                    // Institute email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter institute email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    
                    // Institute phone
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      hint: 'Enter institute phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Institute address
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter institute address',
                      prefixIcon: Icons.location_on,
                      maxLines: 2,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 32),
                    
                    // Admin information section
                    Text(
                      'Admin Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Admin name
                    CustomTextField(
                      controller: _adminNameController,
                      label: 'Admin Name',
                      hint: 'Enter admin name',
                      prefixIcon: Icons.person,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    
                    // Admin email
                    CustomTextField(
                      controller: _adminEmailController,
                      label: 'Admin Email',
                      hint: 'Enter admin email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    
                    // Admin password
                    CustomTextField(
                      controller: _adminPasswordController,
                      label: 'Admin Password',
                      hint: 'Enter admin password',
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Create Institute',
                        icon: Icons.save,
                        isLoading: _isSaving,
                        onPressed: _saveInstitute,
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
