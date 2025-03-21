module.exports = {
    secret: process.env.JWT_SECRET || 'educational-system-secret-key',
    // JWT expiration times for different user types
    expiresIn: {
      superAdmin: '24h',
      institute: '24h',
      teacher: '24h',
    },
    // License key validation
    licenseKey: process.env.LICENSE_KEY || 'DEMO-LICENSE-KEY-2025',
    // Fingerprint data encryption key
    fingerprintEncryptionKey: process.env.FINGERPRINT_KEY || 'fingerprint-encryption-key',
  };