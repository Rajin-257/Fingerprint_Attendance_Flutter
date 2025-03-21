const { DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');
const sequelize = require('../config/db.config');
const Institute = require('./institute.model');

const Teacher = sequelize.define(
  'teacher',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    employeeId: {
      type: DataTypes.STRING(50),
      allowNull: false,
      unique: true,
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
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true,
      },
    },
    password: {
      type: DataTypes.STRING(100),
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    phone: {
      type: DataTypes.STRING(20),
    },
    qualification: {
      type: DataTypes.STRING(100),
    },
    joiningDate: {
      type: DataTypes.DATEONLY,
    },
    fingerprint: {
      type: DataTypes.TEXT,
      comment: 'Encrypted fingerprint data of the teacher',
    },
    deviceId: {
      type: DataTypes.STRING(100),
      comment: 'Unique identifier for the teacher\'s device',
    },
    active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    lastLogin: {
      type: DataTypes.DATE,
    },
    lastSync: {
      type: DataTypes.DATE,
      comment: 'Last time teacher data was synced with server',
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
    hooks: {
      beforeCreate: async (teacher) => {
        teacher.password = await bcrypt.hash(teacher.password, 10);
      },
      beforeUpdate: async (teacher) => {
        if (teacher.changed('password')) {
          teacher.password = await bcrypt.hash(teacher.password, 10);
        }
      },
    },
  }
);

// Define association with Institute
Teacher.belongsTo(Institute, { foreignKey: 'instituteId', as: 'institute' });
Institute.hasMany(Teacher, { foreignKey: 'instituteId', as: 'teachers' });

// Instance method to compare password
Teacher.prototype.comparePassword = async function (password) {
  return await bcrypt.compare(password, this.password);
};

module.exports = Teacher;