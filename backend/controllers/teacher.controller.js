const { Student, StudentCourse } = require('../models/student.model');
const Course = require('../models/course.model');
const Department = require('../models/department.model');
const Section = require('../models/section.model');
const Attendance = require('../models/attendance.model');
const Institute = require('../models/institute.model');
const { Op } = require('sequelize');
const sequelize = require('../config/db.config');
const crypto = require('crypto');
const authConfig = require('../config/auth.config');

// Helper function to encrypt fingerprint data
const encryptFingerprint = (fingerprintData) => {
  // Use a secure encryption method for fingerprint data
  const algorithm = 'aes-256-cbc';
  const key = Buffer.from(authConfig.fingerprintEncryptionKey, 'utf8');
  const iv = crypto.randomBytes(16);
  
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  let encrypted = cipher.update(fingerprintData, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  return {
    iv: iv.toString('hex'),
    data: encrypted,
  };
};

// Helper function to decrypt fingerprint data
const decryptFingerprint = (encryptedData) => {
  try {
    const algorithm = 'aes-256-cbc';
    const key = Buffer.from(authConfig.fingerprintEncryptionKey, 'utf8');
    const iv = Buffer.from(encryptedData.iv, 'hex');
    
    const decipher = crypto.createDecipheriv(algorithm, key, iv);
    let decrypted = decipher.update(encryptedData.data, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  } catch (error) {
    console.error('Error decrypting fingerprint:', error);
    return null;
  }
};

// Create a new student
const createStudent = async (req, res) => {
  try {
    const {
      registrationNumber,
      firstName,
      lastName,
      email,
      dateOfBirth,
      gender,
      contactNumber,
      address,
      fingerprint,
      departmentId,
      sectionId,
      courseIds,
    } = req.body;

    // Validate that department and section belong to teacher's institute
    const department = await Department.findOne({
      where: {
        id: departmentId,
        instituteId: req.teacher.instituteId,
      },
    });

    if (!department) {
      return res.status(400).json({
        success: false,
        message: 'Invalid department',
      });
    }

    const section = await Section.findOne({
      where: {
        id: sectionId,
        departmentId,
        instituteId: req.teacher.instituteId,
      },
    });

    if (!section) {
      return res.status(400).json({
        success: false,
        message: 'Invalid section',
      });
    }

    // Check if student with registration number already exists
    const existingStudent = await Student.findOne({
      where: {
        registrationNumber,
        instituteId: req.teacher.instituteId,
      },
    });

    if (existingStudent) {
      return res.status(409).json({
        success: false,
        message: 'Student with this registration number already exists',
      });
    }

    // Process fingerprint data if provided
    let encryptedFingerprint = null;
    if (fingerprint) {
      encryptedFingerprint = JSON.stringify(encryptFingerprint(fingerprint));
    }

    // Create student in a transaction
    const result = await sequelize.transaction(async (t) => {
      // Create student
      const newStudent = await Student.create(
        {
          registrationNumber,
          firstName,
          lastName,
          email,
          dateOfBirth,
          gender,
          contactNumber,
          address,
          fingerprint: encryptedFingerprint,
          active: true,
          instituteId: req.teacher.instituteId,
          departmentId,
          sectionId,
          addedBy: req.teacher.id,
        },
        { transaction: t }
      );

      // Add student to courses if courseIds provided
      if (courseIds && courseIds.length > 0) {
        // Verify courses belong to teacher
        const courses = await Course.findAll({
          where: {
            id: { [Op.in]: courseIds },
            teacherId: req.teacher.id,
          },
          transaction: t,
        });

        if (courses.length !== courseIds.length) {
          throw new Error('One or more invalid course IDs');
        }

        // Create student-course enrollments
        const enrollments = courses.map((course) => ({
          studentId: newStudent.id,
          courseId: course.id,
          enrollmentDate: new Date(),
          status: 'Active',
        }));

        await StudentCourse.bulkCreate(enrollments, { transaction: t });
      }

      return newStudent;
    });

    return res.status(201).json({
      success: true,
      message: 'Student created successfully',
      data: {
        id: result.id,
        registrationNumber: result.registrationNumber,
        firstName: result.firstName,
        lastName: result.lastName,
        hasFingerprint: !!encryptedFingerprint,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating student',
      error: error.message,
    });
  }
};

// Get all students
const getAllStudents = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const courseId = req.query.courseId || null;

    // Filter options
    let whereClause = {};
    
    if (courseId) {
      // If courseId is provided, find students in that course
      whereClause = {
        '$courses.id$': courseId,
        '$courses.teacherId$': req.teacher.id,
      };
    } else {
      // Otherwise find all students added by this teacher
      whereClause = { addedBy: req.teacher.id };
    }

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
          model: Course,
          as: 'courses',
          attributes: ['id', 'name', 'code'],
          through: { attributes: [] },
          required: courseId ? true : false,
        },
      ],
      order: [['firstName', 'ASC'], ['lastName', 'ASC']],
      distinct: true,
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

// Get student by ID
const getStudentById = async (req, res) => {
  try {
    const { id } = req.params;

    const student = await Student.findOne({
      where: { id, addedBy: req.teacher.id },
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
          model: Course,
          as: 'courses',
          attributes: ['id', 'name', 'code'],
          through: { attributes: ['enrollmentDate', 'status'] },
        },
      ],
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found',
      });
    }

    // Get attendance statistics
    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();
    
    const attendanceStats = await Attendance.findAll({
      where: {
        studentId: id,
        teacherId: req.teacher.id,
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

// Update student
const updateStudent = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      firstName,
      lastName,
      email,
      contactNumber,
      address,
      fingerprint,
      active,
      courseIds,
    } = req.body;

    // Find student
    const student = await Student.findOne({
      where: { id, addedBy: req.teacher.id },
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found',
      });
    }

    // Process fingerprint data if provided
    let encryptedFingerprint = null;
    if (fingerprint) {
      encryptedFingerprint = JSON.stringify(encryptFingerprint(fingerprint));
    }

    // Update student in a transaction
    await sequelize.transaction(async (t) => {
      // Update fields
      const updateData = {};
      if (firstName) updateData.firstName = firstName;
      if (lastName) updateData.lastName = lastName;
      if (email) updateData.email = email;
      if (contactNumber) updateData.contactNumber = contactNumber;
      if (address) updateData.address = address;
      if (fingerprint) updateData.fingerprint = encryptedFingerprint;
      if (active !== undefined) updateData.active = active;

      // Update student
      await student.update(updateData, { transaction: t });

      // Update course enrollments if provided
      if (courseIds && Array.isArray(courseIds)) {
        // Verify courses belong to teacher
        const validCourses = await Course.findAll({
          where: {
            id: { [Op.in]: courseIds },
            teacherId: req.teacher.id,
          },
          transaction: t,
        });

        const validCourseIds = validCourses.map((course) => course.id);

        // Get current enrollments
        const currentEnrollments = await StudentCourse.findAll({
          where: { studentId: id },
          transaction: t,
        });

        const currentCourseIds = currentEnrollments.map(
          (enrollment) => enrollment.courseId
        );

        // Courses to add
        const coursesToAdd = validCourseIds.filter(
          (courseId) => !currentCourseIds.includes(courseId)
        );

        // Courses to remove
        const coursesToRemove = currentCourseIds.filter(
          (courseId) => !validCourseIds.includes(courseId)
        );

        // Add new enrollments
        if (coursesToAdd.length > 0) {
          const newEnrollments = coursesToAdd.map((courseId) => ({
            studentId: id,
            courseId,
            enrollmentDate: new Date(),
            status: 'Active',
          }));

          await StudentCourse.bulkCreate(newEnrollments, { transaction: t });
        }

        // Remove old enrollments
        if (coursesToRemove.length > 0) {
          await StudentCourse.destroy({
            where: {
              studentId: id,
              courseId: { [Op.in]: coursesToRemove },
            },
            transaction: t,
          });
        }
      }
    });

    return res.status(200).json({
      success: true,
      message: 'Student updated successfully',
      data: {
        id: student.id,
        registrationNumber: student.registrationNumber,
        firstName: student.firstName,
        lastName: student.lastName,
        hasFingerprint: !!encryptedFingerprint || !!student.fingerprint,
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

// Take attendance
const takeAttendance = async (req, res) => {
  try {
    const {
      studentId,
      courseId,
      date,
      status,
      timeIn,
      remarks,
      fingerprintVerified,
      offlineId,
    } = req.body;

    // Validate student and course
    const student = await Student.findOne({
      where: {
        id: studentId,
        active: true,
      },
      include: [
        {
          model: Course,
          as: 'courses',
          where: { id: courseId, teacherId: req.teacher.id },
          required: true,
        },
      ],
    });

    if (!student) {
      return res.status(400).json({
        success: false,
        message: 'Invalid student or course',
      });
    }

    // Check if attendance already exists for this student, course, and date
    const existingAttendance = await Attendance.findOne({
      where: {
        studentId,
        courseId,
        date,
        teacherId: req.teacher.id,
      },
    });

    if (existingAttendance) {
      // Update existing attendance
      await existingAttendance.update({
        status,
        timeIn: timeIn || existingAttendance.timeIn,
        remarks: remarks || existingAttendance.remarks,
        fingerprintVerified: fingerprintVerified || existingAttendance.fingerprintVerified,
        syncedFromOffline: offlineId ? true : existingAttendance.syncedFromOffline,
        offlineId: offlineId || existingAttendance.offlineId,
      });

      return res.status(200).json({
        success: true,
        message: 'Attendance updated successfully',
        data: {
          id: existingAttendance.id,
          studentId,
          courseId,
          date,
          status,
        },
      });
    }

    // Create new attendance record
    const newAttendance = await Attendance.create({
      studentId,
      courseId,
      date,
      status,
      timeIn,
      remarks,
      fingerprintVerified: fingerprintVerified || false,
      verified: true,
      syncedFromOffline: offlineId ? true : false,
      offlineId,
      teacherId: req.teacher.id,
      instituteId: req.teacher.instituteId,
    });

    return res.status(201).json({
      success: true,
      message: 'Attendance recorded successfully',
      data: {
        id: newAttendance.id,
        studentId,
        courseId,
        date,
        status,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error recording attendance',
      error: error.message,
    });
  }
};

// Sync offline attendance
const syncOfflineAttendance = async (req, res) => {
  try {
    const { attendanceRecords } = req.body;

    if (!attendanceRecords || !Array.isArray(attendanceRecords) || attendanceRecords.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No attendance records provided',
      });
    }

    // Use transaction for syncing
    const results = await sequelize.transaction(async (t) => {
      const syncResults = {
        total: attendanceRecords.length,
        created: 0,
        updated: 0,
        failed: 0,
        failedRecords: [],
      };

      // Process each attendance record
      for (const record of attendanceRecords) {
        try {
          const {
            offlineId,
            studentId,
            courseId,
            date,
            status,
            timeIn,
            remarks,
            fingerprintVerified,
          } = record;

          if (!offlineId || !studentId || !courseId || !date || !status) {
            syncResults.failed++;
            syncResults.failedRecords.push({
              offlineId: offlineId || 'unknown',
              error: 'Missing required fields',
            });
            continue;
          }

          // Validate that the student and course exist and are associated with this teacher
          const isValid = await Student.findOne({
            where: {
              id: studentId,
              active: true,
            },
            include: [
              {
                model: Course,
                as: 'courses',
                where: { id: courseId, teacherId: req.teacher.id },
                required: true,
              },
            ],
            transaction: t,
          });

          if (!isValid) {
            syncResults.failed++;
            syncResults.failedRecords.push({
              offlineId,
              error: 'Invalid student or course',
            });
            continue;
          }

          // Check if this offline record was already synced
          const alreadySynced = await Attendance.findOne({
            where: { offlineId },
            transaction: t,
          });

          if (alreadySynced) {
            // Update the existing record
            await alreadySynced.update(
              {
                status,
                timeIn: timeIn || alreadySynced.timeIn,
                remarks: remarks || alreadySynced.remarks,
                fingerprintVerified: fingerprintVerified || alreadySynced.fingerprintVerified,
              },
              { transaction: t }
            );
            syncResults.updated++;
            continue;
          }

          // Check if attendance already exists for this student, course, and date
          const existingAttendance = await Attendance.findOne({
            where: {
              studentId,
              courseId,
              date,
              teacherId: req.teacher.id,
            },
            transaction: t,
          });

          if (existingAttendance) {
            // Update existing attendance
            await existingAttendance.update(
              {
                status,
                timeIn: timeIn || existingAttendance.timeIn,
                remarks: remarks || existingAttendance.remarks,
                fingerprintVerified: fingerprintVerified || existingAttendance.fingerprintVerified,
                syncedFromOffline: true,
                offlineId,
              },
              { transaction: t }
            );
            syncResults.updated++;
          } else {
            // Create new attendance record
            await Attendance.create(
              {
                studentId,
                courseId,
                date,
                status,
                timeIn,
                remarks,
                fingerprintVerified: fingerprintVerified || false,
                verified: true,
                syncedFromOffline: true,
                offlineId,
                teacherId: req.teacher.id,
                instituteId: req.teacher.instituteId,
              },
              { transaction: t }
            );
            syncResults.created++;
          }
        } catch (error) {
          syncResults.failed++;
          syncResults.failedRecords.push({
            offlineId: record.offlineId || 'unknown',
            error: error.message,
          });
        }
      }

      // Update teacher's last sync timestamp
      await req.teacher.update(
        { lastSync: new Date() },
        { transaction: t }
      );

      return syncResults;
    });

    return res.status(200).json({
      success: true,
      message: 'Attendance records synced successfully',
      data: results,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error syncing attendance records',
      error: error.message,
    });
  }
};

// Get attendance report
const getAttendanceReport = async (req, res) => {
  try {
    const { courseId, startDate, endDate } = req.query;

    if (!courseId) {
      return res.status(400).json({
        success: false,
        message: 'Course ID is required',
      });
    }

    // Validate course belongs to teacher
    const course = await Course.findOne({
      where: {
        id: courseId,
        teacherId: req.teacher.id,
      },
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

    // Get students enrolled in this course
    const students = await Student.findAll({
      include: [
        {
          model: Course,
          as: 'courses',
          where: { id: courseId },
          required: true,
          attributes: [],
          through: { attributes: [] },
        },
      ],
      attributes: ['id', 'registrationNumber', 'firstName', 'lastName'],
      order: [['firstName', 'ASC'], ['lastName', 'ASC']],
    });

    const studentIds = students.map((student) => student.id);

    // Get attendance records
    const attendanceRecords = await Attendance.findAll({
      where: {
        studentId: { [Op.in]: studentIds },
        courseId,
        ...dateFilter,
      },
      attributes: ['id', 'studentId', 'date', 'status', 'timeIn', 'fingerprintVerified'],
      order: [['date', 'DESC']],
    });

    // Process data into report format
    const attendanceByDate = {};
    attendanceRecords.forEach((record) => {
      const dateStr = record.date.toISOString().split('T')[0];
      if (!attendanceByDate[dateStr]) {
        attendanceByDate[dateStr] = {};
      }
      attendanceByDate[dateStr][record.studentId] = {
        status: record.status,
        timeIn: record.timeIn,
        fingerprintVerified: record.fingerprintVerified,
      };
    });

    // Convert to array of dates
    const dates = Object.keys(attendanceByDate).sort().reverse();

    // Calculate statistics
    const studentStats = {};
    studentIds.forEach((studentId) => {
      studentStats[studentId] = {
        present: 0,
        late: 0,
        absent: 0,
        total: dates.length,
      };

      dates.forEach((date) => {
        const record = attendanceByDate[date][studentId];
        if (record) {
          if (record.status === 'Present') studentStats[studentId].present++;
          else if (record.status === 'Late') studentStats[studentId].late++;
          else if (record.status === 'Absent') studentStats[studentId].absent++;
        } else {
          // If no record, count as absent
          studentStats[studentId].absent++;
          if (!attendanceByDate[date]) attendanceByDate[date] = {};
          attendanceByDate[date][studentId] = { status: 'Absent', timeIn: null, fingerprintVerified: false };
        }
      });
    });

    return res.status(200).json({
      success: true,
      message: 'Attendance report generated successfully',
      data: {
        course: {
          id: course.id,
          name: course.name,
          code: course.code,
          department: course.department,
          section: course.section,
        },
        dates,
        students,
        attendance: attendanceByDate,
        statistics: studentStats,
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

// Get teacher profile
const getProfile = async (req, res) => {
  try {
    const teacher = req.teacher;

    // Get statistics
    const studentCount = await Student.count({
      where: { addedBy: teacher.id },
    });

    const courseCount = await Course.count({
      where: { teacherId: teacher.id },
    });

    // Get teacher's courses
    const courses = await Course.findAll({
      where: { teacherId: teacher.id },
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

    return res.status(200).json({
      success: true,
      message: 'Profile retrieved successfully',
      data: {
        teacher: {
          id: teacher.id,
          employeeId: teacher.employeeId,
          firstName: teacher.firstName,
          lastName: teacher.lastName,
          email: teacher.email,
          phone: teacher.phone,
          qualification: teacher.qualification,
          joiningDate: teacher.joiningDate,
          lastSync: teacher.lastSync,
          createdAt: teacher.createdAt,
          institute: {
            id: teacher.institute.id,
            name: teacher.institute.name,
            code: teacher.institute.code,
          },
        },
        stats: {
          studentCount,
          courseCount,
        },
        courses,
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

// Update teacher profile
const updateProfile = async (req, res) => {
  try {
    const {
      firstName,
      lastName,
      phone,
      qualification,
      password,
      fingerprint,
    } = req.body;

    // Update fields
    const updateData = {};
    if (firstName) updateData.firstName = firstName;
    if (lastName) updateData.lastName = lastName;
    if (phone) updateData.phone = phone;
    if (qualification) updateData.qualification = qualification;
    if (password) updateData.password = password;
    
    // Process fingerprint data if provided
    if (fingerprint) {
      updateData.fingerprint = JSON.stringify(encryptFingerprint(fingerprint));
    }

    // Update teacher
    await req.teacher.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: req.teacher.id,
        employeeId: req.teacher.employeeId,
        firstName: req.teacher.firstName,
        lastName: req.teacher.lastName,
        email: req.teacher.email,
        phone: req.teacher.phone,
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
    // Get teacher's courses
    const courses = await Course.findAll({
      where: { teacherId: req.teacher.id },
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

    // Get student count per course
    const studentCounts = await Promise.all(
      courses.map(async (course) => {
        const count = await StudentCourse.count({
          where: { courseId: course.id },
        });
        return {
          courseId: course.id,
          courseName: course.name,
          courseCode: course.code,
          studentCount: count,
          department: course.department,
          section: course.section,
        };
      })
    );

    // Get today's attendance statistics
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todayAttendance = await Attendance.findAll({
      where: {
        teacherId: req.teacher.id,
        date: today,
      },
      attributes: [
        'courseId',
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
      ],
      group: ['courseId', 'status'],
      raw: true,
    });

    // Format attendance stats by course
    const attendanceStats = {};
    todayAttendance.forEach((stat) => {
      if (!attendanceStats[stat.courseId]) {
        attendanceStats[stat.courseId] = {
          Present: 0,
          Late: 0,
          Absent: 0,
        };
      }
      attendanceStats[stat.courseId][stat.status] = parseInt(stat.count, 10);
    });

    // Add attendance stats to course data
    const coursesWithStats = studentCounts.map((course) => ({
      ...course,
      todayAttendance: attendanceStats[course.courseId] || {
        Present: 0,
        Late: 0,
        Absent: 0,
      },
    }));

    // Get recent students
    const recentStudents = await Student.findAll({
      where: { addedBy: req.teacher.id },
      order: [['createdAt', 'DESC']],
      limit: 5,
      attributes: ['id', 'firstName', 'lastName', 'registrationNumber', 'createdAt'],
    });

    return res.status(200).json({
      success: true,
      message: 'Dashboard statistics retrieved successfully',
      data: {
        courses: coursesWithStats,
        recentStudents,
        lastSync: req.teacher.lastSync,
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
  createStudent,
  getAllStudents,
  getStudentById,
  updateStudent,
  takeAttendance,
  syncOfflineAttendance,
  getAttendanceReport,
  getProfile,
  updateProfile,
  getDashboardStats,
};