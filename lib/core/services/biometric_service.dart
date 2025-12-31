// ============================================================================
// BIOMETRIC AUTHENTICATION SERVICE (UPDATED 2025 API)
// lib/core/repositories/biometric_service.dart
// ============================================================================

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';
import '../utils/logger.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --------------------------------------------------------------------------
  // DEVICE SUPPORT
  // --------------------------------------------------------------------------
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      AppLogger.error('Error checking device support', error: e);
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // BIOMETRIC AVAILABLE?
  // --------------------------------------------------------------------------
  Future<bool> isBiometricAvailable() async {
    try {
      if (!await isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;

      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking biometric availability', error: e);
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // GET AVAILABLE TYPES (fingerprint / face / etc)
  // --------------------------------------------------------------------------
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.error('Error getting biometrics list', error: e);
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // AUTHENTICATE
  // --------------------------------------------------------------------------
  Future<bool> authenticate({
    String reason = 'Authenticate to continue',
    bool biometricOnly = true,
  }) async {
    try {
      AppLogger.info("Starting biometric authentication…");

      if (!await isBiometricAvailable()) {
        AppLogger.warning("Biometric not available on this device");
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: "Please authenticate to enable biometric login",
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      if (authenticated) {
        AppLogger.info("Biometric auth success");
      } else {
        AppLogger.warning("Biometric auth failed");
      }

      return authenticated;
    } on PlatformException catch (e) {
      AppLogger.error("Platform biometric error", error: e);

      switch (e.code) {
        case 'LockedOut':
          throw BiometricException('Too many attempts. Try later.');
        case 'PermanentlyLockedOut':
          throw BiometricException('Biometric permanently disabled.');
        case 'NotAvailable':
          throw BiometricException('Biometrics unavailable.');
        case 'NotEnrolled':
          throw BiometricException('No biometric enrolled.');
      }

      throw BiometricException('Biometric error: ${e.message}');
    } catch (e) {
      AppLogger.error("Unknown biometric error", error: e);
      throw BiometricException('Authentication error');
    }
  }

  // --------------------------------------------------------------------------
  // LOGIN STATE
  // --------------------------------------------------------------------------
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _storage.read(key: StorageKeys.biometricEnabled);
      return enabled == 'true';
    } catch (e) {
      AppLogger.error("Error reading biometric login setting", error: e);
      return false;
    }
  }

  // lib/core/repositories/biometric_service.dart

// Add this inside the BiometricService class:
  Future<bool> hasSavedCredentials() async {
    try {
      final credentials = await _storage.read(key: StorageKeys.biometricCredentials);
      // Returns true only if the string exists and contains our separator
      return credentials != null && credentials.contains("::");
    } catch (e) {
      AppLogger.error("Error checking saved credentials", error: e);
      return false;
    }
  }
  Future<void> enableBiometricLogin() async {
    try {
      await _storage.write(key: StorageKeys.biometricEnabled, value: 'true');
      AppLogger.info("Biometric login turned ON");
    } catch (e) {
      AppLogger.error("Enable biometric login failed", error: e);
      throw BiometricException("Could not enable");
    }
  }

  Future<void> disableBiometricLogin() async {
    try {
      await _storage.write(key: StorageKeys.biometricEnabled, value: 'false');
      await _storage.delete(key: StorageKeys.biometricCredentials);
      AppLogger.info("Biometric login turned OFF");
    } catch (e) {
      AppLogger.error("Disable biometric login failed", error: e);
      throw BiometricException("Could not disable");
    }
  }

  // --------------------------------------------------------------------------
  // SAVE LOGIN CREDENTIALS
  // --------------------------------------------------------------------------
  Future<void> saveCredentialsForBiometric(
      String email,
      String password,
      ) async {
    try {
      await _storage.write(
        key: StorageKeys.biometricCredentials,
        value: "$email::$password",
      );

      AppLogger.info("Biometric credentials saved");
    } catch (e) {
      AppLogger.error("Saving credentials failed", error: e);
      throw BiometricException("Could not save credentials");
    }
  }

  // --------------------------------------------------------------------------
  // READ LOGIN CREDENTIALS
  // --------------------------------------------------------------------------
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final raw = await _storage.read(key: StorageKeys.biometricCredentials);

      if (raw == null) return null;
      final parts = raw.split("::");
      if (parts.length != 2) return null;

      return {
        "email": parts[0],
        "password": parts[1],
      };
    } catch (e) {
      AppLogger.error("Get credentials failed", error: e);
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // CANCEL
  // --------------------------------------------------------------------------
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      AppLogger.error("Stop auth error", error: e);
    }
  }

  // --------------------------------------------------------------------------
  // BIOMETRIC DISPLAY NAME
  // --------------------------------------------------------------------------
  String getTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return "Face ID";
    if (types.contains(BiometricType.fingerprint)) return "Fingerprint";
    if (types.contains(BiometricType.iris)) return "Iris";
    return "Biometric";
  }
}

class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);
  @override
  String toString() => message;
}
