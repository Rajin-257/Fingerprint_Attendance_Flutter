const express = require('express');
const { body } = require('express-validator');
const teacherController = require('../controllers/teacher.controller');
const { verifyToken, isTeacher, checkLicenseKey } = require('../middleware/auth.middleware');
const { validateRequest } = require('../middleware/errorHandler.middleware');

const router = express.Router();

// Apply middleware to all routes
router.use([checkLicenseKey, verifyToken, isTeacher]);

/**
 * @swagger
 * /api/teachers/students:
 *   post:
 *     summary: Create a new student
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - registrationNumber
 *               - firstName
 *               - lastName
 *               - departmentId
 *               - sectionId
 *             properties:
 *               registrationNumber:
 *                 type: string
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               email:
 *                 type: string
 *               dateOfBirth:
 *                 type: string
 *                 format: date
 *               gender:
 *                 type: string
 *                 enum: [Male, Female, Other]
 *               contactNumber:
 *                 type: string
 *               address:
 *                 type: string
 *               fingerprint:
 *                 type: string
 *               departmentId:
 *                 type: integer
 *               sectionId:
 *                 type: integer
 *               courseIds:
 *                 type: array
 *                 items:
 *                   type: integer
 *     responses:
 *       201:
 *         description: Student created successfully
 *       409:
 *         description: Student already exists
 */
router.post(
  '/students',
  [
    body('registrationNumber').notEmpty().withMessage('Registration number is required'),
    body('firstName').notEmpty().withMessage('First name is required'),
    body('lastName').notEmpty().withMessage('Last name is required'),
    body('departmentId').isInt().withMessage('Valid department ID is required'),
    body('sectionId').isInt().withMessage('Valid section ID is required'),
    validateRequest,
  ],
  teacherController.createStudent
);

/**
 * @swagger
 * /api/teachers/students:
 *   get:
 *     summary: Get all students
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *       - in: query
 *         name: courseId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of students
 */
router.get('/students', teacherController.getAllStudents);

/**
 * @swagger
 * /api/teachers/students/{id}:
 *   get:
 *     summary: Get student by ID
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Student details
 *       404:
 *         description: Student not found
 */
router.get('/students/:id', teacherController.getStudentById);

/**
 * @swagger
 * /api/teachers/students/{id}:
 *   put:
 *     summary: Update student
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               email:
 *                 type: string
 *               contactNumber:
 *                 type: string
 *               address:
 *                 type: string
 *               fingerprint:
 *                 type: string
 *               active:
 *                 type: boolean
 *               courseIds:
 *                 type: array
 *                 items:
 *                   type: integer
 *     responses:
 *       200:
 *         description: Student updated successfully
 *       404:
 *         description: Student not found
 */
router.put('/students/:id', teacherController.updateStudent);

/**
 * @swagger
 * /api/teachers/attendance:
 *   post:
 *     summary: Take attendance
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - studentId
 *               - courseId
 *               - date
 *               - status
 *             properties:
 *               studentId:
 *                 type: integer
 *               courseId:
 *                 type: integer
 *               date:
 *                 type: string
 *                 format: date
 *               status:
 *                 type: string
 *                 enum: [Present, Late, Absent]
 *               timeIn:
 *                 type: string
 *                 format: time
 *               remarks:
 *                 type: string
 *               fingerprintVerified:
 *                 type: boolean
 *               offlineId:
 *                 type: string
 *     responses:
 *       201:
 *         description: Attendance recorded successfully
 */
router.post(
  '/attendance',
  [
    body('studentId').isInt().withMessage('Valid student ID is required'),
    body('courseId').isInt().withMessage('Valid course ID is required'),
    body('date').isDate().withMessage('Valid date is required'),
    body('status')
      .isIn(['Present', 'Late', 'Absent'])
      .withMessage('Status must be Present, Late, or Absent'),
    validateRequest,
  ],
  teacherController.takeAttendance
);

/**
 * @swagger
 * /api/teachers/attendance/sync:
 *   post:
 *     summary: Sync offline attendance records
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - attendanceRecords
 *             properties:
 *               attendanceRecords:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - offlineId
 *                     - studentId
 *                     - courseId
 *                     - date
 *                     - status
 *                   properties:
 *                     offlineId:
 *                       type: string
 *                     studentId:
 *                       type: integer
 *                     courseId:
 *                       type: integer
 *                     date:
 *                       type: string
 *                       format: date
 *                     status:
 *                       type: string
 *                       enum: [Present, Late, Absent]
 *                     timeIn:
 *                       type: string
 *                       format: time
 *                     remarks:
 *                       type: string
 *                     fingerprintVerified:
 *                       type: boolean
 *     responses:
 *       200:
 *         description: Attendance records synced successfully
 */
router.post(
  '/attendance/sync',
  [
    body('attendanceRecords').isArray().withMessage('Attendance records must be an array'),
    validateRequest,
  ],
  teacherController.syncOfflineAttendance
);

/**
 * @swagger
 * /api/teachers/attendance/report:
 *   get:
 *     summary: Get attendance report
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: courseId
 *         required: true
 *         schema:
 *           type: integer
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Attendance report
 */
router.get('/attendance/report', teacherController.getAttendanceReport);

/**
 * @swagger
 * /api/teachers/profile:
 *   get:
 *     summary: Get teacher profile
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Teacher profile
 */
router.get('/profile', teacherController.getProfile);

/**
 * @swagger
 * /api/teachers/profile:
 *   put:
 *     summary: Update teacher profile
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               phone:
 *                 type: string
 *               qualification:
 *                 type: string
 *               password:
 *                 type: string
 *               fingerprint:
 *                 type: string
 *     responses:
 *       200:
 *         description: Profile updated successfully
 */
router.put(
  '/profile',
  [
    body('password')
      .optional()
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters'),
    validateRequest,
  ],
  teacherController.updateProfile
);

/**
 * @swagger
 * /api/teachers/dashboard:
 *   get:
 *     summary: Get dashboard statistics
 *     tags: [Teacher]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard statistics
 */
router.get('/dashboard', teacherController.getDashboardStats);

module.exports = router;