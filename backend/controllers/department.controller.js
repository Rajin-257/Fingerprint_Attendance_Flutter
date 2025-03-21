const Department = require('../models/department.model');
const Section = require('../models/section.model');
const Course = require('../models/course.model');
const { Student } = require('../models/student.model');
const Teacher = require('../models/teacher.model');
const { Op } = require('sequelize');

// Update department
const updateDepartment = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, active } = req.body;

    // Find department
    const department = await Department.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!department) {
      return res.status(404).json({
        success: false,
        message: 'Department not found',
      });
    }

    // Update fields
    const updateData = {};
    if (name) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (active !== undefined) updateData.active = active;

    // Update department
    await department.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Department updated successfully',
      data: {
        id: department.id,
        name: department.name,
        code: department.code,
        description: department.description,
        active: department.active,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating department',
      error: error.message,
    });
  }
};

// Get department by ID
const getDepartmentById = async (req, res) => {
  try {
    const { id } = req.params;

    const department = await Department.findOne({
      where: { id, instituteId: req.institute.id },
      attributes: ['id', 'name', 'code', 'description', 'active', 'createdAt'],
    });

    if (!department) {
      return res.status(404).json({
        success: false,
        message: 'Department not found',
      });
    }

    // Get department statistics
    const sectionCount = await Section.count({
      where: { departmentId: id },
    });

    const teacherCount = await Teacher.count({
      include: [
        {
          model: Course,
          as: 'courses',
          required: true,
          where: { departmentId: id },
          attributes: [],
        },
      ],
    });

    const studentCount = await Student.count({
      where: { departmentId: id },
    });

    const courses = await Course.count({
      where: { departmentId: id },
    });

    // Get sections in this department
    const sections = await Section.findAll({
      where: { departmentId: id },
      attributes: ['id', 'name', 'code', 'capacity', 'active'],
      order: [['name', 'ASC']],
    });

    return res.status(200).json({
      success: true,
      message: 'Department retrieved successfully',
      data: {
        department,
        stats: {
          sectionCount,
          teacherCount,
          studentCount,
          courseCount: courses,
        },
        sections,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving department',
      error: error.message,
    });
  }
};

// Delete department
const deleteDepartment = async (req, res) => {
  try {
    const { id } = req.params;

    // Find department
    const department = await Department.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!department) {
      return res.status(404).json({
        success: false,
        message: 'Department not found',
      });
    }

    // Check if department has associated sections, courses, or students
    const sectionsCount = await Section.count({
      where: { departmentId: id },
    });

    const coursesCount = await Course.count({
      where: { departmentId: id },
    });

    const studentsCount = await Student.count({
      where: { departmentId: id },
    });

    if (sectionsCount > 0 || coursesCount > 0 || studentsCount > 0) {
      return res.status(400).json({
        success: false,
        message:
          'Cannot delete department with associated sections, courses, or students. Deactivate it instead.',
      });
    }

    // Delete department
    await department.destroy();

    return res.status(200).json({
      success: true,
      message: 'Department deleted successfully',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error deleting department',
      error: error.message,
    });
  }
};

module.exports = {
  updateDepartment,
  getDepartmentById,
  deleteDepartment,
};