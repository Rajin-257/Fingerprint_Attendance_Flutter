const { DataTypes } = require('sequelize');
const sequelize = require('../config/db.config');
const { Student } = require('./student.model');
const Course = require('./course.model');
const Teacher = require('./teacher.model');
const Institute = require('./institute.model');

const Attendance = sequelize.define(
  'attendance',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM('Present', 'Late', 'Absent'),
      allowNull: false,
    },
    timeIn: {
      type: DataTypes.TIME,
    },
    remarks: {
      type: DataTypes.TEXT,
    },
    fingerprintVerified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    verified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    syncedFromOffline: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    offlineId: {
      type: DataTypes.STRING(100),
      comment: 'ID used in offline mode before syncing',
    },
    studentId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Student,
        key: 'id',
      },
    },
    courseId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Course,
        key: 'id',
      },
    },
    teacherId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Teacher,
        key: 'id',
      },
    },
    instituteId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Institute,
        key: 'id',
      },
    },
  },
  {
    timestamps: true,
    indexes: [
      {
        fields: ['date', 'studentId', 'courseId'],
        name: 'attendance_date_student_course_idx',
      },
      {
        fields: ['teacherId', 'date'],
        name: 'attendance_teacher_date_idx',
      },
    ],
  }
);

// Define associations
Attendance.belongsTo(Student, { foreignKey: 'studentId', as: 'student' });
Student.hasMany(Attendance, { foreignKey: 'studentId', as: 'attendanceRecords' });

Attendance.belongsTo(Course, { foreignKey: 'courseId', as: 'course' });
Course.hasMany(Attendance, { foreignKey: 'courseId', as: 'attendanceRecords' });

Attendance.belongsTo(Teacher, { foreignKey: 'teacherId', as: 'teacher' });
Teacher.hasMany(Attendance, { foreignKey: 'teacherId', as: 'recordedAttendances' });

Attendance.belongsTo(Institute, { foreignKey: 'instituteId', as: 'institute' });
Institute.hasMany(Attendance, { foreignKey: 'instituteId', as: 'attendanceRecords' });

module.exports = Attendance;