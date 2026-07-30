import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
    ref.watch(firebaseAuthProvider),
  );
});

enum AuthStep { enterPhone, enterOtp, authenticated }

class AuthState {
  const AuthState({
    this.step = AuthStep.enterPhone,
    this.isLoading = false,
    this.errorMessage,
    this.verificationId,
    this.phoneNumber,
    this.user,
  });

  final AuthStep step;
  final bool isLoading;
  final String? errorMessage;
  final String? verificationId;
  final String? phoneNumber;
  final AppUser? user;

  AuthState copyWith({
    AuthStep? step,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? verificationId,
    String? phoneNumber,
    AppUser? user,
  }) {
    return AuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      user: user ?? this.user,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> checkExistingSession() async {
    final bool hasSession = await _repository.hasStoredSession();
    if (!hasSession) return;
    try {
      final AppUser user = await _repository.fetchMe();
      state = state.copyWith(step: AuthStep.authenticated, user: user);
    } catch (_) {
      // Stored token is stale/invalid; fall through to phone entry.
    }
  }

  Future<void> submitPhoneNumber(String e164Phone) async {
    state = state.copyWith(isLoading: true, clearError: true, phoneNumber: e164Phone);
    try {
      await _repository.startPhoneVerification(
        phoneNumber: e164Phone,
        onCodeSent: (verificationId) {
          state = state.copyWith(
            isLoading: false,
            step: AuthStep.enterOtp,
            verificationId: verificationId,
          );
        },
        onAutoVerified: (user) {
          state = state.copyWith(isLoading: false, step: AuthStep.authenticated, user: user);
        },
        onFailed: (message) {
          state = state.copyWith(isLoading: false, errorMessage: message);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> submitOtp(String smsCode) async {
    final String? verificationId = state.verificationId;
    if (verificationId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AppUser user = await _repository.confirmOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      state = state.copyWith(isLoading: false, step: AuthStep.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }

  void setUser(AppUser user) {
    state = state.copyWith(user: user);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
