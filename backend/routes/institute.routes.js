const express = require('express');
const { body } = require('express-validator');
const instituteController = require('../controllers/institute.controller');
const { verifyToken, isInstitute, validateRequest, checkLicenseKey } = require('../middleware/auth.middleware');

const router = express.Router();

// Apply middleware to all routes
router.use([checkLicenseKey, verifyToken, isInstitute]);

/**
 * @swagger
 * /api/institutes/teachers:
 *   post:
 *     summary: Create a new teacher
 *     tags: [Institute]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - employeeId
 *               - firstName
 *               - lastName
 *               - email
 *               - password
 *             properties:
 *               employeeId:
 *                 type: string
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               phone:
 *                 type: string
 *               qualification:
 *                 type: string
 *               joiningDate:
 *                 type: string
 *                 format: date
 *     responses:
 *       201:
 *         description: Teacher created successfully
 *       409:
 *         description: Teacher already exists
 */
router.post(
  '/teachers',
  [
    body('employeeId').notEmpty().withMessage('Employee ID is required'),
    body('firstName').notEmpty().withMessage('First name is required'),
    body('lastName').notEmpty().withMessage('Last name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    validateRequest,
  ],
  instituteController.createTeacher
);

/**
 * @swagger
 * /api/institutes/teachers:
 *   get:
 *     summary: Get all teachers
 *     tags: [Institute]
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
 *     responses:
 *       200:
 *         description: List of teachers
 */
router.get('/teachers', instituteController.getAllTeachers);

/**
 * @swagger
 * /api/institutes/teachers/{id}:
 *   get:
 *     summary: Get teacher by ID
 *     tags: [Institute]
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
 *         description: Teacher details
 *       404:
 *         description: Teacher not found
 */
router.get('/teachers/:id', instituteController.getTeacherById);

/**
 * @swagger
 * /api/institutes/teachers/{id}:
 *   put:
 *     summary: Update teacher
 *     tags: [Institute]
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
 *               phone:
 *                 type: string
 *               qualification:
 *                 type: string
 *               active:
 *                 type: boolean
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Teacher updated successfully
 *       404:
 *         description: Teacher not found
 */
router.put('/teachers/:id', instituteController.updateTeacher);

/**
 * @swagger
 * /api/institutes/teachers/{id}:
 *   delete:
 *     summary: Delete teacher (deactivate)
 *     tags: [Institute]
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
 *         description: Teacher deactivated successfully
 *       404:
 *         description: Teacher not found
 */
router.delete('/teachers/:id', instituteController.deleteTeacher);

/**
 * @swagger
 * /api/institutes/departments:
 *   post:
 *     summary: Create a new department
 *     tags: [Institute]
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
 *             properties:
 *               name:
 *                 type: string
 *               code:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Department created successfully
 *       409:
 *         description: Department already exists
 */
router.post(
  '/departments',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
    validateRequest,
  ],
  instituteController.createDepartment
);

/**
 * @swagger
 * /api/institutes/departments:
 *   get:
 *     summary: Get all departments
 *     tags: [Institute]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of departments
 */
router.get('/departments', instituteController.getAllDepartments);

/**
 * @swagger
 * /api/institutes/profile:
 *   get:
 *     summary: Get institute profile
 *     tags: [Institute]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Institute profile
 */
router.get('/profile', instituteController.getProfile);

/**
 * @swagger
 * /api/institutes/profile:
 *   put:
 *     summary: Update institute profile
 *     tags: [Institute]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               address:
 *                 type: string
 *               contactPerson:
 *                 type: string
 *               contactNumber:
 *                 type: string
 *               password:
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
  instituteController.updateProfile
);

/**
 * @swagger
 * /api/institutes/dashboard:
 *   get:
 *     summary: Get dashboard statistics
 *     tags: [Institute]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard statistics
 */
router.get('/dashboard', instituteController.getDashboardStats);

module.exports = router;