import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final encrypt.Key _encryptionKey = encrypt.Key.fromUtf8(
    dotenv.env['FINGERPRINT_KEY'] ?? 'fingerprint-encryption-key-32-chars!!',
  );
  final encrypt.IV _iv = encrypt.IV.fromLength(16);

  // Check if device supports biometrics
  Future<bool> isBiometricAvailable() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return canCheckBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Get available biometrics types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  // Authenticate with device biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to proceed',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        // Biometrics is not available
      } else if (e.code == auth_error.notEnrolled) {
        // No biometrics enrolled
      } else if (e.code == auth_error.lockedOut) {
        // Too many attempts
      } else if (e.code == auth_error.permanentlyLockedOut) {
        // Permanently locked out
      }
      return false;
    }
  }

  // Encrypt fingerprint data for storage and transmission
  String encryptFingerprintData(String fingerprintData) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encrypt(fingerprintData, iv: _iv);
    
    // Return as JSON with IV for decryption later
    return jsonEncode({
      'iv': _iv.base64,
      'data': encrypted.base64,
    });
  }

  // Decrypt fingerprint data
  String? decryptFingerprintData(String encryptedData) {
    try {
      final encryptedJson = jsonDecode(encryptedData);
      final iv = encrypt.IV.fromBase64(encryptedJson['iv']);
      final encrypted = encrypt.Encrypted.fromBase64(encryptedJson['data']);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return null;
    }
  }

  // Register a student's fingerprint (simulated in this app)
  // In a real app, this would interface with actual fingerprint hardware
  Future<Map<String, dynamic>> registerFingerprint({
    required String studentId,
    String position = 'right_thumb',
  }) async {
    try {
      // First authenticate the teacher/admin using device biometrics
      bool authenticated = await authenticate(
        localizedReason: 'Authenticate to register student fingerprint',
      );
      
      if (!authenticated) {
        return {
          'success': false,
          'message': 'Authentication failed',
        };
      }
      
      // In a real app, this is where we would capture the actual fingerprint template
      // For this demo, we'll simulate by generating a unique template string
      
      // Create a simulated fingerprint template (unique for each student and position)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final templateBase = 'FP_TEMPLATE_$studentId\_$position\_$timestamp';
      final simulatedTemplate = base64Encode(utf8.encode(templateBase));
      
      // Encrypt the template for storage
      final encryptedTemplate = encryptFingerprintData(simulatedTemplate);
      
      return {
        'success': true,
        'template': encryptedTemplate,
        'quality': 85, // Simulated quality score (0-100)
        'position': position,
        'message': 'Fingerprint registered successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to register fingerprint: ${e.toString()}',
      };
    }
  }

  // Verify a fingerprint against stored template (simulated)
  Future<Map<String, dynamic>> verifyFingerprint({
    required String studentId,
    required String storedTemplate,
  }) async {
    try {
      // First authenticate using device biometrics
      bool authenticated = await authenticate(
        localizedReason: 'Authenticate to verify student fingerprint',
      );
      
      if (!authenticated) {
        return {
          'success': false,
          'verified': false,
          'message': 'Authentication failed',
        };
      }
      
      // In a real app, we would:
      // 1. Capture the fingerprint
      // 2. Extract minutiae
      // 3. Compare with the stored template
      
      // For this demo, we'll simulate a successful verification
      // with a small random factor for realism
      
      // Verify the decryption works
      final decryptedTemplate = decryptFingerprintData(storedTemplate);
      if (decryptedTemplate == null) {
        return {
          'success': false,
          'verified': false,
          'message': 'Invalid template data',
        };
      }
      
      // Add a small random factor to simulate real-world verification
      // with occasional failures
      final randomFactor = DateTime.now().millisecondsSinceEpoch % 10;
      final verified = randomFactor < 9; // 90% success rate
      
      return {
        'success': true,
        'verified': verified,
        'score': verified ? 80 + randomFactor : 60 - randomFactor,
        'message': verified 
            ? 'Fingerprint verified successfully' 
            : 'Fingerprint verification failed',
      };
    } catch (e) {
      return {
        'success': false,
        'verified': false,
        'message': 'Error during verification: ${e.toString()}',
      };
    }
  }
}