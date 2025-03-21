const express = require('express');
const { body } = require('express-validator');
const sectionController = require('../controllers/section.controller');
const { verifyToken, isInstitute, validateRequest, checkLicenseKey } = require('../middleware/auth.middleware');

const router = express.Router();

// Apply middleware to all routes
router.use([checkLicenseKey, verifyToken, isInstitute]);

/**
 * @swagger
 * /api/sections:
 *   post:
 *     summary: Create a new section
 *     tags: [Sections]
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
 *             properties:
 *               name:
 *                 type: string
 *               code:
 *                 type: string
 *               capacity:
 *                 type: integer
 *               description:
 *                 type: string
 *               departmentId:
 *                 type: integer
 *     responses:
 *       201:
 *         description: Section created successfully
 *       409:
 *         description: Section with this code already exists
 */
router.post(
  '/',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('code').notEmpty().withMessage('Code is required'),
    body('departmentId').isInt().withMessage('Valid department ID is required'),
    validateRequest,
  ],
  sectionController.createSection
);

/**
 * @swagger
 * /api/sections:
 *   get:
 *     summary: Get all sections
 *     tags: [Sections]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: departmentId
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of sections
 */
router.get('/', sectionController.getAllSections);

/**
 * @swagger
 * /api/sections/{id}:
 *   get:
 *     summary: Get section by ID
 *     tags: [Sections]
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
 *         description: Section details
 *       404:
 *         description: Section not found
 */
router.get('/:id', sectionController.getSectionById);

/**
 * @swagger
 * /api/sections/{id}:
 *   put:
 *     summary: Update section
 *     tags: [Sections]
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
 *               capacity:
 *                 type: integer
 *               description:
 *                 type: string
 *               active:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Section updated successfully
 *       404:
 *         description: Section not found
 */
router.put(
  '/:id',
  [
    body('name').optional().notEmpty().withMessage('Name cannot be empty'),
    body('capacity').optional().isInt().withMessage('Capacity must be an integer'),
    validateRequest,
  ],
  sectionController.updateSection
);

/**
 * @swagger
 * /api/sections/{id}:
 *   delete:
 *     summary: Delete section
 *     tags: [Sections]
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
 *         description: Section deleted successfully
 *       400:
 *         description: Cannot delete section with dependencies
 *       404:
 *         description: Section not found
 */
router.delete('/:id', sectionController.deleteSection);

module.exports = router;