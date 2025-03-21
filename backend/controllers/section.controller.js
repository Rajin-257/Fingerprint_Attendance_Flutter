const Section = require('../models/section.model');
const Course = require('../models/course.model');
const Department = require('../models/department.model');
const { Student } = require('../models/student.model');
const { Op } = require('sequelize');

// Create section
const createSection = async (req, res) => {
  try {
    const { name, code, capacity, description, departmentId } = req.body;

    // Check if department exists and belongs to institute
    const department = await Department.findOne({
      where: { id: departmentId, instituteId: req.institute.id },
    });

    if (!department) {
      return res.status(400).json({
        success: false,
        message: 'Invalid department',
      });
    }

    // Check if section code already exists in this department
    const existingSection = await Section.findOne({
      where: { code, departmentId },
    });

    if (existingSection) {
      return res.status(409).json({
        success: false,
        message: 'Section with this code already exists in the department',
      });
    }

    // Create new section
    const newSection = await Section.create({
      name,
      code,
      capacity: capacity || 50,
      description,
      active: true,
      departmentId,
      instituteId: req.institute.id,
    });

    return res.status(201).json({
      success: true,
      message: 'Section created successfully',
      data: {
        id: newSection.id,
        name: newSection.name,
        code: newSection.code,
        capacity: newSection.capacity,
        departmentId: newSection.departmentId,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating section',
      error: error.message,
    });
  }
};

// Get all sections
const getAllSections = async (req, res) => {
  try {
    const departmentId = req.query.departmentId || null;

    // Filter options
    const whereClause = { instituteId: req.institute.id };
    if (departmentId) {
      whereClause.departmentId = departmentId;
    }

    // Get sections
    const sections = await Section.findAll({
      where: whereClause,
      attributes: ['id', 'name', 'code', 'capacity', 'description', 'active', 'createdAt'],
      include: [
        {
          model: Department,
          as: 'department',
          attributes: ['id', 'name', 'code'],
        },
      ],
      order: [['name', 'ASC']],
    });

    return res.status(200).json({
      success: true,
      message: 'Sections retrieved successfully',
      data: sections,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error retrieving sections',
      error: error.message,
    });
  }
};

// Get section by ID
const getSectionById = async (req, res) => {
  try {
    const { id } = req.params;

    const section = await Section.findOne({
      where: { id, instituteId: req.institute.id },
      attributes: [
        'id',
        'name',
        'code',
        'capacity',
        'description',
        'active',
        'departmentId',
        'createdAt',
      ],
      include: [
        {
          model: Department,
          as: 'department',
          attributes: ['id', 'name', 'code'],
        },
      ],
    });

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Section not found',
      });
    }

    // Get section statistics
    const studentCount = await Student.count({
      where: { sectionId: id },
    });

    const courseCount = await Course.count({
      where: { sectionId: id },
    });

    // Get courses in this section
    const courses = await Course.findAll({
      where: { sectionId: id },
      attributes: ['id', 'name', 'code', 'active'],
      order: [['name', 'ASC']],
    });

    return res.status(200).json({
      success: true,
      message: 'Section retrieved successfully',
      data: {
        section,
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
      message: 'Error retrieving section',
      error: error.message,
    });
  }
};

// Update section
const updateSection = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, capacity, description, active } = req.body;

    // Find section
    const section = await Section.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Section not found',
      });
    }

    // Update fields
    const updateData = {};
    if (name) updateData.name = name;
    if (capacity) updateData.capacity = capacity;
    if (description !== undefined) updateData.description = description;
    if (active !== undefined) updateData.active = active;

    // Update section
    await section.update(updateData);

    return res.status(200).json({
      success: true,
      message: 'Section updated successfully',
      data: {
        id: section.id,
        name: section.name,
        code: section.code,
        capacity: section.capacity,
        description: section.description,
        active: section.active,
        departmentId: section.departmentId,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating section',
      error: error.message,
    });
  }
};

// Delete section
const deleteSection = async (req, res) => {
  try {
    const { id } = req.params;

    // Find section
    const section = await Section.findOne({
      where: { id, instituteId: req.institute.id },
    });

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Section not found',
      });
    }

    // Check if section has associated courses or students
    const coursesCount = await Course.count({
      where: { sectionId: id },
    });

    const studentsCount = await Student.count({
      where: { sectionId: id },
    });

    if (coursesCount > 0 || studentsCount > 0) {
      return res.status(400).json({
        success: false,
        message:
          'Cannot delete section with associated courses or students. Deactivate it instead.',
      });
    }

    // Delete section
    await section.destroy();

    return res.status(200).json({
      success: true,
      message: 'Section deleted successfully',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error deleting section',
      error: error.message,
    });
  }
};

module.exports = {
  createSection,
  getAllSections,
  getSectionById,
  updateSection,
  deleteSection,
};