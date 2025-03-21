const sequelize = require('../config/db.config');
const { QueryTypes } = require('sequelize');

/**
 * Database utility functions
 */
const dbUtil = {
  /**
   * Execute a raw SQL query
   * @param {string} sql - SQL query
   * @param {Object} replacements - Values to replace placeholders in the query
   * @param {string} type - Query type (SELECT, INSERT, UPDATE, DELETE)
   * @returns {Promise<Array|Object>} - Query results
   */
  async executeQuery(sql, replacements = {}, type = QueryTypes.SELECT) {
    try {
      return await sequelize.query(sql, {
        replacements,
        type,
        raw: true,
      });
    } catch (error) {
      console.error('Database query error:', error);
      throw error;
    }
  },

  /**
   * Get database transaction
   * @returns {Promise<Transaction>} - Sequelize transaction
   */
  async getTransaction() {
    return await sequelize.transaction();
  },

  /**
   * Check database connection
   * @returns {Promise<boolean>} - Connection status
   */
  async checkConnection() {
    try {
      await sequelize.authenticate();
      return true;
    } catch (error) {
      console.error('Database connection error:', error);
      return false;
    }
  },

  /**
   * Initialize database with required tables
   * @returns {Promise<void>}
   */
  async initializeDatabase() {
    try {
      // This will create tables based on models
      await sequelize.sync();
      console.log('Database synchronized successfully');
    } catch (error) {
      console.error('Error initializing database:', error);
      throw error;
    }
  },

  /**
   * Reset database (development only)
   * @returns {Promise<void>}
   */
  async resetDatabase() {
    if (process.env.NODE_ENV !== 'development') {
      throw new Error('Reset database is only allowed in development environment');
    }

    try {
      await sequelize.sync({ force: true });
      console.log('Database reset successfully');
    } catch (error) {
      console.error('Error resetting database:', error);
      throw error;
    }
  },

  /**
   * Get database statistics
   * @returns {Promise<Object>} - Database statistics
   */
  async getDatabaseStats() {
    try {
      const models = sequelize.models;
      const stats = {};

      for (const modelName in models) {
        const model = models[modelName];
        const count = await model.count();
        stats[modelName] = count;
      }

      return stats;
    } catch (error) {
      console.error('Error getting database statistics:', error);
      throw error;
    }
  },
};

module.exports = dbUtil;