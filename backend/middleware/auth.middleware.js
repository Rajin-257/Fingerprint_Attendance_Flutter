const jwt = require('jsonwebtoken');
const authConfig = require('../config/auth.config');
const SuperAdmin = require('../models/superAdmin.model');
const Institute = require('../models/institute.model');
const Teacher = require('../models/teacher.model');

// Verify JWT token
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'No token provided',
    });
  }

  try {
    const decoded = jwt.verify(token, authConfig.secret);
    req.userId = decoded.id;
    req.userType = decoded.type;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized - Invalid token',
      error: error.message,
    });
  }
};

// Check if user is a Super Admin
const isSuperAdmin = async (req, res, next) => {
  try {
    if (req.userType !== 'superAdmin') {
      return res.status(403).json({
        success: false,
        message: 'Require Super Admin role',
      });
    }

    const superAdmin = await SuperAdmin.findByPk(req.userId);
    if (!superAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Super Admin not found',
      });
    }

    if (!superAdmin.active) {
      return res.status(403).json({
        success: false,
        message: 'Super Admin account is not active',
      });
    }

    req.superAdmin = superAdmin;
    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error validating Super Admin',
      error: error.message,
    });
  }
};

// Check if user is an Institute
const isInstitute = async (req, res, next) => {
  try {
    if (req.userType !== 'institute') {
      return res.status(403).json({
        success: false,
        message: 'Require Institute role',
      });
    }

    const institute = await Institute.findByPk(req.userId);
    if (!institute) {
      return res.status(403).json({
        success: false,
        message: 'Institute not found',
      });
    }

    if (!institute.active) {
      return res.status(403).json({
        success: false,
        message: 'Institute account is not active',
      });
    }

    // Check if license is valid
    if (institute.licenseExpiry && new Date(institute.licenseExpiry) < new Date()) {
      return res.status(403).json({
        success: false,
        message: 'Institute license has expired',
      });
    }

    req.institute = institute;
    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error validating Institute',
      error: error.message,
    });
  }
};

// Check if user is a Teacher
const isTeacher = async (req, res, next) => {
  try {
    if (req.userType !== 'teacher') {
      return res.status(403).json({
        success: false,
        message: 'Require Teacher role',
      });
    }

    const teacher = await Teacher.findByPk(req.userId, {
      include: [{ model: Institute, as: 'institute' }],
    });

    if (!teacher) {
      return res.status(403).json({
        success: false,
        message: 'Teacher not found',
      });
    }

    if (!teacher.active) {
      return res.status(403).json({
        success: false,
        message: 'Teacher account is not active',
      });
    }

    // Check if teacher's institute is active
    if (!teacher.institute || !teacher.institute.active) {
      return res.status(403).json({
        success: false,
        message: 'Teacher\'s institute is not active',
      });
    }

    // Check if institute license is valid
    if (
      teacher.institute.licenseExpiry &&
      new Date(teacher.institute.licenseExpiry) < new Date()
    ) {
      return res.status(403).json({
        success: false,
        message: 'Institute license has expired',
      });
    }

    req.teacher = teacher;
    req.instituteId = teacher.instituteId;
    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error validating Teacher',
      error: error.message,
    });
  }
};

// Check if license key is valid
const checkLicenseKey = (req, res, next) => {
  const licenseKey = req.headers['x-license-key'];

  if (!licenseKey || licenseKey !== authConfig.licenseKey) {
    return res.status(403).json({
      success: false,
      message: 'Invalid license key',
    });
  }

  next();
};

module.exports = {
  verifyToken,
  isSuperAdmin,
  isInstitute,
  isTeacher,
  checkLicenseKey,
};