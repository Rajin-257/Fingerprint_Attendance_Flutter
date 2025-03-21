const { DataTypes } = require('sequelize');
const sequelize = require('../config/db.config');
const Institute = require('./institute.model');
const Department = require('./department.model');

const Section = sequelize.define(
  'section',
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
    capacity: {
      type: DataTypes.INTEGER,
      defaultValue: 50,
    },
    description: {
      type: DataTypes.TEXT,
    },
    active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    departmentId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: Department,
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
        unique: true,
        fields: ['code', 'departmentId'],
        name: 'unique_section_code_per_dept',
      },
    ],
  }
);

// Define associations
Section.belongsTo(Department, { foreignKey: 'departmentId', as: 'department' });
Department.hasMany(Section, { foreignKey: 'departmentId', as: 'sections' });

Section.belongsTo(Institute, { foreignKey: 'instituteId', as: 'institute' });
Institute.hasMany(Section, { foreignKey: 'instituteId', as: 'sections' });

module.exports = Section;