import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/storage/secure_storage.dart';
import '../domain/user.dart';

/// Wraps Firebase Phone Auth (`verifyPhoneNumber` -> OTP -> ID token) and the
/// `/api/v1/auth/*` exchange endpoints. Firebase issues the phone
/// verification; the backend never sees the phone number directly, only the
/// verified Firebase ID token, per docs/API_CONTRACT.md.
class AuthRepository {
  AuthRepository(this._dio, this._secureStorage, this._firebaseAuth);

  final Dio _dio;
  final SecureStorageService _secureStorage;
  final FirebaseAuth _firebaseAuth;

  /// Starts phone verification. [onCodeSent] receives the `verificationId`
  /// needed by [confirmOtp]; [onAutoVerified] fires on Android instant
  /// auto-retrieval, short-circuiting the OTP screen entirely.
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(AppUser user) onAutoVerified,
    required void Function(String message) onFailed,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final UserCredential result = await _firebaseAuth.signInWithCredential(credential);
        final AppUser? user = await _exchangeFirebaseToken(result);
        if (user != null) {
          onAutoVerified(user);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? e.code);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<AppUser> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final UserCredential result = await _firebaseAuth.signInWithCredential(credential);
    final AppUser? user = await _exchangeFirebaseToken(result);
    if (user == null) {
      throw StateError('Failed to obtain Firebase ID token after OTP confirmation.');
    }
    return user;
  }

  Future<AppUser?> _exchangeFirebaseToken(UserCredential credential) async {
    final String? idToken = await credential.user?.getIdToken();
    if (idToken == null) return null;
    return login(firebaseIdToken: idToken);
  }

  /// `POST /api/v1/auth/login` — exchanges the Firebase ID token for a
  /// Sanctum token, persists it, and returns the `User` from the envelope.
  Future<AppUser> login({required String firebaseIdToken}) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/auth/login',
      data: {'firebase_id_token': firebaseIdToken},
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      (response.data as Map)['data'] as Map,
    );
    final String token = data['token'] as String;
    await _secureStorage.saveToken(token);
    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<AppUser> fetchMe() async {
    final Response<dynamic> response = await _dio.get<dynamic>('/auth/me');
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      (response.data as Map)['data'] as Map,
    );
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateMe({String? name, String? preferredLanguage}) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      '/auth/me',
      data: {
        if (name != null) 'name': name,
        if (preferredLanguage != null) 'preferred_language': preferredLanguage,
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      (response.data as Map)['data'] as Map,
    );
    return AppUser.fromJson(data);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _secureStorage.clearToken();
  }

  Future<bool> hasStoredSession() async {
    final String? token = await _secureStorage.readToken();
    return token != null && token.isNotEmpty;
  }
}
