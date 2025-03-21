const { DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');
const sequelize = require('../config/db.config');
const SuperAdmin = require('./superAdmin.model');

const Institute = sequelize.define(
  'institute',
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
      unique: true,
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
    address: {
      type: DataTypes.STRING(200),
    },
    contactPerson: {
      type: DataTypes.STRING(100),
    },
    contactNumber: {
      type: DataTypes.STRING(20),
    },
    licenseExpiry: {
      type: DataTypes.DATE,
    },
    active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    lastLogin: {
      type: DataTypes.DATE,
    },
    createdBy: {
      type: DataTypes.INTEGER,
      references: {
        model: SuperAdmin,
        key: 'id',
      },
    },
  },
  {
    timestamps: true,
    hooks: {
      beforeCreate: async (institute) => {
        institute.password = await bcrypt.hash(institute.password, 10);
      },
      beforeUpdate: async (institute) => {
        if (institute.changed('password')) {
          institute.password = await bcrypt.hash(institute.password, 10);
        }
      },
    },
  }
);

// Define association with SuperAdmin
Institute.belongsTo(SuperAdmin, { foreignKey: 'createdBy', as: 'creator' });
SuperAdmin.hasMany(Institute, { foreignKey: 'createdBy', as: 'institutes' });

// Instance method to compare password
Institute.prototype.comparePassword = async function (password) {
  return await bcrypt.compare(password, this.password);
};

module.exports = Institute;