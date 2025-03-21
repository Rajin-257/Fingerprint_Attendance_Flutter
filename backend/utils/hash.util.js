const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const authConfig = require('../config/auth.config');

/**
 * Hash utility functions
 */
const hashUtil = {
  /**
   * Hash a password using bcrypt
   * @param {string} password - Plain text password
   * @returns {Promise<string>} - Hashed password
   */
  async hashPassword(password) {
    return await bcrypt.hash(password, 10);
  },

  /**
   * Compare a plain text password with a hashed password
   * @param {string} password - Plain text password
   * @param {string} hashedPassword - Hashed password
   * @returns {Promise<boolean>} - Comparison result
   */
  async comparePassword(password, hashedPassword) {
    return await bcrypt.compare(password, hashedPassword);
  },

  /**
   * Generate a JWT token
   * @param {Object} payload - Token payload
   * @param {string} type - User type (superAdmin, institute, teacher)
   * @param {string} expiresIn - Token expiration time
   * @returns {string} - JWT token
   */
  generateToken(payload, type) {
    return jwt.sign(
      { ...payload, type },
      authConfig.secret,
      { expiresIn: authConfig.expiresIn[type] || '24h' }
    );
  },

  /**
   * Verify a JWT token
   * @param {string} token - JWT token
   * @returns {Object|null} - Decoded token payload or null if invalid
   */
  verifyToken(token) {
    try {
      return jwt.verify(token, authConfig.secret);
    } catch (error) {
      console.error('Token verification error:', error.message);
      return null;
    }
  },

  /**
   * Generate a random string
   * @param {number} length - Length of the string
   * @returns {string} - Random string
   */
  generateRandomString(length = 32) {
    return crypto.randomBytes(length).toString('hex').slice(0, length);
  },

  /**
   * Generate a UUID
   * @returns {string} - UUID
   */
  generateUUID() {
    return crypto.randomUUID();
  },

  /**
   * Encrypt data
   * @param {string} data - Data to encrypt
   * @param {string} key - Encryption key
   * @returns {Object} - Encrypted data with IV
   */
  encryptData(data, key = authConfig.fingerprintEncryptionKey) {
    const algorithm = 'aes-256-cbc';
    const keyBuffer = Buffer.from(key, 'utf8');
    const iv = crypto.randomBytes(16);
    
    const cipher = crypto.createCipheriv(algorithm, keyBuffer, iv);
    let encrypted = cipher.update(data, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    return {
      iv: iv.toString('hex'),
      data: encrypted,
    };
  },

  /**
   * Decrypt data
   * @param {Object} encryptedData - Encrypted data with IV
   * @param {string} key - Encryption key
   * @returns {string|null} - Decrypted data or null if error
   */
  decryptData(encryptedData, key = authConfig.fingerprintEncryptionKey) {
    try {
      const algorithm = 'aes-256-cbc';
      const keyBuffer = Buffer.from(key, 'utf8');
      const iv = Buffer.from(encryptedData.iv, 'hex');
      
      const decipher = crypto.createDecipheriv(algorithm, keyBuffer, iv);
      let decrypted = decipher.update(encryptedData.data, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      console.error('Decryption error:', error.message);
      return null;
    }
  },
};

module.exports = hashUtil;