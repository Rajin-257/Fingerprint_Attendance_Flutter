const express = require('express');
const { body } = require('express-validator');
const courseController = require('../controllers/course.controller');
const { verifyToken, isInstitute, checkLicenseKey } = require('../middleware/auth.middleware');
const { validateRequest } = require('../middleware/errorHandler.middleware');

const router = express.Router();

// Apply middleware to all routes
router.use([checkLicenseKey, verifyToken, isInstitute]);

/**
 * @swagger
 * /api/courses:
 *   post:
 *     summary: Create a new course
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - code
 *               - departmentId
 *               - sectionId
 *             properties:
 *               name:
 *                 type: string
 *               code:
 *                 type: string
 *               description:
 *                 type: string
 *               creditHours:
 *                 type: number
 *               schedule:
 *                 type: object
 *               departmentId:
 *                 type: integer
 *               sectionId:
 *                 type: integer
 *               teacherId:
 *                 type: integer
 *     responses:
 *       201:
 *         description: Course created successfully
 *       409:
 *         description: Course with this code already exists
 */
router.post(
  '/',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
    body('departmentId').isInt().withMessage('Valid department ID is required'),
    body('sectionId').isInt().withMessage('Valid section ID is required'),
    validateRequest,
  ],
  courseController.createCourse
);

/**
 * @swagger
 * /api/courses:
 *   get:
 *     summary: Get all courses
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: departmentId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: sectionId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: teacherId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of courses
 */
router.get('/', courseController.getAllCourses);

/**
 * @swagger
 * /api/courses/{id}:
 *   get:
 *     summary: Get course by ID
 *     tags: [Courses]
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
 *         description: Course details
 *       404:
 *         description: Course not found
 */
router.get('/:id', courseController.getCourseById);

/**
 * @swagger
 * /api/courses/{id}:
 *   put:
 *     summary: Update course
 *     tags: [Courses]
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
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               creditHours:
 *                 type: number
 *               schedule:
 *                 type: object
 *               active:
 *                 type: boolean
 *               teacherId:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Course updated successfully
 *       404:
 *         description: Course not found
 */
router.put(
  '/:id',
  [
    body('name').optional().notEmpty().withMessage('Name cannot be empty'),
    validateRequest,
  ],
  courseController.updateCourse
);

/**
 * @swagger
 * /api/courses/{id}:
 *   delete:
 *     summary: Delete course
 *     tags: [Courses]
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
 *         description: Course deleted successfully
 *       400:
 *         description: Cannot delete course with dependencies
 *       404:
 *         description: Course not found
 */
router.delete('/:id', courseController.deleteCourse);

/**
 * @swagger
 * /api/courses/{id}/students:
 *   post:
 *     summary: Add students to course
 *     tags: [Courses]
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
 *             required:
 *               - studentIds
 *             properties:
 *               studentIds:
 *                 type: array
 *                 items:
 *                   type: integer
 *     responses:
 *       200:
 *         description: Students added to course successfully
 *       400:
 *         description: Invalid student IDs
 *       404:
 *         description: Course not found
 */
router.post(
  '/:id/students',
  [
    body('studentIds').isArray().withMessage('Student IDs must be an array'),
    validateRequest,
  ],
  courseController.addStudentsToCourse
);

/**
 * @swagger
 * /api/courses/{id}/students:
 *   delete:
 *     summary: Remove students from course
 *     tags: [Courses]
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
 *             required:
 *               - studentIds
 *             properties:
 *               studentIds:
 *                 type: array
 *                 items:
 *                   type: integer
 *     responses:
 *       200:
 *         description: Students removed from course successfully
 *       400:
 *         description: Cannot remove students with attendance records
 *       404:
 *         description: Course not found
 */
router.delete(
  '/:id/students',
  [
    body('studentIds').isArray().withMessage('Student IDs must be an array'),
    validateRequest,
  ],
  courseController.removeStudentsFromCourse
);

/**
 * @swagger
 * /api/courses/{id}/students:
 *   get:
 *     summary: Get students in course
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
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
 *     responses:
 *       200:
 *         description: List of students in course
 *       404:
 *         description: Course not found
 */
router.get('/:id/students', courseController.getStudentsInCourse);

module.exports = router;