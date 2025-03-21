const express = require('express');
const { body, query } = require('express-validator');
const attendanceController = require('../controllers/attendance.controller');
const { verifyToken, isInstitute, isTeacher, validateRequest, checkLicenseKey } = require('../middleware/auth.middleware');

const router = express.Router();

// Routes for Institute
router.use('/institute', [checkLicenseKey, verifyToken, isInstitute]);

/**
 * @swagger
 * /api/attendance/institute:
 *   get:
 *     summary: Get attendance (Institute)
 *     tags: [Attendance]
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
 *         name: courseId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: teacherId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: studentId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [Present, Late, Absent]
 *     responses:
 *       200:
 *         description: List of attendance records
 */
router.get(
  '/institute',
  [
    query('date').optional().isDate().withMessage('Valid date is required'),
    query('status')
      .optional()
      .isIn(['Present', 'Late', 'Absent'])
      .withMessage('Status must be Present, Late, or Absent'),
    validateRequest,
  ],
  attendanceController.getAttendanceForInstitute
);

/**
 * @swagger
 * /api/attendance/institute/daily:
 *   get:
 *     summary: Get daily attendance summary (Institute)
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: departmentId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: sectionId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Daily attendance summary
 */
router.get('/institute/daily', attendanceController.getDailyAttendanceSummaryForInstitute);

/**
 * @swagger
 * /api/attendance/institute/statistics:
 *   get:
 *     summary: Get attendance statistics (Institute)
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
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
 *       - in: query
 *         name: departmentId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: sectionId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: courseId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Attendance statistics
 */
router.get('/institute/statistics', attendanceController.getAttendanceStatisticsForInstitute);

// Routes for Teacher
router.use('/teacher', [checkLicenseKey, verifyToken, isTeacher]);

/**
 * @swagger
 * /api/attendance/teacher:
 *   get:
 *     summary: Get attendance (Teacher)
 *     tags: [Attendance]
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
 *         name: courseId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: studentId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [Present, Late, Absent]
 *     responses:
 *       200:
 *         description: List of attendance records
 */
router.get(
  '/teacher',
  [
    query('date').optional().isDate().withMessage('Valid date is required'),
    query('status')
      .optional()
      .isIn(['Present', 'Late', 'Absent'])
      .withMessage('Status must be Present, Late, or Absent'),
    validateRequest,
  ],
  attendanceController.getAttendanceForTeacher
);

/**
 * @swagger
 * /api/attendance/teacher/daily:
 *   get:
 *     summary: Get daily attendance summary (Teacher)
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: courseId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Daily attendance summary
 */
router.get('/teacher/daily', attendanceController.getDailyAttendanceSummaryForTeacher);

// Export router
module.exports = router;