const { DataTypes } = require('sequelize');
const sequelize = require('../config/db.config');
const Institute = require('./institute.model');

const Department = sequelize.define(
  'department',
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
  },
  {
    timestamps: true,
    indexes: [
      {
        unique: true,
        fields: ['code', 'instituteId'],
        name: 'unique_dept_code_per_institute',
      },
    ],
  }
);

// Define association with Institute
Department.belongsTo(Institute, { foreignKey: 'instituteId', as: 'institute' });
Institute.hasMany(Department, { foreignKey: 'instituteId', as: 'departments' });

module.exports = Department;