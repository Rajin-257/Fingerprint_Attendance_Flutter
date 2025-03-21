const Course = require('../models/course.model');
const Department = require('../models/department.model');
const Section = require('../models/section.model');
const Teacher = require('../models/teacher.model');
const { Student, StudentCourse } = require('../models/student.model');
const Attendance = require('../models/attendance.model');
const { Op } = require('sequelize');

// Create course
const createCourse = async (req, res) => {
  try {
    const {
      name,
      code,
      description,
      creditHours,
      schedule,
      departmentId,
      sectionId,
      teacherId,
    } = req.body;

    // Check if department exists and belongs to institute
    const department = await Department.findOne({
      where: { id: departmentId, instituteId: req.institute.id },
    });

    if (!department) {
      return res.status(400).json({
        success: false,
        message: 'Invalid department',
      });
    }

    // Check if section exists and belongs to department
    const section = await Section.findOne({
      where: { id: sectionId, departmentId, instituteId: req.institute.id },
    });

    if (!section) {
      return res.status(400).json({
        success: false,
        message: 'Invalid section',
      });
    }

    // Check if teacher exists and belongs to institute
    let teacher = null;
    if (teacherId) {
      teacher = await Teacher.findOne({
        where: { id: teacherId, instituteId: req.institute.id, active: true },
      });

      if (!teacher) {
        return res.status(400).json({
          success: false,
          message: 'Invalid teacher',
        });
      }
    }

    // Check if course code already exists in this section
    const existingCourse = await Course.findOne({
      where: { code, sectionId, departmentId },
    });

    if (existingCourse) {
      return res.status(409).json({
        success: false,
        message: 'Course with this code already exists in the section',
      });
    }

    // Create new course
    const newCourse = await Course.create({
      name,
      code,
      description,
      creditHours: creditHours || 3.0,
      schedule: schedule || null,
      active: true,
      departmentId,
      sectionId,
      teacherId: teacher ? teacher.id : null,
      instituteId: req.institute.id,
    });

    return res.status(201).json({
      success: true,
      message: 'Course created successfully',
      data: {
        id: newCourse.id,
        name: newCourse.name,
        code: newCourse.code,
        departmentId: newCourse.departmentId,
        sectionId: newCourse.sectionId,
        teacherId: newCourse.teacherId,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating course',
      error: error.message,
    });
  }
};

// Get all courses
const getAllCourses = async (req, res) => {
  try {
    const departmentId = req.query.departmentId || null;
    const sectionId = req.query.sectionId || null;
    const teacherId = req.query.teacherId || null;

    // Filter options
    const whereClause = { instituteId: req.institute.id };
    if (departmentId) whereClause.departmentId = departmentId;
    if (sectionId) whereClause.sectionId = sectionId;
    if (teacherId) whereClause.teacherId = teacherId;

    // Get courses
    const courses = await Course.findAll({
      where: whereClause,
      attributes: [
        'id',
        'name',
        'code',
        'description',
        'creditHours',
        'schedule',
        'active',
        'createdAt',
      ],
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
        {
          model: Teacher,
          as: 'teacher',
          attributes: ['id', 'firstName', 'lastName', 'employeeId'],
        },
      ],
      order: [['name', 'ASC']],
    });

    return res.status(200).json({
      success: true,
      message: 'Courses retrieved successfully',
      data: courses,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving courses',
      error: error.message,
    });
  }
};

// Get course by ID
const getCourseById = async (req, res) => {
  try {
    const { id } = req.params;

    const course = await Course.findOne({
      where: { id, instituteId: req.institute.id },
      attributes: [
        'id',
        'name',
        'code',
        'description',
        'creditHours',
        'schedule',
        'active',
        'departmentId',
        'sectionId',
        'teacherId',
        'createdAt',
      ],
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
        {
          model: Teacher,
          as: 'teacher',
          attributes: ['id', 'firstName', 'lastName', 'employeeId', 'email'],
        },
      ],
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found',
      });
    }

    // Get course statistics
    const studentCount = await StudentCourse.count({
      where: { courseId: id },
    });

    const attendanceCount = await Attendance.count({
      where: { courseId: id },
    });

    // Get students enrolled in this course
    const students = await Student.findAll({
      include: [
        {
          model: Course,
          as: 'courses',
          where: { id },
          required: true,
          attributes: [],
          through: { attributes: [] },
        },
      ],
      attributes: ['id', 'firstName', 'lastName', 'registrationNumber'],
      order: [['firstName', 'ASC'], ['lastName', 'ASC']],
      limit: 10, // Limiting to avoid large response
    });

    return res.status(200).json({
      success: true,
      message: 'Course retrieved successfully',
      data: {
        course,
        stats: {
          studentCount,
          attendanceCount,
        },
        students,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving course',
      error: error.message,
    });
  }
};

// Update course
const updateCourse = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      description,
      creditHours,
      schedule,
      active,
      teacherId,
    } = req.body;

    // Find course
    const course = await Course.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found',
      });
    }

    // Check if teacher exists and belongs to institute
    if (teacherId) {
      const teacher = await Teacher.findOne({
        where: { id: teacherId, instituteId: req.institute.id, active: true },
      });

      if (!teacher) {
        return res.status(400).json({
          success: false,
          message: 'Invalid teacher',
        });
      }
    }

    // Update fields
    const updateData = {};
    if (name) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (creditHours) updateData.creditHours = creditHours;
    if (schedule) updateData.schedule = schedule;
    if (active !== undefined) updateData.active = active;
    if (teacherId !== undefined) updateData.teacherId = teacherId || null;

    // Update course
    await course.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Course updated successfully',
      data: {
        id: course.id,
        name: course.name,
        code: course.code,
        description: course.description,
        creditHours: course.creditHours,
        active: course.active,
        teacherId: course.teacherId,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating course',
      error: error.message,
    });
  }
};

// Delete course
const deleteCourse = async (req, res) => {
  try {
    const { id } = req.params;

    // Find course
    const course = await Course.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found',
      });
    }

    // Check if course has associated students or attendance records
    const studentCount = await StudentCourse.count({
      where: { courseId: id },
    });

    const attendanceCount = await Attendance.count({
      where: { courseId: id },
    });

    if (studentCount > 0 || attendanceCount > 0) {
      return res.status(400).json({
        success: false,
        message:
          'Cannot delete course with enrolled students or attendance records. Deactivate it instead.',
      });
    }

    // Delete course
    await course.destroy();

    return res.status(200).json({
      success: true,
      message: 'Course deleted successfully',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error deleting course',
      error: error.message,
    });
  }
};

// Add students to course
const addStudentsToCourse = async (req, res) => {
  try {
    const { id } = req.params;
    const { studentIds } = req.body;

    if (!studentIds || !Array.isArray(studentIds) || studentIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Student IDs must be provided as an array',
      });
    }

    // Find course
    const course = await Course.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found',
      });
    }

    // Verify students belong to institute
    const students = await Student.findAll({
      where: {
        id: { [Op.in]: studentIds },
        instituteId: req.institute.id,
        active: true,
      },
    });

    if (students.length !== studentIds.length) {
      return res.status(400).json({
        success: false,
        message: 'One or more invalid student IDs',
      });
    }

    // Get existing enrollments to avoid duplicates
    const existingEnrollments = await StudentCourse.findAll({
      where: {
        courseId: id,
        studentId: { [Op.in]: studentIds },
      },
      attributes: ['studentId'],
    });

    const existingStudentIds = existingEnrollments.map(
      (enrollment) => enrollment.studentId
    );

    // Filter out already enrolled students
    const newStudentIds = studentIds.filter(
      (studentId) => !existingStudentIds.includes(studentId)
    );

    if (newStudentIds.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'All students are already enrolled in this course',
        data: {
          enrolledCount: 0,
          totalCount: studentIds.length,
        },
      });
    }

    // Create new enrollments
    const enrollments = newStudentIds.map((studentId) => ({
      studentId,
      courseId: id,
      enrollmentDate: new Date(),
      status: 'Active',
    }));

    await StudentCourse.bulkCreate(enrollments);

    return res.status(200).json({
      success: true,
      message: 'Students added to course successfully',
      data: {
        enrolledCount: newStudentIds.length,
        totalCount: studentIds.length,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error adding students to course',
      error: error.message,
    });
  }
};

// Remove students from course
const removeStudentsFromCourse = async (req, res) => {
  try {
    const { id } = req.params;
    const { studentIds } = req.body;

    if (!studentIds || !Array.isArray(studentIds) || studentIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Student IDs must be provided as an array',
      });
    }

    // Find course
    const course = await Course.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found',
      });
    }

    // Check if there are attendance records for these students
    const attendanceCount = await Attendance.count({
      where: {
        courseId: id,
        studentId: { [Op.in]: studentIds },
      },
    });

    if (attendanceCount > 0) {
      return res.status(400).json({
        success: false,
        message:
          'Cannot remove students with attendance records from course',
      });
    }

    // Delete enrollments
    const result = await StudentCourse.destroy({
      where: {
        courseId: id,
        studentId: { [Op.in]: studentIds },
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Students removed from course successfully',
      data: {
        removedCount: result,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error removing students from course',
      error: error.message,
    });
  }
};

// Get students in course
const getStudentsInCourse = async (req, res) => {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';

    // Find course
    const course = await Course.findOne({
      where: { id, instituteId: req.institute.id },
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
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found',
      });
    }

    // Filter options for students
    const whereClause = {
      instituteId: req.institute.id,
      '$courses.id$': id,
    };

    if (search) {
      whereClause[Op.or] = [
        { firstName: { [Op.like]: `%${search}%` } },
        { lastName: { [Op.like]: `%${search}%` } },
        { registrationNumber: { [Op.like]: `%${search}%` } },
      ];
    }

    // Get students with pagination
    const { count, rows } = await Student.findAndCountAll({
      where: whereClause,
      attributes: [
        'id',
        'registrationNumber',
        'firstName',
        'lastName',
        'email',
        'gender',
        'active',
      ],
      include: [
        {
          model: Course,
          as: 'courses',
          where: { id },
          attributes: [],
          through: {
            attributes: ['enrollmentDate', 'status'],
          },
        },
      ],
      order: [['firstName', 'ASC'], ['lastName', 'ASC']],
      distinct: true,
      limit,
      offset,
    });

    return res.status(200).json({
      success: true,
      message: 'Students in course retrieved successfully',
      data: {
        course,
        students: rows,
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
      message: 'Error retrieving students in course',
      error: error.message,
    });
  }
};

module.exports = {
  createCourse,
  getAllCourses,
  getCourseById,
  updateCourse,
  deleteCourse,
  addStudentsToCourse,
  removeStudentsFromCourse,
  getStudentsInCourse,
};