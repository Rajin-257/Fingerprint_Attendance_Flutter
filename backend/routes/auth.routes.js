const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { checkLicenseKey } = require('../middleware/auth.middleware');
const { validateRequest } = require('../middleware/errorHandler.middleware');

const router = express.Router();

/**
 * @swagger
 * /api/auth/super-admin/login:
 *   post:
 *     summary: Super Admin login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post(
  '/super-admin/login',
  [
    checkLicenseKey,
    body('username').notEmpty().withMessage('Username is required'),
    body('password').notEmpty().withMessage('Password is required'),
    validateRequest,
  ],
  authController.superAdminLogin
);

/**
 * @swagger
 * /api/auth/institute/login:
 *   post:
 *     summary: Institute login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post(
  '/institute/login',
  [
    checkLicenseKey,
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
    validateRequest,
  ],
  authController.instituteLogin
);

/**
 * @swagger
 * /api/auth/teacher/login:
 *   post:
 *     summary: Teacher login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               deviceId:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post(
  '/teacher/login',
  [
    checkLicenseKey,
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
    validateRequest,
  ],
  authController.teacherLogin
);

module.exports = router;