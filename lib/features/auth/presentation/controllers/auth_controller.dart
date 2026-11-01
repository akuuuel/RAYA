import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/notification_service.dart';
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

  /// Masuk langsung dengan email dan kata sandi (Instan tanpa menunggu OTP)
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final result = await _repository.signInWithPassword(
        email: email,
        password: password,
      );

      if (result.isNewUser) {
        state = state.copyWith(
          status: AuthStatus.needsProfileCompletion,
          email: result.email,
          errorMessage: null,
        );
      } else {
        final profile = await _repository.getCurrentProfile();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userProfile: profile,
          email: result.email,
          errorMessage: null,
        );
      }
      return true;
    } catch (e) {
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Mendaftar akun baru dengan email dan kata sandi (mengirim verifikasi OTP sekali)
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signUpWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.otpSent,
        email: email.trim().toLowerCase(),
        errorMessage: null,
      );
      return true;
    } catch (e) {
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Mengirim kode OTP ke email (cadangan login tanpa password / verifikasi)
  Future<bool> sendOtp(String email, {bool shouldCreateUser = true}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.requestEmailOtp(email, shouldCreateUser: shouldCreateUser);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        email: email.trim().toLowerCase(),
        errorMessage: null,
      );
      return true;
    } catch (e) {
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Verifikasi kode OTP 6/8 digit (FR-01, FR-02)
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
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Melengkapi profil saat pendaftaran (FR-03, FR-04)
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
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Memperbarui informasi profil pengguna (Nama, Username, Bio, Avatar Foto)
  Future<bool> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final updatedProfile = await _repository.updateProfile(
        displayName: displayName,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      state = state.copyWith(
        userProfile: updatedProfile,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      final message = _formatErrorMessage(e);
      state = state.copyWith(errorMessage: message);
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
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Mengonversi error teknis / sistem menjadi pesan yang ramah pengguna
  String _formatErrorMessage(dynamic error) {
    final raw = error.toString().toLowerCase();

    // 1. Masalah Kata Sandi Salah / Kredensial Tidak Valid
    if (raw.contains('invalid login credentials') ||
        raw.contains('invalid_credentials') ||
        raw.contains('wrong password') ||
        raw.contains('invalid email or password')) {
      return 'Email atau kata sandi salah. Silakan periksa kembali.';
    }

    // 2. Kata Sandi Terlalu Pendek
    if (raw.contains('password should be at least') || raw.contains('weak_password')) {
      return 'Kata sandi minimal terdiri dari 6 karakter.';
    }

    // 3. Masalah Koneksi / Jaringan / DNS / Timeout
    if (raw.contains('socketfailed') ||
        raw.contains('no address associated with hostname') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('network is unreachable') ||
        raw.contains('handshakeexception') ||
        raw.contains('clientexception') ||
        raw.contains('timeout') ||
        raw.contains('timed out')) {
      return 'Koneksi internet bermasalah. Periksa jaringan data/Wi-Fi Anda dan coba lagi.';
    }

    // 4. Kode OTP Kedaluwarsa atau Salah
    if (raw.contains('otp_expired') ||
        raw.contains('token has expired') ||
        raw.contains('invalid token')) {
      return 'Kode verifikasi salah atau sudah kedaluwarsa. Silakan minta kode baru.';
    }

    // 5. Batas Frekuensi / Rate Limiting
    if (raw.contains('rate_limit') ||
        raw.contains('over_email_send_rate_limit') ||
        raw.contains('429') ||
        raw.contains('too many requests')) {
      return 'Terlalu banyak permintaan. Silakan tunggu sekitar 1 menit sebelum meminta kode lagi.';
    }

    // 6. Masalah Pengiriman Email
    if (raw.contains('error sending confirmation email') ||
        raw.contains('unexpected_failure') ||
        raw.contains('error sending email')) {
      return 'Gagal mengirim email verifikasi. Pastikan alamat email benar atau coba beberapa saat lagi.';
    }

    // 7. Username Duplikat
    if (raw.contains('username') &&
        (raw.contains('unique') || raw.contains('duplicate') || raw.contains('already exists'))) {
      return 'Username ini sudah digunakan oleh orang lain. Silakan pilih username lain.';
    }

    // 8. Izin Akses / RLS
    if (raw.contains('row-level security') || raw.contains('violates row-level security')) {
      return 'Gagal menyimpan data profil. Silakan coba lagi.';
    }

    // 9. Pengguna Sudah Ada
    if (raw.contains('user already registered') || raw.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masukkan kata sandi untuk masuk.';
    }

    // 10. Akun Belum Terdaftar Saat Mencoba Masuk
    if (raw.contains('signups not allowed') ||
        raw.contains('user not found') ||
        raw.contains('user_not_found') ||
        raw.contains('signup disabled')) {
      return 'Akun dengan email ini belum terdaftar. Silakan pilih Daftar Akun Baru terlebih dahulu.';
    }

    // Jika pesan Exception sudah berupa teks Bahasa Indonesia yang bersih dan singkat
    final clean = error.toString().replaceFirst('Exception: ', '').trim();
    if (!clean.contains('(') && !clean.contains('{') && clean.length < 80) {
      return clean;
    }

    return 'Terjadi kendala saat memproses permintaan. Silakan coba lagi.';
  }

  /// Keluar dari akun
  Future<void> signOut() async {
    NotificationService.instance.stopListening();
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
