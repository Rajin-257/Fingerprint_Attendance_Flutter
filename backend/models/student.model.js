const { DataTypes } = require('sequelize');
const sequelize = require('../config/db.config');
const Institute = require('./institute.model');
const Department = require('./department.model');
const Section = require('./section.model');
const Course = require('./course.model');
const Teacher = require('./teacher.model');

const Student = sequelize.define(
  'student',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    registrationNumber: {
      type: DataTypes.STRING(50),
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    firstName: {
      type: DataTypes.STRING(50),
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    lastName: {
      type: DataTypes.STRING(50),
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    email: {
      type: DataTypes.STRING(100),
      validate: {
        isEmail: true,
      },
    },
    dateOfBirth: {
      type: DataTypes.DATEONLY,
    },
    gender: {
      type: DataTypes.ENUM('Male', 'Female', 'Other'),
    },
    contactNumber: {
      type: DataTypes.STRING(20),
    },
    address: {
      type: DataTypes.TEXT,
    },
    fingerprint: {
      type: DataTypes.TEXT,
      comment: 'Encrypted fingerprint data of the student',
    },
    active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    instituteId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Institute,
        key: 'id',
      },
    },
    departmentId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Department,
        key: 'id',
      },
    },
    sectionId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Section,
        key: 'id',
      },
    },
    addedBy: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Teacher,
        key: 'id',
      },
    },
  },
  {
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ['registrationNumber', 'instituteId'],
        name: 'unique_reg_number_per_institute',
      },
    ],
  }
);

// Define associations
Student.belongsTo(Institute, { foreignKey: 'instituteId', as: 'institute' });
Institute.hasMany(Student, { foreignKey: 'instituteId', as: 'students' });

Student.belongsTo(Department, { foreignKey: 'departmentId', as: 'department' });
Department.hasMany(Student, { foreignKey: 'departmentId', as: 'students' });

Student.belongsTo(Section, { foreignKey: 'sectionId', as: 'section' });
Section.hasMany(Student, { foreignKey: 'sectionId', as: 'students' });

Student.belongsTo(Teacher, { foreignKey: 'addedBy', as: 'teacher' });
Teacher.hasMany(Student, { foreignKey: 'addedBy', as: 'students' });

// Many-to-Many relationship between Students and Courses
const StudentCourse = sequelize.define(
  'student_course',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    studentId: {
      type: DataTypes.INTEGER,
      references: {
        model: Student,
        key: 'id',
      },
    },
    courseId: {
      type: DataTypes.INTEGER,
      references: {
        model: Course,
        key: 'id',
      },
    },
    enrollmentDate: {
      type: DataTypes.DATEONLY,
      defaultValue: DataTypes.NOW,
    },
    status: {
      type: DataTypes.ENUM('Active', 'Dropped', 'Completed'),
      defaultValue: 'Active',
    },
  },
  {
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ['studentId', 'courseId'],
        name: 'unique_student_course',
      },
    ],
  }
);

Student.belongsToMany(Course, {
  through: StudentCourse,
  as: 'courses',
  foreignKey: 'studentId',
});

Course.belongsToMany(Student, {
  through: StudentCourse,
  as: 'students',
  foreignKey: 'courseId',
});

module.exports = { Student, StudentCourse };