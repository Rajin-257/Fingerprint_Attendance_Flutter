const jwt = require('jsonwebtoken');
const SuperAdmin = require('../models/superAdmin.model');
const Institute = require('../models/institute.model');
const Teacher = require('../models/teacher.model');
const authConfig = require('../config/auth.config');

// Super Admin login
const superAdminLogin = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Find super admin by username
    const superAdmin = await SuperAdmin.findOne({ where: { username } });

    if (!superAdmin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid username or password',
      });
    }

    // Verify password
    const isPasswordValid = await superAdmin.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid username or password',
      });
    }

    // Check if account is active
    if (!superAdmin.active) {
      return res.status(403).json({
        success: false,
        message: 'Account is not active',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: superAdmin.id, type: 'superAdmin' },
      authConfig.secret,
      { expiresIn: authConfig.expiresIn.superAdmin }
    );

    // Update last login
    await superAdmin.update({ lastLogin: new Date() });

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: superAdmin.id,
          username: superAdmin.username,
          email: superAdmin.email,
          fullName: superAdmin.fullName,
          type: 'superAdmin',
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error during login',
      error: error.message,
    });
  }
};

// Institute login
const instituteLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find institute by email
    const institute = await Institute.findOne({ where: { email } });

    if (!institute) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Verify password
    const isPasswordValid = await institute.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Check if account is active
    if (!institute.active) {
      return res.status(403).json({
        success: false,
        message: 'Account is not active',
      });
    }

    // Check if license is expired
    if (institute.licenseExpiry && new Date(institute.licenseExpiry) < new Date()) {
      return res.status(403).json({
        success: false,
        message: 'Your license has expired',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: institute.id, type: 'institute' },
      authConfig.secret,
      { expiresIn: authConfig.expiresIn.institute }
    );

    // Update last login
    await institute.update({ lastLogin: new Date() });

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: institute.id,
          name: institute.name,
          code: institute.code,
          email: institute.email,
          type: 'institute',
          licenseExpiry: institute.licenseExpiry,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error during login',
      error: error.message,
    });
  }
};

// Teacher login
const teacherLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find teacher by email
    const teacher = await Teacher.findOne({
      where: { email },
      include: [{ model: Institute, as: 'institute' }],
    });

    if (!teacher) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Verify password
    const isPasswordValid = await teacher.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Check if account is active
    if (!teacher.active) {
      return res.status(403).json({
        success: false,
        message: 'Account is not active',
      });
    }

    // Check if teacher's institute is active
    if (!teacher.institute || !teacher.institute.active) {
      return res.status(403).json({
        success: false,
        message: 'Your institute is not active',
      });
    }

    // Check if institute license is expired
    if (
      teacher.institute.licenseExpiry &&
      new Date(teacher.institute.licenseExpiry) < new Date()
    ) {
      return res.status(403).json({
        success: false,
        message: 'Your institute\'s license has expired',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: teacher.id, type: 'teacher' },
      authConfig.secret,
      { expiresIn: authConfig.expiresIn.teacher }
    );

    // Update last login and device ID if provided
    const updateData = { lastLogin: new Date() };
    if (req.body.deviceId) {
      updateData.deviceId = req.body.deviceId;
    }
    await teacher.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: teacher.id,
          employeeId: teacher.employeeId,
          firstName: teacher.firstName,
          lastName: teacher.lastName,
          email: teacher.email,
          type: 'teacher',
          instituteId: teacher.instituteId,
          instituteName: teacher.institute.name,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error during login',
      error: error.message,
    });
  }
};

module.exports = {
  superAdminLogin,
  instituteLogin,
  teacherLogin,
};