class Validators {
  // Required field validator
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }
  
  // Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  // Password validator (minimum 6 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Password match validator
  static String? Function(String?) passwordMatch(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirm password is required';
      }
      
      if (value != password) {
        return 'Passwords do not match';
      }
      
      return null;
    };
  }
  
  // Phone number validator
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegExp = RegExp(r'^\d{10,15}$');
    
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
      return 'Enter a valid phone number';
    }
    
    return null;
  }
  
  // Name validator
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
  
  // Registration number validator
  static String? registrationNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Registration number is required';
    }
    
    if (value.length < 3) {
      return 'Registration number must be at least 3 characters';
    }
    
    return null;
  }
  
  // Course code validator
  static String? courseCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Course code is required';
    }
    
    return null;
  }
  
  // Department code validator
  static String? departmentCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Department code is required';
    }
    
    return null;
  }
  
  // Employee ID validator
  static String? employeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }
    
    return null;
  }
}