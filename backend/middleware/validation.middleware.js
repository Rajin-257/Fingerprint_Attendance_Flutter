const { body, param, query, validationResult } = require('express-validator');

// Define common validation rules
const validationRules = {
  // Authentication
  login: [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  
  // Super Admin
  createInstitute: [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ],
  
  // Institute
  createTeacher: [
    body('employeeId').notEmpty().withMessage('Employee ID is required'),
    body('firstName').notEmpty().withMessage('First name is required'),
    body('lastName').notEmpty().withMessage('Last name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ],
  
  createDepartment: [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
  ],
  
  createSection: [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
    body('departmentId').isInt().withMessage('Valid department ID is required'),
  ],
  
  createCourse: [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
    body('departmentId').isInt().withMessage('Valid department ID is required'),
    body('sectionId').isInt().withMessage('Valid section ID is required'),
  ],
  
  // Teacher
  createStudent: [
    body('registrationNumber').notEmpty().withMessage('Registration number is required'),
    body('firstName').notEmpty().withMessage('First name is required'),
    body('lastName').notEmpty().withMessage('Last name is required'),
    body('departmentId').isInt().withMessage('Valid department ID is required'),
    body('sectionId').isInt().withMessage('Valid section ID is required'),
  ],
  
  updateProfile: [
    body('password')
      .optional()
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters'),
  ],
  
  takeAttendance: [
    body('studentId').isInt().withMessage('Valid student ID is required'),
    body('courseId').isInt().withMessage('Valid course ID is required'),
    body('date').isDate().withMessage('Valid date is required'),
    body('status')
      .isIn(['Present', 'Late', 'Absent'])
      .withMessage('Status must be Present, Late, or Absent'),
  ],
  
  syncAttendance: [
    body('attendanceRecords').isArray().withMessage('Attendance records must be an array'),
    body('attendanceRecords.*.offlineId').notEmpty().withMessage('Offline ID is required'),
    body('attendanceRecords.*.studentId').isInt().withMessage('Valid student ID is required'),
    body('attendanceRecords.*.courseId').isInt().withMessage('Valid course ID is required'),
    body('attendanceRecords.*.date').isDate().withMessage('Valid date is required'),
    body('attendanceRecords.*.status')
      .isIn(['Present', 'Late', 'Absent'])
      .withMessage('Status must be Present, Late, or Absent'),
  ],
  
  // Common
  idParam: [
    param('id').isInt().withMessage('Invalid ID parameter'),
  ],
  
  pagination: [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1 }).withMessage('Limit must be a positive integer'),
  ],
};

// Validation middleware
const validate = (validations) => {
  return async (req, res, next) => {
    // Execute all validations
    await Promise.all(validations.map(validation => validation.run(req)));

    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    // Format errors
    const formattedErrors = errors.array().map(error => ({
      field: error.param,
      message: error.msg,
    }));

    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: formattedErrors,
    });
  };
};

module.exports = {
  validationRules,
  validate,
};