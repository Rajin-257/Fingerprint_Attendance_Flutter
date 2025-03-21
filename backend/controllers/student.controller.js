const { Student, StudentCourse } = require('../models/student.model');
const Department = require('../models/department.model');
const Section = require('../models/section.model');
const Course = require('../models/course.model');
const Teacher = require('../models/teacher.model');
const Attendance = require('../models/attendance.model');
const { Op } = require('sequelize');
const sequelize = require('../config/db.config');

// Get all students for institute
const getAllStudentsForInstitute = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const departmentId = req.query.departmentId || null;
    const sectionId = req.query.sectionId || null;

    // Filter options
    const whereClause = { instituteId: req.institute.id };
    if (departmentId) whereClause.departmentId = departmentId;
    if (sectionId) whereClause.sectionId = sectionId;
    
    if (search) {
      whereClause[Op.or] = [
        { firstName: { [Op.like]: `%${search}%` } },
        { lastName: { [Op.like]: `%${search}%` } },
        { registrationNumber: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
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
        'contactNumber',
        'active',
        [
          sequelize.literal(
            'CASE WHEN fingerprint IS NULL THEN FALSE ELSE TRUE END'
          ),
          'hasFingerprint',
        ],
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
      order: [['createdAt', 'DESC']],
      limit,
      offset,
    });

    return res.status(200).json({
      success: true,
      message: 'Students retrieved successfully',
      data: {
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
      message: 'Error retrieving students',
      error: error.message,
    });
  }
};

// Get student by ID for institute
const getStudentByIdForInstitute = async (req, res) => {
  try {
    const { id } = req.params;

    const student = await Student.findOne({
      where: { id, instituteId: req.institute.id },
      attributes: [
        'id',
        'registrationNumber',
        'firstName',
        'lastName',
        'email',
        'dateOfBirth',
        'gender',
        'contactNumber',
        'address',
        [
          sequelize.literal(
            'CASE WHEN fingerprint IS NULL THEN FALSE ELSE TRUE END'
          ),
          'hasFingerprint',
        ],
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
        {
          model: Course,
          as: 'courses',
          attributes: ['id', 'name', 'code'],
          through: { attributes: ['enrollmentDate', 'status'] },
          include: [
            {
              model: Teacher,
              as: 'teacher',
              attributes: ['id', 'firstName', 'lastName'],
            },
          ],
        },
      ],
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found',
      });
    }

    // Get attendance statistics for current month
    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();
    
    const attendanceStats = await Attendance.findAll({
      where: {
        studentId: id,
        [Op.and]: [
          sequelize.where(
            sequelize.fn('MONTH', sequelize.col('date')),
            currentMonth
          ),
          sequelize.where(
            sequelize.fn('YEAR', sequelize.col('date')),
            currentYear
          ),
        ],
      },
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      group: ['status'],
      raw: true,
    });

    // Format attendance stats
    const formattedStats = {
      Present: 0,
      Late: 0,
      Absent: 0,
    };

    attendanceStats.forEach((stat) => {
      formattedStats[stat.status] = parseInt(stat.count, 10);
    });

    return res.status(200).json({
      success: true,
      message: 'Student retrieved successfully',
      data: {
        student,
        attendanceStats: formattedStats,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving student',
      error: error.message,
    });
  }
};

// Update student for institute
const updateStudentForInstitute = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      firstName,
      lastName,
      email,
      contactNumber,
      address,
      active,
      departmentId,
      sectionId,
    } = req.body;

    // Find student
    const student = await Student.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found',
      });
    }

    // Validate department and section if provided
    if (departmentId) {
      const department = await Department.findOne({
        where: { id: departmentId, instituteId: req.institute.id },
      });

      if (!department) {
        return res.status(400).json({
          success: false,
          message: 'Invalid department',
        });
      }
    }

    if (sectionId) {
      const section = await Section.findOne({
        where: { 
          id: sectionId, 
          instituteId: req.institute.id,
          departmentId: departmentId || student.departmentId,
        },
      });

      if (!section) {
        return res.status(400).json({
          success: false,
          message: 'Invalid section',
        });
      }
    }

    // Update fields
    const updateData = {};
    if (firstName) updateData.firstName = firstName;
    if (lastName) updateData.lastName = lastName;
    if (email) updateData.email = email;
    if (contactNumber) updateData.contactNumber = contactNumber;
    if (address !== undefined) updateData.address = address;
    if (active !== undefined) updateData.active = active;
    if (departmentId) updateData.departmentId = departmentId;
    if (sectionId) updateData.sectionId = sectionId;

    // Update student
    await student.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Student updated successfully',
      data: {
        id: student.id,
        registrationNumber: student.registrationNumber,
        firstName: student.firstName,
        lastName: student.lastName,
        email: student.email,
        active: student.active,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating student',
      error: error.message,
    });
  }
};

// Delete student for institute
const deleteStudentForInstitute = async (req, res) => {
  try {
    const { id } = req.params;

    // Find student
    const student = await Student.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found',
      });
    }

    // Check if student has attendance records
    const attendanceCount = await Attendance.count({
      where: { studentId: id },
    });

    if (attendanceCount > 0) {
      return res.status(400).json({
        success: false,
        message:
          'Cannot delete student with attendance records. Deactivate instead.',
      });
    }

    // Delete student course enrollments
    await StudentCourse.destroy({
      where: { studentId: id },
    });

    // Delete student
    await student.destroy();

    return res.status(200).json({
      success: true,
      message: 'Student deleted successfully',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error deleting student',
      error: error.message,
    });
  }
};

// Get attendance report for institute
const getAttendanceReportForInstitute = async (req, res) => {
  try {
    const { courseId, departmentId, sectionId, startDate, endDate } = req.query;

    // Validate at least one filter is provided
    if (!courseId && !departmentId && !sectionId) {
      return res.status(400).json({
        success: false,
        message: 'At least one filter (courseId, departmentId, or sectionId) is required',
      });
    }

    // Build filters
    const whereClause = { instituteId: req.institute.id };
    if (courseId) whereClause.courseId = courseId;
    
    // Build student filters
    const studentWhere = { instituteId: req.institute.id };
    if (departmentId) studentWhere.departmentId = departmentId;
    if (sectionId) studentWhere.sectionId = sectionId;

    // Build date filter
    const dateFilter = {};
    if (startDate && endDate) {
      dateFilter.date = {
        [Op.between]: [new Date(startDate), new Date(endDate)],
      };
    } else if (startDate) {
      dateFilter.date = {
        [Op.gte]: new Date(startDate),
      };
    } else if (endDate) {
      dateFilter.date = {
        [Op.lte]: new Date(endDate),
      };
    }

    // Get attendance records
    let attendanceRecords;
    
    if (courseId) {
      // If courseId is provided, get attendance for that course
      attendanceRecords = await Attendance.findAll({
        where: {
          ...whereClause,
          ...dateFilter,
        },
        attributes: [
          'id', 'date', 'status', 'studentId', 'courseId', 
          'timeIn', 'fingerprintVerified', 'createdAt'
        ],
        include: [
          {
            model: Student,
            as: 'student',
            attributes: ['id', 'registrationNumber', 'firstName', 'lastName'],
            where: studentWhere,
          },
          {
            model: Course,
            as: 'course',
            attributes: ['id', 'name', 'code'],
          },
          {
            model: Teacher,
            as: 'teacher',
            attributes: ['id', 'firstName', 'lastName', 'employeeId'],
          },
        ],
        order: [['date', 'DESC'], ['student', 'firstName', 'ASC']],
      });
    } else {
      // If no courseId, get students first and then their attendance
      const students = await Student.findAll({
        where: studentWhere,
        attributes: ['id', 'registrationNumber', 'firstName', 'lastName'],
      });

      const studentIds = students.map(student => student.id);

      if (studentIds.length === 0) {
        return res.status(200).json({
          success: true,
          message: 'No students found with the given criteria',
          data: {
            attendanceRecords: [],
          },
        });
      }

      attendanceRecords = await Attendance.findAll({
        where: {
          studentId: { [Op.in]: studentIds },
          instituteId: req.institute.id,
          ...dateFilter,
        },
        attributes: [
          'id', 'date', 'status', 'studentId', 'courseId', 
          'timeIn', 'fingerprintVerified', 'createdAt'
        ],
        include: [
          {
            model: Student,
            as: 'student',
            attributes: ['id', 'registrationNumber', 'firstName', 'lastName'],
          },
          {
            model: Course,
            as: 'course',
            attributes: ['id', 'name', 'code'],
          },
          {
            model: Teacher,
            as: 'teacher',
            attributes: ['id', 'firstName', 'lastName', 'employeeId'],
          },
        ],
        order: [['date', 'DESC'], ['student', 'firstName', 'ASC']],
      });
    }

    // Process data into report format
    const attendanceByDate = {};
    const studentNames = {};
    const courseNames = {};
    
    attendanceRecords.forEach((record) => {
      const dateStr = record.date.toISOString().split('T')[0];
      const studentId = record.student.id;
      const courseId = record.course.id;
      
      // Store student and course names for reference
      studentNames[studentId] = `${record.student.firstName} ${record.student.lastName} (${record.student.registrationNumber})`;
      courseNames[courseId] = `${record.course.name} (${record.course.code})`;
      
      if (!attendanceByDate[dateStr]) {
        attendanceByDate[dateStr] = {};
      }
      
      if (!attendanceByDate[dateStr][courseId]) {
        attendanceByDate[dateStr][courseId] = {};
      }
      
      attendanceByDate[dateStr][courseId][studentId] = {
        status: record.status,
        timeIn: record.timeIn,
        fingerprintVerified: record.fingerprintVerified,
      };
    });

    // Generate summary
    const summary = {
      totalDays: Object.keys(attendanceByDate).length,
      totalStudents: Object.keys(studentNames).length,
      totalCourses: Object.keys(courseNames).length,
      statusCounts: {
        Present: attendanceRecords.filter(r => r.status === 'Present').length,
        Late: attendanceRecords.filter(r => r.status === 'Late').length,
        Absent: attendanceRecords.filter(r => r.status === 'Absent').length,
      },
    };

    return res.status(200).json({
      success: true,
      message: 'Attendance report generated successfully',
      data: {
        summary,
        students: studentNames,
        courses: courseNames,
        dates: Object.keys(attendanceByDate).sort().reverse(),
        attendance: attendanceByDate,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error generating attendance report',
      error: error.message,
    });
  }
};

module.exports = {
  getAllStudentsForInstitute,
  getStudentByIdForInstitute,
  updateStudentForInstitute,
  deleteStudentForInstitute,
  getAttendanceReportForInstitute,
};