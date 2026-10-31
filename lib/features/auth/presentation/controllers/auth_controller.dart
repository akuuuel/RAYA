import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider repository autentikasi.
/// Otomatis memilih MockAuthRepository saat testing/dev, dan SupabaseAuthRepository di mode live.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMock) {
    return MockAuthRepository();
  }
  return SupabaseAuthRepository();
});

/// Controller StateNotifier Riverpod untuk mengelola alur autentikasi FR-01 sampai FR-05.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState(status: AuthStatus.loading)) {
    _checkInitialSession();
  }

  /// Memeriksa sesi login tersimpan secara otomatis (Auto-login / Sesi Persisten).
  /// Pengguna yang sudah pernah login TIDAK PERLU meminta OTP lagi setiap kali membuka aplikasi.
  Future<void> _checkInitialSession() async {
    try {
      final profile = await _repository.getCurrentProfile();
      if (profile != null) {
        if (profile.username == null || profile.birthDate == null) {
          state = state.copyWith(
            status: AuthStatus.needsProfileCompletion,
            email: profile.email,
            userProfile: profile,
            errorMessage: null,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            userProfile: profile,
            email: profile.email,
            errorMessage: null,
          );
        }
      } else {
        state = state.copyWith(status: AuthStatus.initial, errorMessage: null);
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.initial, errorMessage: null);
    }
  }

  /// Mengirim kode OTP ke email (FR-01, FR-02)
  Future<bool> sendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.requestEmailOtp(email);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        email: email.trim().toLowerCase(),
        errorMessage: null,
      );
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Verifikasi kode OTP 6 digit (FR-01, FR-02)
  Future<bool> verifyOtp(String otp) async {
    final currentEmail = state.email;
    if (currentEmail == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Alamat email belum diisi.',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await _repository.verifyEmailOtp(
        email: currentEmail,
        otp: otp,
      );

      if (result.isNewUser) {
        state = state.copyWith(
          status: AuthStatus.needsProfileCompletion,
          errorMessage: null,
        );
      } else {
        final profile = await _repository.getCurrentProfile();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userProfile: profile,
          errorMessage: null,
        );
      }
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Melengkapi profil saat pendaftaran (FR-03, FR-04)
  /// Pengecekan batas usia 18 tahun disimpan di profil.
  Future<bool> completeProfile({
    required String username,
    required String displayName,
    required DateTime birthDate,
    String? avatarUrl,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final profile = await _repository.completeProfile(
        username: username,
        displayName: displayName,
        birthDate: birthDate,
        avatarUrl: avatarUrl,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: profile,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Menghapus akun pengguna (FR-05)
  Future<bool> deleteAccount() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.deleteAccount();
      state = const AuthState(status: AuthStatus.initial);
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Keluar dari akun
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.initial);
  }

  /// Mengatur ulang pesan kesalahan
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
