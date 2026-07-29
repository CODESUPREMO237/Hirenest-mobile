import 'package:flutter/foundation.dart';
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
      debugPrint('📱 [BiometricService] Device supported: $supported');
      return supported;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error checking device support: $e');
      AppLogger.error('Error checking device support', error: e);
      return false;
    }
  }

  // ==========================================================================
  // BIOMETRIC AVAILABLE?
  // ==========================================================================

  Future<bool> isBiometricAvailable() async {
    try {
      debugPrint('🔍 [BiometricService] Checking biometric availability...');

      final deviceSupported = await isDeviceSupported();
      debugPrint('   - Device supported: $deviceSupported');

      if (!deviceSupported) {
        debugPrint('❌ [BiometricService] Device not supported');
        return false;
      }

      final canCheck = await auth.canCheckBiometrics;
      debugPrint('   - Can check biometrics: $canCheck');

      if (!canCheck) {
        debugPrint('❌ [BiometricService] Cannot check biometrics');
        return false;
      }

      final biometrics = await getAvailableBiometrics();
      debugPrint('   - Available biometrics: $biometrics');

      final available = biometrics.isNotEmpty;
      debugPrint('✅ [BiometricService] Biometric available: $available');

      return available;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error checking availability: $e');
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
      debugPrint('📋 [BiometricService] Available types: $types');
      return types;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error getting biometrics list: $e');
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
      debugPrint('🔐 [BiometricService] Starting authentication...');
      debugPrint('   - Reason: $reason');
      debugPrint('   - Biometric only: $biometricOnly');

      AppLogger.info("Starting biometric authentication…");

      final available = await isBiometricAvailable();
      if (!available) {
        debugPrint('❌ [BiometricService] Biometric not available');
        AppLogger.warning("Biometric not available on this device");
        return false;
      }

      debugPrint('🔓 [BiometricService] Showing biometric prompt...');

      final authenticated = await auth.authenticate(
        localizedReason: "Please authenticate to enable biometric login",
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      if (authenticated) {
        debugPrint('✅ [BiometricService] Authentication successful');
        AppLogger.info("Biometric auth success");
      } else {
        debugPrint('❌ [BiometricService] Authentication failed or cancelled');
        AppLogger.warning("Biometric auth failed");
      }

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('❌ [BiometricService] Platform exception: ${e.code} - ${e.message}');
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
      debugPrint('❌ [BiometricService] Unknown error: $e');
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
      debugPrint('🔐 [BiometricService] Authenticating for login...');

      // Check if biometric login is enabled
      final isEnabled = await isBiometricLoginEnabled();
      if (!isEnabled) {
        debugPrint('⚠️ [BiometricService] Biometric login not enabled');
        return null;
      }

      // ✅ Check if we have saved credentials
      final credentials = await _storage.read(key: StorageKeys.biometricCredentials);
      if (credentials == null || !credentials.contains('::')) {
        debugPrint('⚠️ [BiometricService] No saved credentials found');
        debugPrint('ℹ️ [BiometricService] User needs to login normally first');

        // The preference is still enabled, but credentials are missing
        // This happens after logout
        AppLogger.warning('Biometric enabled but no credentials. Please login normally first.');
        return null;
      }

      debugPrint('✅ [BiometricService] Credentials found, prompting for biometric...');

      // Authenticate with biometric
      final authenticated = await authenticate(
        reason: 'Authenticate to login',
        biometricOnly: true,
      );

      if (!authenticated) {
        debugPrint('❌ [BiometricService] Biometric authentication failed');
        return null;
      }

      debugPrint('✅ [BiometricService] Biometric authentication successful');

      // Return the saved credentials
      return await getSavedCredentials();
    } catch (e) {
      debugPrint('❌ [BiometricService] authenticateForLogin error: $e');
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

      debugPrint('📦 [BiometricService] isBiometricLoginEnabled: $isEnabled');
      debugPrint('   - Raw value: $enabled');

      return isEnabled;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error reading enabled status: $e');
      AppLogger.error("Error reading biometric login setting", error: e);
      return false;
    }
  }

  Future<bool> hasSavedCredentials() async {
    try {
      final credentials = await _storage.read(key: StorageKeys.biometricCredentials);
      final hasCredentials = credentials != null && credentials.contains("::");

      debugPrint('📦 [BiometricService] hasSavedCredentials: $hasCredentials');
      debugPrint('   - Raw value exists: ${credentials != null}');
      debugPrint('   - Contains separator: ${credentials?.contains("::") ?? false}');

      return hasCredentials;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error checking saved credentials: $e');
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

      debugPrint('📦 [BiometricService] isBiometricLoginReady: $isReady');
      debugPrint('   - Enabled: $enabled');
      debugPrint('   - Has credentials: $hasCredentials');

      return isReady;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error checking ready status: $e');
      return false;
    }
  }

  Future<void> enableBiometricLogin() async {
    try {
      debugPrint('📦 [BiometricService] Enabling biometric login...');

      await _storage.write(key: StorageKeys.biometricEnabled, value: 'true');

      // Verify
      final verified = await _storage.read(key: StorageKeys.biometricEnabled);
      debugPrint('✅ [BiometricService] Biometric login enabled');
      debugPrint('   - Verification: ${verified == 'true'}');

      AppLogger.info("Biometric login turned ON");
    } catch (e) {
      debugPrint('❌ [BiometricService] Enable failed: $e');
      AppLogger.error("Enable biometric login failed", error: e);
      throw BiometricException("Could not enable");
    }
  }

  Future<void> disableBiometricLogin() async {
    try {
      debugPrint('📦 [BiometricService] Disabling biometric login...');

      await _storage.write(key: StorageKeys.biometricEnabled, value: 'false');
      await _storage.delete(key: StorageKeys.biometricCredentials);

      debugPrint('✅ [BiometricService] Biometric login disabled');

      AppLogger.info("Biometric login turned OFF");
    } catch (e) {
      debugPrint('❌ [BiometricService] Disable failed: $e');
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
      debugPrint('📦 [BiometricService] Saving credentials...');
      debugPrint('   - Email: $email');
      debugPrint('   - Password length: ${password.length}');

      final combined = "$email::$password";

      await _storage.write(
        key: StorageKeys.biometricCredentials,
        value: combined,
      );

      // Verify the write
      final saved = await _storage.read(key: StorageKeys.biometricCredentials);
      final verified = saved == combined;

      debugPrint('✅ [BiometricService] Credentials saved');
      debugPrint('   - Verification: $verified');
      debugPrint('   - Saved length: ${saved?.length ?? 0}');

      AppLogger.info("Biometric credentials saved");
    } catch (e) {
      debugPrint('❌ [BiometricService] Save credentials failed: $e');
      AppLogger.error("Saving credentials failed", error: e);
      throw BiometricException("Could not save credentials");
    }
  }

  // ==========================================================================
  // READ LOGIN CREDENTIALS
  // ==========================================================================

  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      debugPrint('📦 [BiometricService] Getting saved credentials...');

      final raw = await _storage.read(key: StorageKeys.biometricCredentials);

      if (raw == null) {
        debugPrint('❌ [BiometricService] No credentials found');
        return null;
      }

      debugPrint('   - Raw data exists: ${raw.length} chars');

      final parts = raw.split("::");
      if (parts.length != 2) {
        debugPrint('❌ [BiometricService] Invalid credential format');
        return null;
      }

      debugPrint('✅ [BiometricService] Credentials retrieved');
      debugPrint('   - Email: ${parts[0]}');
      debugPrint('   - Password length: ${parts[1].length}');

      return {
        "email": parts[0],
        "password": parts[1],
      };
    } catch (e) {
      debugPrint('❌ [BiometricService] Get credentials failed: $e');
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
      debugPrint('🧹 [BiometricService] Clearing credentials (keeping preference)...');

      await _storage.delete(key: StorageKeys.biometricCredentials);

      debugPrint('✅ [BiometricService] Credentials cleared');

      // The biometric_login_enabled preference is NOT cleared
      // So user still sees biometric as "enabled" in settings

      AppLogger.info("Biometric credentials cleared (preference kept)");
    } catch (e) {
      debugPrint('❌ [BiometricService] Clear credentials failed: $e');
      AppLogger.error("Clear credentials failed", error: e);
    }
  }

  // ==========================================================================
  // CANCEL AUTHENTICATION
  // ==========================================================================

  Future<void> stopAuthentication() async {
    try {
      debugPrint('🛑 [BiometricService] Stopping authentication...');
      await auth.stopAuthentication();
      debugPrint('✅ [BiometricService] Authentication stopped');
    } catch (e) {
      debugPrint('❌ [BiometricService] Stop auth error: $e');
      AppLogger.error("Stop auth error", error: e);
    }
  }

  // ==========================================================================
  // BIOMETRIC DISPLAY NAME
  // ==========================================================================

  String getTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      debugPrint('📱 [BiometricService] Type: Face ID');
      return "Face ID";
    }
    if (types.contains(BiometricType.fingerprint)) {
      debugPrint('📱 [BiometricService] Type: Fingerprint');
      return "Fingerprint";
    }
    if (types.contains(BiometricType.iris)) {
      debugPrint('📱 [BiometricService] Type: Iris');
      return "Iris";
    }
    if (types.contains(BiometricType.strong)) {
      debugPrint('📱 [BiometricService] Type: Strong Biometric');
      return "Biometric";
    }
    if (types.contains(BiometricType.weak)) {
      debugPrint('📱 [BiometricService] Type: Weak Biometric');
      return "Biometric";
    }
    debugPrint('📱 [BiometricService] Type: Generic Biometric');
    return "Biometric";
  }

  // ==========================================================================
  // DEBUG HELPER
  // ==========================================================================

  Future<void> debugStorageContents() async {
    try {
      debugPrint('');
      debugPrint('🔍 ========================================');
      debugPrint('🔍 BIOMETRIC STORAGE DEBUG');
      debugPrint('🔍 ========================================');

      final enabled = await _storage.read(key: StorageKeys.biometricEnabled);
      final credentials = await _storage.read(key: StorageKeys.biometricCredentials);

      debugPrint('📦 Enabled status: $enabled');
      debugPrint('📦 Has credentials: ${credentials != null}');

      if (credentials != null) {
        final parts = credentials.split('::');
        debugPrint('📦 Credential format valid: ${parts.length == 2}');
        if (parts.length == 2) {
          debugPrint('📦 Email: ${parts[0]}');
          debugPrint('📦 Password length: ${parts[1].length} chars');
        }
      }

      final isReady = await isBiometricLoginReady();
      debugPrint('📦 Ready for login: $isReady');

      debugPrint('🔍 ========================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Debug failed: $e');
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
