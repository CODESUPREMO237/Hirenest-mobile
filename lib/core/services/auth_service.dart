// ============================================================================
// auth_service.dart (COMPLETE - Both Firebase & Backend JWT Tokens)
// lib/core/repositories/auth_service.dart
// ============================================================================

import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/storage_keys.dart';
import '../utils/logger.dart';
import '../network/dio_client.dart';
import '../config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';

// --------------------- Models ---------------------
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      tokenType: json['tokenType'] as String,
    );
  }
}

class AuthResult {
  final Map<String, dynamic> user;
  final AuthTokens tokens;
  final bool isNewUser;

  AuthResult({
    required this.user,
    required this.tokens,
    this.isNewUser = false,
  });
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

// --------------------- Providers ---------------------
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

// --------------------- AuthService ---------------------
class AuthService {
  final Ref ref;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  Completer<Map<String, String>>? _oauthCompleter;

  String get baseUrl => '${AppConfig.apiBaseUrl}/auth';

  AuthService(this.ref);

  // ---------------- Auth State ----------------
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // ---------------- Token Management ----------------

  /// ✅ Get Firebase ID Token (for Firebase-specific features like chat, realtime, etc.)
  /// Use this for: Socket.io, Firebase Realtime DB, etc.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        print('⚠️ [AuthService] No Firebase user - cannot get Firebase token');
        return null;
      }

      print('🔥 [AuthService.getIdToken] Getting Firebase ID token...');
      final token = await user.getIdToken(forceRefresh);

      if (token != null) {
        print('✅ [AuthService.getIdToken] Firebase token: ${token.substring(
            0, 30)}...');
      } else {
        print('⚠️ [AuthService.getIdToken] Firebase token is null');
      }

      return token;
    } catch (e, stackTrace) {
      print('❌ [AuthService.getIdToken] Error: $e');
      AppLogger.error(
          'Error getting Firebase token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// ✅ Get Backend JWT Token (for REST API requests)
  /// Use this for: HTTP requests to your backend (/api/v1/jobs, /api/v1/users, etc.)
  Future<String?> getBackendToken({bool forceRefresh = false}) async {
    try {
      print('🎫 [AuthService.getBackendToken] Getting backend JWT token...');

      // Get the backend JWT token
      final token = await _storage.read(key: StorageKeys.authToken);

      if (token == null) {
        print('⚠️ [AuthService.getBackendToken] No backend token in storage');
        return null;
      }

      print('✅ [AuthService.getBackendToken] Backend JWT: ${token.substring(
          0, 30)}...');

      // Check if token is expired and refresh if needed
      if (!forceRefresh) {
        final expiryStr = await _storage.read(
            key: '${StorageKeys.authToken}_expiry');
        if (expiryStr != null) {
          final expiry = DateTime.parse(expiryStr);

          // Refresh if token expires in less than 5 minutes
          if (expiry.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
            print(
                '🔄 [AuthService.getBackendToken] Token expiring soon, refreshing...');
            await refreshAccessToken();
            final newToken = await _storage.read(key: StorageKeys.authToken);
            print('✅ [AuthService.getBackendToken] Token refreshed');
            return newToken;
          }
        }
      }

      return token;
    } catch (e, stackTrace) {
      print('❌ [AuthService.getBackendToken] Error: $e');
      AppLogger.error(
          'Error getting backend token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Store authentication tokens securely
// Replace your _storeTokens method in auth_service.dart with this:

  /// Store authentication tokens securely with verification
  Future<void> _storeTokens(AuthTokens tokens) async {
    print('💾 [AuthService._storeTokens] Storing backend JWT tokens...');

    try {
      // Store all tokens
      await _storage.write(key: StorageKeys.authToken, value: tokens.accessToken);
      await _storage.write(key: StorageKeys.refreshToken, value: tokens.refreshToken);

      // Store expiry timestamp
      final expiryTime = DateTime.now().add(Duration(seconds: tokens.expiresIn));
      await _storage.write(
        key: '${StorageKeys.authToken}_expiry',
        value: expiryTime.toIso8601String(),
      );

      // ✅ CRITICAL: Add a small delay to ensure storage completes
      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ VERIFY the tokens were stored correctly
      final storedToken = await _storage.read(key: StorageKeys.authToken);
      final storedRefresh = await _storage.read(key: StorageKeys.refreshToken);

      if (storedToken == null || storedRefresh == null) {
        print('❌ [AuthService._storeTokens] VERIFICATION FAILED - tokens not in storage!');

        // Retry once
        print('🔄 [AuthService._storeTokens] Retrying storage...');
        await Future.delayed(const Duration(milliseconds: 200));

        await _storage.write(key: StorageKeys.authToken, value: tokens.accessToken);
        await _storage.write(key: StorageKeys.refreshToken, value: tokens.refreshToken);

        await Future.delayed(const Duration(milliseconds: 100));

        final retryToken = await _storage.read(key: StorageKeys.authToken);
        if (retryToken == null) {
          throw AuthException('Failed to store authentication tokens');
        }
      }

      print('✅ [AuthService._storeTokens] Backend tokens stored and verified');
    } catch (e, stackTrace) {
      print('❌ [AuthService._storeTokens] Storage error: $e');
      AppLogger.error('Token storage failed', error: e, stackTrace: stackTrace);
      throw AuthException('Failed to store authentication tokens');
    }
  }

  /// Get valid access token (auto-refresh if expired)
  Future<String> _getValidAccessToken() async {
    final token = await _storage.read(key: StorageKeys.authToken);

    if (token == null) {
      throw AuthException('No auth token found. Please login again.');
    }

    // Check if token is expired
    final expiryStr = await _storage.read(
        key: '${StorageKeys.authToken}_expiry');
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);

      // Refresh if token expires in less than 5 minutes
      if (expiry.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
        AppLogger.info('Token expiring soon, refreshing...');
        await refreshAccessToken();
        return await _storage.read(key: StorageKeys.authToken) ?? token;
      }
    }

    return token;
  }

  /// Refresh access token using refresh token
  Future<void> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);

      if (refreshToken == null) {
        throw AuthException('No refresh token found. Please login again.');
      }

      final res = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tokens = AuthTokens.fromJson(data['data']['tokens']);
        await _storeTokens(tokens);
        AppLogger.info('Access token refreshed successfully');
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(
          data['message'] ?? 'Token refresh failed',
          code: data['code'],
        );
      }
    } on AuthException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Token refresh failed', error: e, stackTrace: st);

      // Clear tokens on refresh failure
      await clearAuthData();
      throw AuthException('Session expired. Please login again.');
    }
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    print('🧹 [AuthService.clearAuthData] Clearing all auth data...');
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: '${StorageKeys.authToken}_expiry');
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userEmail);
    await _storage.delete(key: StorageKeys.userRole);
    await _storage.delete(key: StorageKeys.userData);
    print('✅ [AuthService.clearAuthData] Auth data cleared');
  }

  /// Get auth headers for API requests
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getValidAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------------- Registration ----------------

  Future<AuthResult> register({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> profile,
  }) async {
    try {
      print('📝 [AuthService.register] Starting registration...');

      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
          'profile': profile,
        }),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body)['data'];

        // Store backend JWT tokens
        final tokens = AuthTokens.fromJson(data['tokens']);
        await _storeTokens(tokens);

        // Store user data
        final user = data['user'];
        await _storage.write(key: StorageKeys.userId, value: user['id'] ?? user['_id']);
        await _storage.write(key: StorageKeys.userEmail, value: user['email']);
        await _storage.write(key: StorageKeys.userRole, value: user['role']);
        await _storage.write(
            key: StorageKeys.userData, value: jsonEncode(user));

        // Sign in to Firebase with custom token
        final firebaseToken = data['firebaseToken'];
        await _firebaseAuth.signInWithCustomToken(firebaseToken);

        AppLogger.info('Registration successful: ${user['email']}');
        print('✅ [AuthService.register] Registration successful');

        return AuthResult(
          user: user,
          tokens: tokens,
          isNewUser: true,
        );
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(data['message'] ?? 'Registration failed');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase error during registration', error: e);
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e, st) {
      AppLogger.error('Registration failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed. Please try again.');
    }
  }

  // ---------------- Login ----------------

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [AuthService.login] Starting login...');

      // 1. Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ [AuthService.login] Firebase sign-in successful');

      // 2. Get Firebase ID token
      final firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) {
        throw AuthException('Failed to get Firebase token');
      }
      print('✅ [AuthService.login] Firebase token obtained');

      // 3. Exchange Firebase token for backend JWT
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];

        // Store backend JWT tokens
        final tokens = AuthTokens.fromJson(data['tokens']);
        await _storeTokens(tokens);

        // Store user data
        final user = data['user'];
        await _storage.write(key: StorageKeys.userId, value: user['id'] ?? user['_id']);
        await _storage.write(key: StorageKeys.userEmail, value: user['email']);
        await _storage.write(key: StorageKeys.userRole, value: user['role']);
        await _storage.write(
            key: StorageKeys.userData, value: jsonEncode(user));

        AppLogger.info('Login successful: ${user['email']}');
        print('✅ [AuthService.login] Login complete - both tokens stored');

        return AuthResult(user: user, tokens: tokens);
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(data['message'] ?? 'Login failed');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase login error', error: e);
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e, st) {
      AppLogger.error('Login failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Login failed. Please try again.');
    }
  }

  // Rest of your code remains the same...
  // (Social auth, logout, password reset, profile methods, etc.)

  // For brevity, keeping the existing implementations below

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleIdToken = await _getGoogleIdToken();
      return await _completeSocialAuth('google', googleIdToken);
    } catch (e, st) {
      AppLogger.error('Google sign-in failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }


// ============================================================================
// OAuth Implementation Using app_links (Modern Replacement for uni_links)
// Add to your auth_service.dart
// ============================================================================


  /// ✅ GitHub Sign-In using app_links
  Future<AuthResult> signInWithGithub() async {
    try {
      print(
          '🔐 [AuthService.signInWithGithub] Starting GitHub authentication...');

      final clientId = AppConfig.githubClientId;
      final redirectUri = AppConfig.githubRedirectUri;

      print('📋 [GitHub] Config check:');
      print('   Client ID: ${clientId.isNotEmpty ? "✅ ${clientId.substring(
          0, 10)}..." : "❌ MISSING"}');
      print('   Redirect URI: ${redirectUri.isNotEmpty
          ? "✅ $redirectUri"
          : "❌ MISSING"}');

      if (clientId.isEmpty || redirectUri.isEmpty) {
        throw AuthException('GitHub OAuth not configured');
      }

      // Generate state for CSRF protection
      final state = _generateRandomString(32);
      print('🔐 [GitHub] Generated state: ${state.substring(0, 10)}...');

      // Build authorization URL
      final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': 'read:user user:email',
        'state': state,
      });

      print('🌐 [GitHub] Authorization URL: $authUrl');

      // Create a completer to wait for the callback
      _oauthCompleter = Completer<Map<String, String>>();

      // Set up deep link listener BEFORE opening browser
      print('👂 [GitHub] Setting up app_links listener...');
      _linkSubscription = _appLinks.uriLinkStream.listen(
            (Uri uri) {
          print('📥 [GitHub] Deep link received: $uri');

          if (uri.scheme == 'com.jobconnect' &&
              uri.host == 'auth' &&
              uri.path == '/github/callback') {
            print('✅ [GitHub] Valid GitHub OAuth callback detected!');

            if (_oauthCompleter != null && !_oauthCompleter!.isCompleted) {
              final params = uri.queryParameters;
              final code = params['code'];
              final returnedState = params['state'];
              final error = params['error'];

              print('🔍 [GitHub] Callback parameters:');
              print('   Code: ${code?.substring(0, 10)}...');
              print('   State: ${returnedState?.substring(0, 10)}...');
              print('   Error: $error');

              if (error != null) {
                print('❌ [GitHub] OAuth error: $error');
                _oauthCompleter!.completeError(
                  AuthException('GitHub authorization failed: $error'),
                );
              } else if (code == null) {
                print('❌ [GitHub] No code in callback');
                _oauthCompleter!.completeError(
                  AuthException('No authorization code received'),
                );
              } else if (returnedState != state) {
                print('❌ [GitHub] State mismatch!');
                _oauthCompleter!.completeError(
                  AuthException('State mismatch - possible security issue'),
                );
              } else {
                print('✅ [GitHub] Code and state verified!');
                _oauthCompleter!.complete({
                  'code': code,
                  'state': returnedState!,
                });
              }
            }
          } else {
            print('ℹ️ [GitHub] Deep link not for GitHub OAuth: $uri');
          }
        },
        onError: (err) {
          print('❌ [GitHub] Deep link stream error: $err');
          if (_oauthCompleter != null && !_oauthCompleter!.isCompleted) {
            _oauthCompleter!.completeError(err);
          }
        },
      );

      // Small delay to ensure listener is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Open browser with OAuth URL
      print('🌐 [GitHub] Launching browser...');
      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        print('❌ [GitHub] Failed to launch browser');
        await _cleanupOAuthListener();
        throw AuthException('Could not open browser for GitHub authentication');
      }

      print('⏳ [GitHub] Waiting for OAuth callback (timeout: 5 minutes)...');

      // Wait for callback with timeout
      final params = await _oauthCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print('⏱️ [GitHub] OAuth timed out');
          throw AuthException('GitHub sign-in timed out');
        },
      );

      // Clean up listener
      await _cleanupOAuthListener();

      final code = params['code']!;
      print('✅ [GitHub] Authorization code received: ${code.substring(
          0, 10)}...');

      // Exchange code for tokens via backend
      return await _exchangeGithubCode(code, redirectUri);
    } catch (e, st) {
      await _cleanupOAuthListener();
      print('❌ [GitHub] Exception: $e');
      AppLogger.error('GitHub sign-in failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('GitHub sign-in failed: ${e.toString()}');
    }
  }


  /// Microsoft Sign-In
// ============================================================================
// FRONTEND: Microsoft OAuth with PKCE (auth_service.dart)
// Replace your signInWithMicrosoft method
// ============================================================================

  /// Microsoft Sign-In with PKCE (Secure for mobile apps)
  Future<AuthResult> signInWithMicrosoft() async {
    try {
      print(
          '🔐 [AuthService.signInWithMicrosoft] Starting Microsoft authentication with PKCE...');

      final clientId = AppConfig.microsoftClientId;
      final tenantId = AppConfig.microsoftTenantId;
      final redirectUri = AppConfig.microsoftRedirectUri;

      if (clientId.isEmpty || redirectUri.isEmpty) {
        throw AuthException('Microsoft OAuth not configured');
      }

      // ✅ Generate PKCE parameters (like Twitter)
      final state = _generateRandomString(32);
      final codeVerifier = _generateRandomString(128);
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      print('🔐 [Microsoft] Generated PKCE parameters');

      // Build authorization URL with PKCE
      final authUrl = Uri.https(
        'login.microsoftonline.com',
        '/$tenantId/oauth2/v2.0/authorize',
        {
          'client_id': clientId,
          'response_type': 'code',
          'redirect_uri': redirectUri,
          'response_mode': 'query',
          'scope': 'openid profile email User.Read offline_access',
          'state': state,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      );

      print('🌐 [Microsoft] Authorization URL: $authUrl');

      // Create completer
      _oauthCompleter = Completer<Map<String, String>>();

      // Set up deep link listener
      _linkSubscription = _appLinks.uriLinkStream.listen(
            (Uri uri) {
          if (uri.scheme == 'com.jobconnect' &&
              uri.host == 'auth' &&
              uri.path == '/microsoft/callback') {
            if (_oauthCompleter != null && !_oauthCompleter!.isCompleted) {
              final params = uri.queryParameters;
              final code = params['code'];
              final returnedState = params['state'];
              final error = params['error'];

              if (error != null) {
                _oauthCompleter!.completeError(
                  AuthException('Microsoft authorization failed: $error'),
                );
              } else if (code == null) {
                _oauthCompleter!.completeError(
                  AuthException('No authorization code received'),
                );
              } else if (returnedState != state) {
                _oauthCompleter!.completeError(
                  AuthException('State mismatch - possible security issue'),
                );
              } else {
                print('✅ [Microsoft] Code and state verified!');
                _oauthCompleter!.complete({
                  'code': code,
                  'state': returnedState!,
                  'codeVerifier': codeVerifier, // Pass code verifier to backend
                });
              }
            }
          }
        },
        onError: (err) {
          if (_oauthCompleter != null && !_oauthCompleter!.isCompleted) {
            _oauthCompleter!.completeError(err);
          }
        },
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Open browser
      final launched = await launchUrl(
          authUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        await _cleanupOAuthListener();
        throw AuthException(
            'Could not open browser for Microsoft authentication');
      }

      print('⏳ [Microsoft] Waiting for OAuth callback...');

      // Wait for callback
      final params = await _oauthCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw AuthException('Microsoft sign-in timed out'),
      );

      await _cleanupOAuthListener();

      final code = params['code']!;
      final codeVerifierFromCallback = params['codeVerifier']!;
      print('✅ [Microsoft] Authorization code received');

      // Exchange code with PKCE verifier
      return await _exchangeMicrosoftCode(
          code, codeVerifierFromCallback, redirectUri);
    } catch (e, st) {
      await _cleanupOAuthListener();
      AppLogger.error('Microsoft sign-in failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Microsoft sign-in failed: ${e.toString()}');
    }
  }

  /// Exchange Microsoft code for backend tokens (with PKCE)
  Future<AuthResult> _exchangeMicrosoftCode(String code,
      String codeVerifier,
      String redirectUri,) async {
    print('🔄 [Microsoft] Exchanging code with backend (PKCE)');

    final response = await http.post(
      Uri.parse('$baseUrl/microsoft/exchange'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'codeVerifier': codeVerifier, // Send code verifier to backend
        'redirectUri': redirectUri,
      }),
    ).timeout(const Duration(seconds: 30));

    print('📥 [Microsoft] Backend response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];

      final tokens = AuthTokens.fromJson(data['tokens']);
      await _storeTokens(tokens);

      final user = data['user'];
      await _storage.write(key: StorageKeys.userId, value: user['id'] ?? user['_id']);
      await _storage.write(key: StorageKeys.userEmail, value: user['email']);
      await _storage.write(key: StorageKeys.userRole, value: user['role']);
      await _storage.write(key: StorageKeys.userData, value: jsonEncode(user));

      final firebaseToken = data['firebaseToken'];
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        await _firebaseAuth.signInWithCustomToken(firebaseToken);
      }

      AppLogger.info('Microsoft authentication successful: ${user['email']}');
      print('🎉 [Microsoft] Authentication flow complete!');

      return AuthResult(
        user: user,
        tokens: tokens,
        isNewUser: data['isNewUser'] ?? false,
      );
    } else {
      final errorData = jsonDecode(response.body);
      throw AuthException(
          errorData['message'] ?? 'Microsoft authentication failed');
    }
  }

  /// Link Microsoft Account
  Future<void> linkMicrosoftAccount() async {
    try {
      print('🔗 [AuthService.linkMicrosoftAccount] Starting...');

      final clientId = AppConfig.microsoftClientId;
      final tenantId = AppConfig.microsoftTenantId;
      final redirectUri = AppConfig.microsoftRedirectUri;

      if (clientId.isEmpty || redirectUri.isEmpty) {
        throw AuthException('Microsoft OAuth not configured');
      }

      final state = _generateRandomString(32);
      final nonce = _generateRandomString(32);

      final authUrl = Uri.https(
        'login.microsoftonline.com',
        '/$tenantId/oauth2/v2.0/authorize',
        {
          'client_id': clientId,
          'response_type': 'code',
          'redirect_uri': redirectUri,
          'response_mode': 'query',
          'scope': 'openid profile email User.Read',
          'state': state,
          'nonce': nonce,
        },
      );

      _oauthCompleter = Completer<Map<String, String>>();

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        if (uri.scheme == 'com.jobconnect' &&
            uri.host == 'auth' &&
            uri.path == '/microsoft/callback') {
          if (_oauthCompleter != null && !_oauthCompleter!.isCompleted) {
            final params = uri.queryParameters;
            final code = params['code'];
            final returnedState = params['state'];
            final error = params['error'];

            if (error != null) {
              _oauthCompleter!.completeError(
                AuthException('Microsoft authorization failed: $error'),
              );
            } else if (code == null) {
              _oauthCompleter!.completeError(
                AuthException('No authorization code received'),
              );
            } else if (returnedState != state) {
              _oauthCompleter!.completeError(
                AuthException('State mismatch'),
              );
            } else {
              _oauthCompleter!.complete(
                  {'code': code, 'state': returnedState!});
            }
          }
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      final launched = await launchUrl(
          authUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        await _cleanupOAuthListener();
        throw AuthException('Could not open browser');
      }

      final params = await _oauthCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw AuthException('Microsoft linking timed out'),
      );

      await _cleanupOAuthListener();

      final code = params['code']!;
      await _linkMicrosoftToAccount(code, redirectUri);

      AppLogger.info('Microsoft account linked successfully');
      print('✅ [Microsoft Link] Complete!');
    } catch (e, st) {
      await _cleanupOAuthListener();
      AppLogger.error('Microsoft linking failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Microsoft linking failed: ${e.toString()}');
    }
  }

  /// Link Microsoft account via backend
  Future<void> _linkMicrosoftToAccount(String code, String redirectUri) async {
    final token = await getBackendToken();
    if (token == null) {
      throw AuthException('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/microsoft/link'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'code': code,
        'redirectUri': redirectUri,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      await fetchProfile();
    } else {
      final errorData = jsonDecode(response.body);
      throw AuthException(
          errorData['message'] ?? 'Failed to link Microsoft account');
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Clean up OAuth listener
  Future<void> _cleanupOAuthListener() async {
    print('🧹 Cleaning up OAuth listener...');
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _oauthCompleter = null;
  }

  /// Exchange GitHub code for backend tokens
  Future<AuthResult> _exchangeGithubCode(String code,
      String redirectUri) async {
    print(
        '🔄 [GitHub] Exchanging code with backend at: $baseUrl/github/exchange');

    final response = await http.post(
      Uri.parse('$baseUrl/github/exchange'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    ).timeout(const Duration(seconds: 30));

    print('📥 [GitHub] Backend response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];

      final tokens = AuthTokens.fromJson(data['tokens']);
      await _storeTokens(tokens);
      print('✅ [GitHub] Backend JWT tokens stored');

      final user = data['user'];
      await _storage.write(key: StorageKeys.userId, value: user['id'] ?? user['_id']);
      await _storage.write(key: StorageKeys.userEmail, value: user['email']);
      await _storage.write(key: StorageKeys.userRole, value: user['role']);
      await _storage.write(key: StorageKeys.userData, value: jsonEncode(user));
      print('✅ [GitHub] User data stored: ${user['email']}');

      final firebaseToken = data['firebaseToken'];
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        await _firebaseAuth.signInWithCustomToken(firebaseToken);
        print('✅ [GitHub] Firebase authentication complete');
      }

      AppLogger.info('GitHub authentication successful: ${user['email']}');
      print('🎉 [GitHub] Authentication flow complete!');

      return AuthResult(
        user: user,
        tokens: tokens,
        isNewUser: data['isNewUser'] ?? false,
      );
    } else if (response.statusCode == 404) {
      final errorData = jsonDecode(response.body);
      print('❌ [GitHub] User not found: ${errorData['message']}');
      throw AuthException(
        errorData['message'] ?? 'Account not found. Please register first.',
        code: errorData['code'],
      );
    } else {
      final errorData = jsonDecode(response.body);
      print('❌ [GitHub] Backend error: ${errorData['message']}');
      throw AuthException(
          errorData['message'] ?? 'GitHub authentication failed');
    }
  }


  Future<AuthResult> _completeSocialAuth(String provider, String idToken) async {
    try {
      OAuthCredential credential;
      switch (provider.toLowerCase()) {
        case 'google':
          credential = GoogleAuthProvider.credential(idToken: idToken);
          break;
        case 'github':
          credential = GithubAuthProvider.credential(idToken);
          break;
        case 'microsoft':
          credential = TwitterAuthProvider.credential(
            accessToken: idToken,
            secret: '',
          );
          break;
        default:
          throw AuthException('Unsupported social provider');
      }

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      final firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) {
        throw AuthException('Failed to get Firebase token');
      }

      final res = await http.post(
        Uri.parse('$baseUrl/social'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'idToken': firebaseToken,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];

        final tokens = AuthTokens.fromJson(data['tokens']);

        // ✅ CRITICAL FIX: Ensure tokens are fully stored before proceeding
        await _storeTokens(tokens);

        // ✅ Add a small delay to ensure storage completes (especially on Android)
        await Future.delayed(const Duration(milliseconds: 100));

        final user = data['user'];

        // ✅ Store user data with proper null checking
        final userId = user['id'] ?? user['_id'];
        if (userId == null) {
          throw AuthException('Invalid user data received from backend');
        }

        await _storage.write(key: StorageKeys.userId, value: userId.toString());
        await _storage.write(key: StorageKeys.userEmail, value: user['email']);
        await _storage.write(key: StorageKeys.userRole, value: user['role']);
        await _storage.write(key: StorageKeys.userData, value: jsonEncode(user));

        // ✅ Another small delay to ensure all writes complete
        await Future.delayed(const Duration(milliseconds: 100));

        if (data['isNewUser'] == true) {
          AppLogger.info('🎉 New account created via $provider: ${user['email']}');
          print('🎉 [Social Auth] New user registered: ${user['email']}');
        } else {
          AppLogger.info('✅ Existing user logged in via $provider: ${user['email']}');
          print('✅ [Social Auth] Existing user logged in: ${user['email']}');
        }

        // ✅ Verify token was stored before returning
        final storedToken = await _storage.read(key: StorageKeys.authToken);
        if (storedToken == null) {
          print('❌ [Social Auth] Token verification failed - not stored!');
          throw AuthException('Failed to store authentication tokens');
        }
        print('✅ [Social Auth] Token verified in storage');

        return AuthResult(
          user: user,
          tokens: tokens,
          isNewUser: data['isNewUser'] ?? false,
        );
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(data['message'] ?? 'Social authentication failed');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase social auth error', error: e);
      throw AuthException(_getFirebaseErrorMessage(e));
    } catch (e, st) {
      AppLogger.error('Social authentication failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Social authentication failed. Please try again.');
    }
  }



  /// ✅ Fallback method to create social account from Flutter side
  /// (Only used if backend doesn't auto-create)
  Future<AuthResult> createSocialAccount(
      String provider,
      UserCredential userCredential,
      String firebaseToken,
      ) async {
    try {
      final user = userCredential.user!;

      print('📝 [Social Auth Fallback] Creating account for: ${user.email}');

      // Call backend registration endpoint
      final res = await http.post(
        Uri.parse('$baseUrl/social/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'idToken': firebaseToken,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];

        final tokens = AuthTokens.fromJson(data['tokens']);
        await _storeTokens(tokens);

        final userData = data['user'];
        await _storage.write(key: StorageKeys.userId, value: userData['id'] ?? userData['_id']);
        await _storage.write(key: StorageKeys.userEmail, value: userData['email']);
        await _storage.write(key: StorageKeys.userRole, value: userData['role']);
        await _storage.write(key: StorageKeys.userData, value: jsonEncode(userData));

        AppLogger.info('Social account created via fallback: ${userData['email']}');
        print('✅ [Social Auth Fallback] Account created');

        return AuthResult(
          user: userData,
          tokens: tokens,
          isNewUser: true,
        );
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(data['message'] ?? 'Failed to create account');
      }
    } catch (e, st) {
      AppLogger.error('Social account creation failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Failed to create account. Please try again.');
    }
  }



  Future<String> _getGoogleIdToken() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      await googleSignIn.signOut();

      final GoogleSignInAccount account = await googleSignIn.authenticate(
        scopeHint: [
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
      );

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('Failed to retrieve Google ID token');
      }

      return idToken;
    } catch (e) {
      if (e is AuthException) rethrow;
      AppLogger.error('Google sign-in error', error: e);
      throw AuthException('Google sign-in failed: ${e.toString()}');
    }
  }

  Future<String> _getGithubToken() async {
    final clientId = AppConfig.githubClientId;
    final redirectUri = AppConfig.githubRedirectUri;

    if (clientId.isEmpty || redirectUri.isEmpty) {
      throw AuthException('GitHub OAuth configuration missing');
    }

    final result = await FlutterWebAuth2.authenticate(
      url: 'https://github.com/login/oauth/authorize?client_id=$clientId&scope=read:user user:email',
      callbackUrlScheme: Uri.parse(redirectUri).scheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) {
      throw AuthException('GitHub sign-in failed');
    }

    final res = await http.post(
      Uri.parse('$baseUrl/github/exchange'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );

    if (res.statusCode != 200) {
      throw AuthException('GitHub token exchange failed');
    }

    return jsonDecode(res.body)['data']['accessToken'];
  }



  String _generateRandomString(int length) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<void> _signOutFromGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
      AppLogger.info('Signed out from Google');
    } catch (e) {
      AppLogger.warning('Google sign-out failed', error: e);
    }
  }

  Future<void> signOut() async {
    await logout();
  }

  Future<void> logout() async {
    try {
      try {
        final headers = await _getAuthHeaders();
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: headers,
        );
      } catch (e) {
        AppLogger.warning('Backend logout failed, continuing...', error: e);
      }

      await _firebaseAuth.signOut();
      await _signOutFromGoogle();
      await clearAuthData();

      AppLogger.info('Logout successful');
    } catch (e, st) {
      AppLogger.error('Logout error', error: e, stackTrace: st);
      await clearAuthData();
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/password-reset', data: {'email': email});
      AppLogger.info('Password reset email sent: $email');
    } on DioException catch (e) {
      AppLogger.error('Password reset failed', error: e);
      final message = e.response?.data?['message'] ?? 'Failed to send reset email';
      throw AuthException(message);
    } catch (e, st) {
      AppLogger.error('Unexpected password reset error', error: e, stackTrace: st);
      throw AuthException('Failed to send reset email');
    }
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final user = jsonDecode(res.body)['data']['user'];
        await _storage.write(key: StorageKeys.userData, value: jsonEncode(user));
        return user;
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(data['message'] ?? 'Failed to fetch profile');
      }
    } catch (e, st) {
      AppLogger.error('Profile fetch failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Failed to fetch profile');
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final headers = await _getAuthHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/send-verification'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        AppLogger.info('Verification email sent');
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(data['message'] ?? 'Failed to send verification email');
      }
    } catch (e, st) {
      AppLogger.error('Send verification email failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Failed to send verification email');
    }
  }

  Future<void> updateProfilePicture(String imagePath) async {
    try {
      final token = await _getValidAccessToken();
      final file = File(imagePath);

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${AppConfig.apiBaseUrl}/users/me/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('avatar', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        AppLogger.info('Profile picture updated successfully');
        await fetchProfile();
      } else {
        final data = jsonDecode(response.body);
        throw AuthException(data['message'] ?? 'Failed to update profile picture');
      }
    } catch (e, st) {
      AppLogger.error('Update profile picture failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Failed to update profile picture');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final headers = await _getAuthHeaders();

      final res = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (res.statusCode == 200) {
        final user = jsonDecode(res.body)['data']['user'];
        await _storage.write(key: StorageKeys.userData, value: jsonEncode(user));
        AppLogger.info('Profile updated successfully');
      } else {
        final data = jsonDecode(res.body);
        throw AuthException(data['message'] ?? 'Failed to update profile');
      }
    } catch (e, st) {
      AppLogger.error('Update profile failed', error: e, stackTrace: st);
      if (e is AuthException) rethrow;
      throw AuthException('Failed to update profile');
    }
  }

  Future<void> updateProfileFields({
    String? phone,
    String? bio,
    String? city,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? additionalFields,
  }) async {
    final updates = <String, dynamic>{};

    if (phone != null) updates['profile.phone'] = phone;
    if (bio != null) updates['profile.bio'] = bio;
    if (city != null) updates['profile.location.city'] = city;
    if (firstName != null) updates['profile.firstName'] = firstName;
    if (lastName != null) updates['profile.lastName'] = lastName;

    if (additionalFields != null) {
      updates.addAll(additionalFields);
    }

    if (updates.isEmpty) {
      throw AuthException('No fields to update');
    }

    await updateProfile(updates);
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'Account has been disabled';
      case 'invalid-credential':
        return 'Invalid login credentials';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}