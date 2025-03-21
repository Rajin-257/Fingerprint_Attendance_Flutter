const Attendance = require('../models/attendance.model');
const { Student } = require('../models/student.model');
const Course = require('../models/course.model');
const Teacher = require('../models/teacher.model');
const Department = require('../models/department.model');
const Section = require('../models/section.model');
const { Op } = require('sequelize');
const sequelize = require('../config/db.config');

// Get attendance for institute
const getAttendanceForInstitute = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const courseId = req.query.courseId || null;
    const teacherId = req.query.teacherId || null;
    const studentId = req.query.studentId || null;
    const date = req.query.date || null;
    const status = req.query.status || null;

    // Filter options
    const whereClause = { instituteId: req.institute.id };
    if (courseId) whereClause.courseId = courseId;
    if (teacherId) whereClause.teacherId = teacherId;
    if (studentId) whereClause.studentId = studentId;
    if (date) whereClause.date = new Date(date);
    if (status) whereClause.status = status;

    // Get attendance records with pagination
    const { count, rows } = await Attendance.findAndCountAll({
      where: whereClause,
      attributes: [
        'id',
        'date',
        'status',
        'timeIn',
        'remarks',
        'fingerprintVerified',
        'createdAt',
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
      order: [['date', 'DESC'], ['createdAt', 'DESC']],
      limit,
      offset,
    });

    return res.status(200).json({
      success: true,
      message: 'Attendance records retrieved successfully',
      data: {
        attendance: rows,
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
      message: 'Error retrieving attendance records',
      error: error.message,
    });
  }
};

// Get daily attendance summary for institute
const getDailyAttendanceSummaryForInstitute = async (req, res) => {
  try {
    const date = req.query.date ? new Date(req.query.date) : new Date();
    date.setHours(0, 0, 0, 0);
    
    const departmentId = req.query.departmentId || null;
    const sectionId = req.query.sectionId || null;

    // Filter options
    const whereClause = { 
      instituteId: req.institute.id,
      date,
    };

    // Build course and student filters
    const courseWhere = {};
    if (departmentId) courseWhere.departmentId = departmentId;
    if (sectionId) courseWhere.sectionId = sectionId;

    // Get attendance statistics by status
    const statusCounts = await Attendance.findAll({
      where: whereClause,
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      include: [
        {
          model: Course,
          as: 'course',
          attributes: [],
          where: Object.keys(courseWhere).length > 0 ? courseWhere : undefined,
        },
      ],
      group: ['status'],
      raw: true,
    });

    // Format status counts
    const formattedStatusCounts = {
      Present: 0,
      Late: 0,
      Absent: 0,
      Total: 0,
    };

    statusCounts.forEach((count) => {
      formattedStatusCounts[count.status] = parseInt(count.count, 10);
      formattedStatusCounts.Total += parseInt(count.count, 10);
    });

    // Get attendance by department
    const departmentCounts = await Attendance.findAll({
      where: whereClause,
      attributes: [
        [sequelize.col('course.department.id'), 'departmentId'],
        [sequelize.col('course.department.name'), 'departmentName'],
        'status',
        [sequelize.fn('COUNT', sequelize.col('Attendance.id')), 'count'],
      ],
      include: [
        {
          model: Course,
          as: 'course',
          attributes: [],
          where: Object.keys(courseWhere).length > 0 ? courseWhere : undefined,
          include: [
            {
              model: Department,
              as: 'department',
              attributes: [],
            },
          ],
        },
      ],
      group: ['course.department.id', 'course.department.name', 'status'],
      raw: true,
    });

    // Format department counts
    const formattedDepartmentCounts = {};
    departmentCounts.forEach((count) => {
      const deptId = count.departmentId;
      const deptName = count.departmentName;
      const status = count.status;
      const countValue = parseInt(count.count, 10);

      if (!formattedDepartmentCounts[deptId]) {
        formattedDepartmentCounts[deptId] = {
          id: deptId,
          name: deptName,
          Present: 0,
          Late: 0,
          Absent: 0,
          Total: 0,
        };
      }

      formattedDepartmentCounts[deptId][status] = countValue;
      formattedDepartmentCounts[deptId].Total += countValue;
    });

    // Get recent attendance entries
    const recentAttendance = await Attendance.findAll({
      where: whereClause,
      attributes: [
        'id',
        'date',
        'status',
        'timeIn',
        'fingerprintVerified',
        'createdAt',
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
          include: [
            {
              model: Department,
              as: 'department',
              attributes: ['id', 'name'],
            },
          ],
          where: Object.keys(courseWhere).length > 0 ? courseWhere : undefined,
        },
        {
          model: Teacher,
          as: 'teacher',
          attributes: ['id', 'firstName', 'lastName'],
        },
      ],
      order: [['createdAt', 'DESC']],
      limit: 10,
    });

    return res.status(200).json({
      success: true,
      message: 'Daily attendance summary retrieved successfully',
      data: {
        date: date.toISOString().split('T')[0],
        statusCounts: formattedStatusCounts,
        departmentCounts: Object.values(formattedDepartmentCounts),
        recentAttendance,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving daily attendance summary',
      error: error.message,
    });
  }
};

// Get attendance statistics for institute
const getAttendanceStatisticsForInstitute = async (req, res) => {
  try {
    const startDate = req.query.startDate 
      ? new Date(req.query.startDate) 
      : new Date(new Date().setDate(new Date().getDate() - 30));
    
    const endDate = req.query.endDate 
      ? new Date(req.query.endDate) 
      : new Date();
    
    // Ensure dates are at the start and end of day
    startDate.setHours(0, 0, 0, 0);
    endDate.setHours(23, 59, 59, 999);
    
    const departmentId = req.query.departmentId || null;
    const sectionId = req.query.sectionId || null;
    const courseId = req.query.courseId || null;

    // Filter options
    const whereClause = { 
      instituteId: req.institute.id,
      date: {
        [Op.between]: [startDate, endDate],
      },
    };
    if (courseId) whereClause.courseId = courseId;

    // Build course filter for department/section queries
    const courseWhere = {};
    if (departmentId) courseWhere.departmentId = departmentId;
    if (sectionId) courseWhere.sectionId = sectionId;

    // Get overall attendance statistics
    const overallStats = await Attendance.findAll({
      where: whereClause,
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      include: [
        {
          model: Course,
          as: 'course',
          attributes: [],
          where: Object.keys(courseWhere).length > 0 ? courseWhere : undefined,
        },
      ],
      group: ['status'],
      raw: true,
    });

    // Format overall statistics
    const formattedOverallStats = {
      Present: 0,
      Late: 0,
      Absent: 0,
      Total: 0,
    };

    overallStats.forEach((stat) => {
      formattedOverallStats[stat.status] = parseInt(stat.count, 10);
      formattedOverallStats.Total += parseInt(stat.count, 10);
    });

    // Calculate percentages
    formattedOverallStats.PresentPercentage = formattedOverallStats.Total === 0 
      ? 0 
      : ((formattedOverallStats.Present / formattedOverallStats.Total) * 100).toFixed(2);
    
    formattedOverallStats.LatePercentage = formattedOverallStats.Total === 0 
      ? 0 
      : ((formattedOverallStats.Late / formattedOverallStats.Total) * 100).toFixed(2);
    
    formattedOverallStats.AbsentPercentage = formattedOverallStats.Total === 0 
      ? 0 
      : ((formattedOverallStats.Absent / formattedOverallStats.Total) * 100).toFixed(2);

    // Get daily attendance statistics
    const dailyStats = await Attendance.findAll({
      where: whereClause,
      attributes: [
        [sequelize.fn('DATE', sequelize.col('date')), 'day'],
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      include: [
        {
          model: Course,
          as: 'course',
          attributes: [],
          where: Object.keys(courseWhere).length > 0 ? courseWhere : undefined,
        },
      ],
      group: [
        sequelize.fn('DATE', sequelize.col('date')),
        'status',
      ],
      order: [[sequelize.fn('DATE', sequelize.col('date')), 'ASC']],
      raw: true,
    });

    // Format daily statistics
    const formattedDailyStats = {};
    dailyStats.forEach((stat) => {
      const day = stat.day;
      const status = stat.status;
      const count = parseInt(stat.count, 10);

      if (!formattedDailyStats[day]) {
        formattedDailyStats[day] = {
          date: day,
          Present: 0,
          Late: 0,
          Absent: 0,
          Total: 0,
        };
      }

      formattedDailyStats[day][status] = count;
      formattedDailyStats[day].Total += count;
    });

    // Convert to array and sort by date
    const dailyStatsArray = Object.values(formattedDailyStats).sort((a, b) => {
      return new Date(a.date) - new Date(b.date);
    });

    return res.status(200).json({
      success: true,
      message: 'Attendance statistics retrieved successfully',
      data: {
        period: {
          startDate: startDate.toISOString().split('T')[0],
          endDate: endDate.toISOString().split('T')[0],
        },
        overallStats: formattedOverallStats,
        dailyStats: dailyStatsArray,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving attendance statistics',
      error: error.message,
    });
  }
};

// Get attendance for teacher
const getAttendanceForTeacher = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const courseId = req.query.courseId || null;
    const studentId = req.query.studentId || null;
    const date = req.query.date || null;
    const status = req.query.status || null;

    // Filter options
    const whereClause = { 
      teacherId: req.teacher.id,
      instituteId: req.teacher.instituteId,
    };
    if (courseId) whereClause.courseId = courseId;
    if (studentId) whereClause.studentId = studentId;
    if (date) whereClause.date = new Date(date);
    if (status) whereClause.status = status;

    // Get attendance records with pagination
    const { count, rows } = await Attendance.findAndCountAll({
      where: whereClause,
      attributes: [
        'id',
        'date',
        'status',
        'timeIn',
        'remarks',
        'fingerprintVerified',
        'syncedFromOffline',
        'createdAt',
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
      ],
      order: [['date', 'DESC'], ['createdAt', 'DESC']],
      limit,
      offset,
    });

    return res.status(200).json({
      success: true,
      message: 'Attendance records retrieved successfully',
      data: {
        attendance: rows,
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
      message: 'Error retrieving attendance records',
      error: error.message,
    });
  }
};

// Get daily attendance summary for teacher
const getDailyAttendanceSummaryForTeacher = async (req, res) => {
  try {
    const date = req.query.date ? new Date(req.query.date) : new Date();
    date.setHours(0, 0, 0, 0);
    
    const courseId = req.query.courseId || null;

    // Filter options
    const whereClause = { 
      teacherId: req.teacher.id,
      instituteId: req.teacher.instituteId,
      date,
    };
    if (courseId) whereClause.courseId = courseId;

    // Get attendance statistics by status
    const statusCounts = await Attendance.findAll({
      where: whereClause,
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      group: ['status'],
      raw: true,
    });

    // Format status counts
    const formattedStatusCounts = {
      Present: 0,
      Late: 0,
      Absent: 0,
      Total: 0,
    };

    statusCounts.forEach((count) => {
      formattedStatusCounts[count.status] = parseInt(count.count, 10);
      formattedStatusCounts.Total += parseInt(count.count, 10);
    });

    // Get attendance by course
    const courseCounts = await Attendance.findAll({
      where: whereClause,
      attributes: [
        'courseId',
        [sequelize.col('course.name'), 'courseName'],
        [sequelize.col('course.code'), 'courseCode'],
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      include: [
        {
          model: Course,
          as: 'course',
          attributes: [],
        },
      ],
      group: ['courseId', 'course.name', 'course.code', 'status'],
      raw: true,
    });

    // Format course counts
    const formattedCourseCounts = {};
    courseCounts.forEach((count) => {
      const courseId = count.courseId;
      const courseName = count.courseName;
      const courseCode = count.courseCode;
      const status = count.status;
      const countValue = parseInt(count.count, 10);

      if (!formattedCourseCounts[courseId]) {
        formattedCourseCounts[courseId] = {
          id: courseId,
          name: courseName,
          code: courseCode,
          Present: 0,
          Late: 0,
          Absent: 0,
          Total: 0,
        };
      }

      formattedCourseCounts[courseId][status] = countValue;
      formattedCourseCounts[courseId].Total += countValue;
    });

    // Get recent attendance entries
    const recentAttendance = await Attendance.findAll({
      where: whereClause,
      attributes: [
        'id',
        'date',
        'status',
        'timeIn',
        'fingerprintVerified',
        'syncedFromOffline',
        'createdAt',
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
      ],
      order: [['createdAt', 'DESC']],
      limit: 10,
    });

    return res.status(200).json({
      success: true,
      message: 'Daily attendance summary retrieved successfully',
      data: {
        date: date.toISOString().split('T')[0],
        statusCounts: formattedStatusCounts,
        courseCounts: Object.values(formattedCourseCounts),
        recentAttendance,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving daily attendance summary',
      error: error.message,
    });
  }
};

module.exports = {
  getAttendanceForInstitute,
  getDailyAttendanceSummaryForInstitute,
  getAttendanceStatisticsForInstitute,
  getAttendanceForTeacher,
  getDailyAttendanceSummaryForTeacher,
};