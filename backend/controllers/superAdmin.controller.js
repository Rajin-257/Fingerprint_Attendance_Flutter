const SuperAdmin = require('../models/superAdmin.model');
const Institute = require('../models/institute.model');
const Teacher = require('../models/teacher.model');
const Department = require('../models/department.model');
const { Op } = require('sequelize');
const bcrypt = require('bcryptjs');

// Create a new institute
const createInstitute = async (req, res) => {
  try {
    const {
      name,
      code,
      email,
      password,
      address,
      contactPerson,
      contactNumber,
      licenseExpiry,
    } = req.body;

    // Check if institute with code or email already exists
    const existingInstitute = await Institute.findOne({
      where: {
        [Op.or]: [{ code }, { email }],
      },
    });

    if (existingInstitute) {
      return res.status(409).json({
        success: false,
        message: 'Institute with this code or email already exists',
      });
    }

    // Create new institute
    const newInstitute = await Institute.create({
      name,
      code,
      email,
      password,
      address,
      contactPerson,
      contactNumber,
      licenseExpiry: licenseExpiry || null,
      active: true,
      createdBy: req.superAdmin.id,
    });

    return res.status(201).json({
      success: true,
      message: 'Institute created successfully',
      data: {
        id: newInstitute.id,
        name: newInstitute.name,
        code: newInstitute.code,
        email: newInstitute.email,
        licenseExpiry: newInstitute.licenseExpiry,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating institute',
      error: error.message,
    });
  }
};

// Get all institutes
const getAllInstitutes = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';

    // Filter options
    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { code: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
      ];
    }

    // Get institutes with pagination
    const { count, rows } = await Institute.findAndCountAll({
      where: whereClause,
      attributes: [
        'id',
        'name',
        'code',
        'email',
        'contactPerson',
        'contactNumber',
        'licenseExpiry',
        'active',
        'createdAt',
      ],
      order: [['createdAt', 'DESC']],
      limit,
      offset,
    });

    return res.status(200).json({
      success: true,
      message: 'Institutes retrieved successfully',
      data: {
        institutes: rows,
        pagination: {
          total: count,
          page,
          limit,
          pages: Math.ceil(count / limit),
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving institutes',
      error: error.message,
    });
  }
};

// Get institute by ID
const getInstituteById = async (req, res) => {
  try {
    const { id } = req.params;

    const institute = await Institute.findByPk(id, {
      attributes: [
        'id',
        'name',
        'code',
        'email',
        'address',
        'contactPerson',
        'contactNumber',
        'licenseExpiry',
        'active',
        'createdAt',
      ],
    });

    if (!institute) {
      return res.status(404).json({
        success: false,
        message: 'Institute not found',
      });
    }

    // Get institute statistics
    const teacherCount = await Teacher.count({
      where: { instituteId: id },
    });

    const departmentCount = await Department.count({
      where: { instituteId: id },
    });

    return res.status(200).json({
      success: true,
      message: 'Institute retrieved successfully',
      data: {
        institute,
        stats: {
          teacherCount,
          departmentCount,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving institute',
      error: error.message,
    });
  }
};

// Update institute
const updateInstitute = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      address,
      contactPerson,
      contactNumber,
      licenseExpiry,
      active,
      password,
    } = req.body;

    // Find institute
    const institute = await Institute.findByPk(id);

    if (!institute) {
      return res.status(404).json({
        success: false,
        message: 'Institute not found',
      });
    }

    // Update fields
    const updateData = {};
    if (name) updateData.name = name;
    if (address) updateData.address = address;
    if (contactPerson) updateData.contactPerson = contactPerson;
    if (contactNumber) updateData.contactNumber = contactNumber;
    if (licenseExpiry !== undefined) updateData.licenseExpiry = licenseExpiry;
    if (active !== undefined) updateData.active = active;
    if (password) updateData.password = password;

    // Update institute
    await institute.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Institute updated successfully',
      data: {
        id: institute.id,
        name: institute.name,
        code: institute.code,
        email: institute.email,
        active: institute.active,
        licenseExpiry: institute.licenseExpiry,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating institute',
      error: error.message,
    });
  }
};

// Delete institute
const deleteInstitute = async (req, res) => {
  try {
    const { id } = req.params;

    // Find institute
    const institute = await Institute.findByPk(id);

    if (!institute) {
      return res.status(404).json({
        success: false,
        message: 'Institute not found',
      });
    }

    // Delete institute (or mark as inactive)
    await institute.update({ active: false });

    return res.status(200).json({
      success: true,
      message: 'Institute deactivated successfully',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error deactivating institute',
      error: error.message,
    });
  }
};

// Get super admin profile
const getProfile = async (req, res) => {
  try {
    const superAdmin = await SuperAdmin.findByPk(req.superAdmin.id, {
      attributes: ['id', 'username', 'email', 'fullName', 'lastLogin', 'createdAt'],
    });

    return res.status(200).json({
      success: true,
      message: 'Profile retrieved successfully',
      data: superAdmin,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving profile',
      error: error.message,
    });
  }
};

// Update super admin profile
const updateProfile = async (req, res) => {
  try {
    const { fullName, email, password } = req.body;

    // Update fields
    const updateData = {};
    if (fullName) updateData.fullName = fullName;
    if (email) updateData.email = email;
    if (password) updateData.password = password;

    // Update super admin
    await req.superAdmin.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: req.superAdmin.id,
        username: req.superAdmin.username,
        email: req.superAdmin.email,
        fullName: req.superAdmin.fullName,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating profile',
      error: error.message,
    });
  }
};

// Get dashboard statistics
const getDashboardStats = async (req, res) => {
  try {
    // Get total institutes
    const totalInstitutes = await Institute.count();
    
    // Get active institutes
    const activeInstitutes = await Institute.count({
      where: { active: true },
    });

    // Get total teachers across all institutes
    const totalTeachers = await Teacher.count();

    // Get institutes with expiring licenses (within 30 days)
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    
    const expiringLicenses = await Institute.count({
      where: {
        licenseExpiry: {
          [Op.and]: [
            { [Op.gt]: new Date() },
            { [Op.lt]: thirtyDaysFromNow },
          ],
        },
      },
    });

    // Get recently created institutes (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const recentInstitutes = await Institute.findAll({
      where: {
        createdAt: { [Op.gt]: sevenDaysAgo },
      },
      attributes: ['id', 'name', 'code', 'createdAt'],
      order: [['createdAt', 'DESC']],
      limit: 5,
    });

    return res.status(200).json({
      success: true,
      message: 'Dashboard statistics retrieved successfully',
      data: {
        totalInstitutes,
        activeInstitutes,
        totalTeachers,
        expiringLicenses,
        recentInstitutes,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving dashboard statistics',
      error: error.message,
    });
  }
};

module.exports = {
  createInstitute,
  getAllInstitutes,
  getInstituteById,
  updateInstitute,
  deleteInstitute,
  getProfile,
  updateProfile,
  getDashboardStats,
};