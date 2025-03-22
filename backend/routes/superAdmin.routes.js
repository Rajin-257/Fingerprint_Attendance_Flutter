const express = require('express');
const { body } = require('express-validator');
const superAdminController = require('../controllers/superAdmin.controller');
const { verifyToken, isSuperAdmin, checkLicenseKey } = require('../middleware/auth.middleware');
const { validateRequest } = require('../middleware/errorHandler.middleware');

const router = express.Router();

// Apply middleware to all routes
router.use([checkLicenseKey, verifyToken, isSuperAdmin]);

/**
 * @swagger
 * /api/super-admin/institutes:
 *   post:
 *     summary: Create a new institute
 *     tags: [Super Admin]
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
 *               - email
 *               - password
 *             properties:
 *               name:
 *                 type: string
 *               code:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               address:
 *                 type: string
 *               contactPerson:
 *                 type: string
 *               contactNumber:
 *                 type: string
 *               licenseExpiry:
 *                 type: string
 *                 format: date
 *     responses:
 *       201:
 *         description: Institute created successfully
 *       409:
 *         description: Institute already exists
 */
router.post(
  '/institutes',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    validateRequest,
  ],
  superAdminController.createInstitute
);

/**
 * @swagger
 * /api/super-admin/institutes:
 *   get:
 *     summary: Get all institutes
 *     tags: [Super Admin]
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
 *     responses:
 *       200:
 *         description: List of institutes
 */
router.get('/institutes', superAdminController.getAllInstitutes);

/**
 * @swagger
 * /api/super-admin/institutes/{id}:
 *   get:
 *     summary: Get institute by ID
 *     tags: [Super Admin]
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
 *         description: Institute details
 *       404:
 *         description: Institute not found
 */
router.get('/institutes/:id', superAdminController.getInstituteById);

/**
 * @swagger
 * /api/super-admin/institutes/{id}:
 *   put:
 *     summary: Update institute
 *     tags: [Super Admin]
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
 *               address:
 *                 type: string
 *               contactPerson:
 *                 type: string
 *               contactNumber:
 *                 type: string
 *               licenseExpiry:
 *                 type: string
 *                 format: date
 *               active:
 *                 type: boolean
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Institute updated successfully
 *       404:
 *         description: Institute not found
 */
router.put('/institutes/:id', superAdminController.updateInstitute);

/**
 * @swagger
 * /api/super-admin/institutes/{id}:
 *   delete:
 *     summary: Delete institute (deactivate)
 *     tags: [Super Admin]
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
 *         description: Institute deactivated successfully
 *       404:
 *         description: Institute not found
 */
router.delete('/institutes/:id', superAdminController.deleteInstitute);

/**
 * @swagger
 * /api/super-admin/profile:
 *   get:
 *     summary: Get super admin profile
 *     tags: [Super Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Super admin profile
 */
router.get('/profile', superAdminController.getProfile);

/**
 * @swagger
 * /api/super-admin/profile:
 *   put:
 *     summary: Update super admin profile
 *     tags: [Super Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName:
 *                 type: string
 *               email:
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
    body('email').optional().isEmail().withMessage('Valid email is required'),
    body('password')
      .optional()
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters'),
    validateRequest,
  ],
  superAdminController.updateProfile
);

/**
 * @swagger
 * /api/super-admin/dashboard:
 *   get:
 *     summary: Get dashboard statistics
 *     tags: [Super Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard statistics
 */
router.get('/dashboard', superAdminController.getDashboardStats);

console.log('Exported Controller Methods:', module.exports);

module.exports = router;