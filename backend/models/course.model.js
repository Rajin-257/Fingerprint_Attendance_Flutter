const { DataTypes } = require('sequelize');
const sequelize = require('../config/db.config');
const Institute = require('./institute.model');
const Department = require('./department.model');
const Section = require('./section.model');
const Teacher = require('./teacher.model');

const Course = sequelize.define(
  'course',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.STRING(100),
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    code: {
      type: DataTypes.STRING(20),
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    description: {
      type: DataTypes.TEXT,
    },
    creditHours: {
      type: DataTypes.FLOAT,
      defaultValue: 3.0,
    },
    schedule: {
      type: DataTypes.JSON,
      comment: 'JSON object containing course schedule information',
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
    teacherId: {
      type: DataTypes.INTEGER,
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
        fields: ['code', 'sectionId', 'departmentId'],
        name: 'unique_course_per_section_dept',
      },
    ],
  }
);

// Define associations
Course.belongsTo(Institute, { foreignKey: 'instituteId', as: 'institute' });
Institute.hasMany(Course, { foreignKey: 'instituteId', as: 'courses' });

Course.belongsTo(Department, { foreignKey: 'departmentId', as: 'department' });
Department.hasMany(Course, { foreignKey: 'departmentId', as: 'courses' });

Course.belongsTo(Section, { foreignKey: 'sectionId', as: 'section' });
Section.hasMany(Course, { foreignKey: 'sectionId', as: 'courses' });

Course.belongsTo(Teacher, { foreignKey: 'teacherId', as: 'teacher' });
Teacher.hasMany(Course, { foreignKey: 'teacherId', as: 'courses' });

module.exports = Course;