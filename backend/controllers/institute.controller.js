const Teacher = require('../models/teacher.model');
const Department = require('../models/department.model');
const Section = require('../models/section.model');
const Course = require('../models/course.model');
const { Student } = require('../models/student.model');
const Attendance = require('../models/attendance.model');
const { Op } = require('sequelize');
const bcrypt = require('bcryptjs');
const sequelize = require('../config/db.config');

// Create a new teacher
const createTeacher = async (req, res) => {
  try {
    const {
      employeeId,
      firstName,
      lastName,
      email,
      password,
      phone,
      qualification,
      joiningDate,
    } = req.body;

    // Check if teacher with employeeId or email already exists
    const existingTeacher = await Teacher.findOne({
      where: {
        [Op.or]: [
          { employeeId, instituteId: req.institute.id },
          { email, instituteId: req.institute.id },
        ],
      },
    });

    if (existingTeacher) {
      return res.status(409).json({
        success: false,
        message: 'Teacher with this employee ID or email already exists',
      });
    }

    // Create new teacher
    const newTeacher = await Teacher.create({
      employeeId,
      firstName,
      lastName,
      email,
      password,
      phone,
      qualification,
      joiningDate,
      active: true,
      instituteId: req.institute.id,
    });

    return res.status(201).json({
      success: true,
      message: 'Teacher created successfully',
      data: {
        id: newTeacher.id,
        employeeId: newTeacher.employeeId,
        firstName: newTeacher.firstName,
        lastName: newTeacher.lastName,
        email: newTeacher.email,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating teacher',
      error: error.message,
    });
  }
};

// Get all teachers
const getAllTeachers = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const departmentId = req.query.departmentId || null;

    // Filter options
    const whereClause = { instituteId: req.institute.id };
    if (search) {
      whereClause[Op.or] = [
        { firstName: { [Op.like]: `%${search}%` } },
        { lastName: { [Op.like]: `%${search}%` } },
        { employeeId: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
      ];
    }

    // Get teachers with pagination
    const { count, rows } = await Teacher.findAndCountAll({
      where: whereClause,
      attributes: [
        'id',
        'employeeId',
        'firstName',
        'lastName',
        'email',
        'phone',
        'qualification',
        'joiningDate',
        'active',
        'lastLogin',
        'lastSync',
        'createdAt',
      ],
      order: [['createdAt', 'DESC']],
      limit,
      offset,
      include: departmentId
        ? [
            {
              model: Course,
              as: 'courses',
              required: true,
              where: { departmentId },
              attributes: ['id', 'name', 'code'],
              include: [
                {
                  model: Department,
                  as: 'department',
                  attributes: ['id', 'name', 'code'],
                },
                {
                  model: Section,
                  as: 'section',
                  attributes: ['id', 'name', 'code'],
                },
              ],
            },
          ]
        : [],
    });

    return res.status(200).json({
      success: true,
      message: 'Teachers retrieved successfully',
      data: {
        teachers: rows,
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
      message: 'Error retrieving teachers',
      error: error.message,
    });
  }
};

// Get teacher by ID
const getTeacherById = async (req, res) => {
  try {
    const { id } = req.params;

    const teacher = await Teacher.findOne({
      where: { id, instituteId: req.institute.id },
      attributes: [
        'id',
        'employeeId',
        'firstName',
        'lastName',
        'email',
        'phone',
        'qualification',
        'joiningDate',
        'active',
        'lastLogin',
        'lastSync',
        'createdAt',
      ],
      include: [
        {
          model: Course,
          as: 'courses',
          attributes: ['id', 'name', 'code'],
          include: [
            {
              model: Department,
              as: 'department',
              attributes: ['id', 'name', 'code'],
            },
            {
              model: Section,
              as: 'section',
              attributes: ['id', 'name', 'code'],
            },
          ],
        },
      ],
    });

    if (!teacher) {
      return res.status(404).json({
        success: false,
        message: 'Teacher not found',
      });
    }

    // Get teacher statistics
    const studentCount = await Student.count({
      where: { addedBy: id },
    });

    const courseCount = await Course.count({
      where: { teacherId: id },
    });

    return res.status(200).json({
      success: true,
      message: 'Teacher retrieved successfully',
      data: {
        teacher,
        stats: {
          studentCount,
          courseCount,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving teacher',
      error: error.message,
    });
  }
};

// Update teacher
const updateTeacher = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      firstName,
      lastName,
      phone,
      qualification,
      active,
      password,
    } = req.body;

    // Find teacher
    const teacher = await Teacher.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!teacher) {
      return res.status(404).json({
        success: false,
        message: 'Teacher not found',
      });
    }

    // Update fields
    const updateData = {};
    if (firstName) updateData.firstName = firstName;
    if (lastName) updateData.lastName = lastName;
    if (phone) updateData.phone = phone;
    if (qualification) updateData.qualification = qualification;
    if (active !== undefined) updateData.active = active;
    if (password) updateData.password = password;

    // Update teacher
    await teacher.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Teacher updated successfully',
      data: {
        id: teacher.id,
        employeeId: teacher.employeeId,
        firstName: teacher.firstName,
        lastName: teacher.lastName,
        email: teacher.email,
        active: teacher.active,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating teacher',
      error: error.message,
    });
  }
};

// Delete teacher
const deleteTeacher = async (req, res) => {
  try {
    const { id } = req.params;

    // Find teacher
    const teacher = await Teacher.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!teacher) {
      return res.status(404).json({
        success: false,
        message: 'Teacher not found',
      });
    }

    // Delete teacher (or mark as inactive)
    await teacher.update({ active: false });

    return res.status(200).json({
      success: true,
      message: 'Teacher deactivated successfully',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error deactivating teacher',
      error: error.message,
    });
  }
};

// Create department
const createDepartment = async (req, res) => {
  try {
    const { name, code, description } = req.body;

    // Check if department code already exists in this institute
    const existingDepartment = await Department.findOne({
      where: { code, instituteId: req.institute.id },
    });

    if (existingDepartment) {
      return res.status(409).json({
        success: false,
        message: 'Department with this code already exists',
      });
    }

    // Create new department
    const newDepartment = await Department.create({
      name,
      code,
      description,
      active: true,
      instituteId: req.institute.id,
    });

    return res.status(201).json({
      success: true,
      message: 'Department created successfully',
      data: {
        id: newDepartment.id,
        name: newDepartment.name,
        code: newDepartment.code,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating department',
      error: error.message,
    });
  }
};

// Get all departments
const getAllDepartments = async (req, res) => {
  try {
    const departments = await Department.findAll({
      where: { instituteId: req.institute.id },
      attributes: ['id', 'name', 'code', 'description', 'active', 'createdAt'],
      order: [['name', 'ASC']],
    });

    return res.status(200).json({
      success: true,
      message: 'Departments retrieved successfully',
      data: departments,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving departments',
      error: error.message,
    });
  }
};

// Get institute profile
const getProfile = async (req, res) => {
  try {
    const institute = req.institute;

    // Get statistics
    const teacherCount = await Teacher.count({
      where: { instituteId: institute.id },
    });

    const departmentCount = await Department.count({
      where: { instituteId: institute.id },
    });

    const sectionCount = await Section.count({
      where: { instituteId: institute.id },
    });

    const courseCount = await Course.count({
      where: { instituteId: institute.id },
    });

    const studentCount = await Student.count({
      where: { instituteId: institute.id },
    });

    return res.status(200).json({
      success: true,
      message: 'Profile retrieved successfully',
      data: {
        institute: {
          id: institute.id,
          name: institute.name,
          code: institute.code,
          email: institute.email,
          address: institute.address,
          contactPerson: institute.contactPerson,
          contactNumber: institute.contactNumber,
          licenseExpiry: institute.licenseExpiry,
          createdAt: institute.createdAt,
        },
        stats: {
          teacherCount,
          departmentCount,
          sectionCount,
          courseCount,
          studentCount,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving profile',
      error: error.message,
    });
  }
};

// Update institute profile
const updateProfile = async (req, res) => {
  try {
    const {
      name,
      address,
      contactPerson,
      contactNumber,
      password,
    } = req.body;

    // Update fields
    const updateData = {};
    if (name) updateData.name = name;
    if (address) updateData.address = address;
    if (contactPerson) updateData.contactPerson = contactPerson;
    if (contactNumber) updateData.contactNumber = contactNumber;
    if (password) updateData.password = password;

    // Update institute
    await req.institute.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: req.institute.id,
        name: req.institute.name,
        code: req.institute.code,
        email: req.institute.email,
        address: req.institute.address,
        contactPerson: req.institute.contactPerson,
        contactNumber: req.institute.contactNumber,
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
    const instituteId = req.institute.id;

    // Basic counts
    const teacherCount = await Teacher.count({ where: { instituteId } });
    const studentCount = await Student.count({ where: { instituteId } });
    const departmentCount = await Department.count({ where: { instituteId } });
    const courseCount = await Course.count({ where: { instituteId } });

    // Get attendance statistics
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todayAttendance = await Attendance.findAll({
      where: {
        instituteId,
        date: today,
      },
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      group: ['status'],
      raw: true,
    });

    // Format attendance stats
    const attendanceStats = {
      Present: 0,
      Late: 0,
      Absent: 0,
    };

    todayAttendance.forEach((stat) => {
      attendanceStats[stat.status] = parseInt(stat.count, 10);
    });

    // Recent teachers
    const recentTeachers = await Teacher.findAll({
      where: { instituteId },
      order: [['createdAt', 'DESC']],
      limit: 5,
      attributes: ['id', 'firstName', 'lastName', 'employeeId', 'createdAt'],
    });

    return res.status(200).json({
      success: true,
      message: 'Dashboard statistics retrieved successfully',
      data: {
        counts: {
          teacherCount,
          studentCount,
          departmentCount,
          courseCount,
        },
        todayAttendance: attendanceStats,
        recentTeachers,
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
  createTeacher,
  getAllTeachers,
  getTeacherById,
  updateTeacher,
  deleteTeacher,
  createDepartment,
  getAllDepartments,
  getProfile,
  updateProfile,
  getDashboardStats,
};