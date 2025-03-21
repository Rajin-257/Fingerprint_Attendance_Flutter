const express = require('express');
const { body } = require('express-validator');
const studentController = require('../controllers/student.controller');
const { verifyToken, isInstitute, isTeacher, validateRequest, checkLicenseKey } = require('../middleware/auth.middleware');

const router = express.Router();

// Routes for Institute
router.use('/institute', [checkLicenseKey, verifyToken, isInstitute]);

/**
 * @swagger
 * /api/students/institute:
 *   get:
 *     summary: Get all students (Institute)
 *     tags: [Students]
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
 *         name: departmentId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: sectionId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of students
 */
router.get('/institute', studentController.getAllStudentsForInstitute);

/**
 * @swagger
 * /api/students/institute/{id}:
 *   get:
 *     summary: Get student by ID (Institute)
 *     tags: [Students]
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
router.get('/institute/:id', studentController.getStudentByIdForInstitute);

/**
 * @swagger
 * /api/students/institute/{id}:
 *   put:
 *     summary: Update student (Institute)
 *     tags: [Students]
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
 *               active:
 *                 type: boolean
 *               departmentId:
 *                 type: integer
 *               sectionId:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Student updated successfully
 *       404:
 *         description: Student not found
 */
router.put(
  '/institute/:id',
  [
    body('firstName').optional().notEmpty().withMessage('First name cannot be empty'),
    body('lastName').optional().notEmpty().withMessage('Last name cannot be empty'),
    body('email').optional().isEmail().withMessage('Valid email is required'),
    validateRequest,
  ],
  studentController.updateStudentForInstitute
);

/**
 * @swagger
 * /api/students/institute/{id}:
 *   delete:
 *     summary: Delete student (Institute)
 *     tags: [Students]
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
 *         description: Student deleted successfully
 *       404:
 *         description: Student not found
 */
router.delete('/institute/:id', studentController.deleteStudentForInstitute);

/**
 * @swagger
 * /api/students/institute/attendance/report:
 *   get:
 *     summary: Get attendance report (Institute)
 *     tags: [Students]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: courseId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: departmentId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: sectionId
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
router.get('/institute/attendance/report', studentController.getAttendanceReportForInstitute);

// Export router
module.exports = router;