// ============================================================================
// BIOMETRIC AUTHENTICATION SERVICE - WITH LOGOUT SUPPORT
// lib/core/services/biometric_service.dart
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
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ==========================================================================
  // DEVICE SUPPORT
  // ==========================================================================

  Future<bool> isDeviceSupported() async {
    try {
      final supported = await auth.isDeviceSupported();
      print('📱 [BiometricService] Device supported: $supported');
      return supported;
    } catch (e) {
      print('❌ [BiometricService] Error checking device support: $e');
      AppLogger.error('Error checking device support', error: e);
      return false;
    }
  }

  // ==========================================================================
  // BIOMETRIC AVAILABLE?
  // ==========================================================================

  Future<bool> isBiometricAvailable() async {
    try {
      print('🔍 [BiometricService] Checking biometric availability...');

      final deviceSupported = await isDeviceSupported();
      print('   - Device supported: $deviceSupported');

      if (!deviceSupported) {
        print('❌ [BiometricService] Device not supported');
        return false;
      }

      final canCheck = await auth.canCheckBiometrics;
      print('   - Can check biometrics: $canCheck');

      if (!canCheck) {
        print('❌ [BiometricService] Cannot check biometrics');
        return false;
      }

      final biometrics = await getAvailableBiometrics();
      print('   - Available biometrics: $biometrics');

      final available = biometrics.isNotEmpty;
      print('✅ [BiometricService] Biometric available: $available');

      return available;
    } catch (e) {
      print('❌ [BiometricService] Error checking availability: $e');
      AppLogger.error('Error checking biometric availability', error: e);
      return false;
    }
  }

  // ==========================================================================
  // GET AVAILABLE TYPES (fingerprint / face / etc)
  // ==========================================================================

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final types = await auth.getAvailableBiometrics();
      print('📋 [BiometricService] Available types: $types');
      return types;
    } catch (e) {
      print('❌ [BiometricService] Error getting biometrics list: $e');
      AppLogger.error('Error getting biometrics list', error: e);
      return [];
    }
  }

  // ==========================================================================
  // AUTHENTICATE - FIXED WITH CORRECT API
  // ==========================================================================

  Future<bool> authenticate({
    String reason = 'Authenticate to continue',
    bool biometricOnly = true,
  }) async {
    try {
      print('🔐 [BiometricService] Starting authentication...');
      print('   - Reason: $reason');
      print('   - Biometric only: $biometricOnly');

      AppLogger.info("Starting biometric authentication…");

      final available = await isBiometricAvailable();
      if (!available) {
        print('❌ [BiometricService] Biometric not available');
        AppLogger.warning("Biometric not available on this device");
        return false;
      }

      print('🔓 [BiometricService] Showing biometric prompt...');

      final authenticated = await auth.authenticate(
        localizedReason: "Please authenticate to enable biometric login",
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      if (authenticated) {
        print('✅ [BiometricService] Authentication successful');
        AppLogger.info("Biometric auth success");
      } else {
        print('❌ [BiometricService] Authentication failed or cancelled');
        AppLogger.warning("Biometric auth failed");
      }

      return authenticated;
    } on PlatformException catch (e) {
      print('❌ [BiometricService] Platform exception: ${e.code} - ${e.message}');
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
        default:
          throw BiometricException('Biometric error: ${e.message}');
      }
    } catch (e) {
      print('❌ [BiometricService] Unknown error: $e');
      AppLogger.error("Unknown biometric error", error: e);
      throw BiometricException('Authentication error');
    }
  }

  // ==========================================================================
  // ✅ AUTHENTICATE FOR LOGIN - HANDLES LOGOUT SCENARIO
  // ==========================================================================

  /// Authenticate user for login using saved credentials
  /// Returns credentials map if successful, null if failed or no credentials
  Future<Map<String, String>?> authenticateForLogin() async {
    try {
      print('🔐 [BiometricService] Authenticating for login...');

      // Check if biometric login is enabled
      final isEnabled = await isBiometricLoginEnabled();
      if (!isEnabled) {
        print('⚠️ [BiometricService] Biometric login not enabled');
        return null;
      }

      // ✅ Check if we have saved credentials
      final credentials = await _storage.read(key: StorageKeys.biometricCredentials);
      if (credentials == null || !credentials.contains('::')) {
        print('⚠️ [BiometricService] No saved credentials found');
        print('ℹ️ [BiometricService] User needs to login normally first');

        // The preference is still enabled, but credentials are missing
        // This happens after logout
        AppLogger.warning('Biometric enabled but no credentials. Please login normally first.');
        return null;
      }

      print('✅ [BiometricService] Credentials found, prompting for biometric...');

      // Authenticate with biometric
      final authenticated = await authenticate(
        reason: 'Authenticate to login',
        biometricOnly: true,
      );

      if (!authenticated) {
        print('❌ [BiometricService] Biometric authentication failed');
        return null;
      }

      print('✅ [BiometricService] Biometric authentication successful');

      // Return the saved credentials
      return await getSavedCredentials();
    } catch (e) {
      print('❌ [BiometricService] authenticateForLogin error: $e');
      AppLogger.error('Biometric login failed', error: e);
      return null;
    }
  }

  // ==========================================================================
  // LOGIN STATE
  // ==========================================================================

  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _storage.read(key: StorageKeys.biometricEnabled);
      final isEnabled = enabled == 'true';

      print('📦 [BiometricService] isBiometricLoginEnabled: $isEnabled');
      print('   - Raw value: $enabled');

      return isEnabled;
    } catch (e) {
      print('❌ [BiometricService] Error reading enabled status: $e');
      AppLogger.error("Error reading biometric login setting", error: e);
      return false;
    }
  }

  Future<bool> hasSavedCredentials() async {
    try {
      final credentials = await _storage.read(key: StorageKeys.biometricCredentials);
      final hasCredentials = credentials != null && credentials.contains("::");

      print('📦 [BiometricService] hasSavedCredentials: $hasCredentials');
      print('   - Raw value exists: ${credentials != null}');
      print('   - Contains separator: ${credentials?.contains("::") ?? false}');

      return hasCredentials;
    } catch (e) {
      print('❌ [BiometricService] Error checking saved credentials: $e');
      AppLogger.error("Error checking saved credentials", error: e);
      return false;
    }
  }

  /// ✅ Check if biometric login is ready to use (enabled AND has credentials)
  Future<bool> isBiometricLoginReady() async {
    try {
      final enabled = await isBiometricLoginEnabled();
      final hasCredentials = await hasSavedCredentials();

      final isReady = enabled && hasCredentials;

      print('📦 [BiometricService] isBiometricLoginReady: $isReady');
      print('   - Enabled: $enabled');
      print('   - Has credentials: $hasCredentials');

      return isReady;
    } catch (e) {
      print('❌ [BiometricService] Error checking ready status: $e');
      return false;
    }
  }

  Future<void> enableBiometricLogin() async {
    try {
      print('📦 [BiometricService] Enabling biometric login...');

      await _storage.write(key: StorageKeys.biometricEnabled, value: 'true');

      // Verify
      final verified = await _storage.read(key: StorageKeys.biometricEnabled);
      print('✅ [BiometricService] Biometric login enabled');
      print('   - Verification: ${verified == 'true'}');

      AppLogger.info("Biometric login turned ON");
    } catch (e) {
      print('❌ [BiometricService] Enable failed: $e');
      AppLogger.error("Enable biometric login failed", error: e);
      throw BiometricException("Could not enable");
    }
  }

  Future<void> disableBiometricLogin() async {
    try {
      print('📦 [BiometricService] Disabling biometric login...');

      await _storage.write(key: StorageKeys.biometricEnabled, value: 'false');
      await _storage.delete(key: StorageKeys.biometricCredentials);

      print('✅ [BiometricService] Biometric login disabled');

      AppLogger.info("Biometric login turned OFF");
    } catch (e) {
      print('❌ [BiometricService] Disable failed: $e');
      AppLogger.error("Disable biometric login failed", error: e);
      throw BiometricException("Could not disable");
    }
  }

  // ==========================================================================
  // SAVE LOGIN CREDENTIALS
  // ==========================================================================

  Future<void> saveCredentialsForBiometric(
      String email,
      String password,
      ) async {
    try {
      print('📦 [BiometricService] Saving credentials...');
      print('   - Email: $email');
      print('   - Password length: ${password.length}');

      final combined = "$email::$password";

      await _storage.write(
        key: StorageKeys.biometricCredentials,
        value: combined,
      );

      // Verify the write
      final saved = await _storage.read(key: StorageKeys.biometricCredentials);
      final verified = saved == combined;

      print('✅ [BiometricService] Credentials saved');
      print('   - Verification: $verified');
      print('   - Saved length: ${saved?.length ?? 0}');

      AppLogger.info("Biometric credentials saved");
    } catch (e) {
      print('❌ [BiometricService] Save credentials failed: $e');
      AppLogger.error("Saving credentials failed", error: e);
      throw BiometricException("Could not save credentials");
    }
  }

  // ==========================================================================
  // READ LOGIN CREDENTIALS
  // ==========================================================================

  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      print('📦 [BiometricService] Getting saved credentials...');

      final raw = await _storage.read(key: StorageKeys.biometricCredentials);

      if (raw == null) {
        print('❌ [BiometricService] No credentials found');
        return null;
      }

      print('   - Raw data exists: ${raw.length} chars');

      final parts = raw.split("::");
      if (parts.length != 2) {
        print('❌ [BiometricService] Invalid credential format');
        return null;
      }

      print('✅ [BiometricService] Credentials retrieved');
      print('   - Email: ${parts[0]}');
      print('   - Password length: ${parts[1].length}');

      return {
        "email": parts[0],
        "password": parts[1],
      };
    } catch (e) {
      print('❌ [BiometricService] Get credentials failed: $e');
      AppLogger.error("Get credentials failed", error: e);
      return null;
    }
  }

  // ==========================================================================
  // ✅ CLEAR CREDENTIALS (Called during logout)
  // ==========================================================================

  /// Clear saved biometric credentials (but keep the enabled preference)
  /// This is called during logout
  Future<void> clearCredentials() async {
    try {
      print('🧹 [BiometricService] Clearing credentials (keeping preference)...');

      await _storage.delete(key: StorageKeys.biometricCredentials);

      print('✅ [BiometricService] Credentials cleared');

      // The biometric_login_enabled preference is NOT cleared
      // So user still sees biometric as "enabled" in settings

      AppLogger.info("Biometric credentials cleared (preference kept)");
    } catch (e) {
      print('❌ [BiometricService] Clear credentials failed: $e');
      AppLogger.error("Clear credentials failed", error: e);
    }
  }

  // ==========================================================================
  // CANCEL AUTHENTICATION
  // ==========================================================================

  Future<void> stopAuthentication() async {
    try {
      print('🛑 [BiometricService] Stopping authentication...');
      await auth.stopAuthentication();
      print('✅ [BiometricService] Authentication stopped');
    } catch (e) {
      print('❌ [BiometricService] Stop auth error: $e');
      AppLogger.error("Stop auth error", error: e);
    }
  }

  // ==========================================================================
  // BIOMETRIC DISPLAY NAME
  // ==========================================================================

  String getTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      print('📱 [BiometricService] Type: Face ID');
      return "Face ID";
    }
    if (types.contains(BiometricType.fingerprint)) {
      print('📱 [BiometricService] Type: Fingerprint');
      return "Fingerprint";
    }
    if (types.contains(BiometricType.iris)) {
      print('📱 [BiometricService] Type: Iris');
      return "Iris";
    }
    if (types.contains(BiometricType.strong)) {
      print('📱 [BiometricService] Type: Strong Biometric');
      return "Biometric";
    }
    if (types.contains(BiometricType.weak)) {
      print('📱 [BiometricService] Type: Weak Biometric');
      return "Biometric";
    }
    print('📱 [BiometricService] Type: Generic Biometric');
    return "Biometric";
  }

  // ==========================================================================
  // DEBUG HELPER
  // ==========================================================================

  Future<void> debugStorageContents() async {
    try {
      print('');
      print('🔍 ========================================');
      print('🔍 BIOMETRIC STORAGE DEBUG');
      print('🔍 ========================================');

      final enabled = await _storage.read(key: StorageKeys.biometricEnabled);
      final credentials = await _storage.read(key: StorageKeys.biometricCredentials);

      print('📦 Enabled status: $enabled');
      print('📦 Has credentials: ${credentials != null}');

      if (credentials != null) {
        final parts = credentials.split('::');
        print('📦 Credential format valid: ${parts.length == 2}');
        if (parts.length == 2) {
          print('📦 Email: ${parts[0]}');
          print('📦 Password length: ${parts[1].length} chars');
        }
      }

      final isReady = await isBiometricLoginReady();
      print('📦 Ready for login: $isReady');

      print('🔍 ========================================');
      print('');
    } catch (e) {
      print('❌ Debug failed: $e');
    }
  }
}

// ============================================================================
// BIOMETRIC EXCEPTION
// ============================================================================

class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);

  @override
  String toString() => message;
}