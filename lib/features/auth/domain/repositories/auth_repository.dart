import '../entities/user_profile.dart';

/// Hasil verifikasi autentikasi OTP (FR-01, FR-02)
class AuthResult {
  final String userId;
  final String email;
  final bool isNewUser;
  final bool isAdult;

  const AuthResult({
    required this.userId,
    required this.email,
    required this.isNewUser,
    required this.isAdult,
  });
}

/// Kontrak Repository Autentikasi dan Profil Pengguna sesuai FR-01 sampai FR-05.
abstract class AuthRepository {
  /// Mengirim kode OTP 6 digit ke alamat email (FR-01, FR-02)
  Future<void> requestEmailOtp(String email);

  /// Memverifikasi kode OTP 6 digit yang dimasukkan pengguna (FR-01, FR-02)
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String otp,
  });

  /// Melengkapi profil awal saat pendaftaran (FR-03, FR-04)
  Future<UserProfile> completeProfile({
    required String username,
    required String displayName,
    required DateTime birthDate,
    String? avatarUrl,
  });

  /// Mengambil profil pengguna yang saat ini login
  Future<UserProfile?> getCurrentProfile();

  /// Menghapus akun dan data pengguna secara permanen (FR-05)
  Future<void> deleteAccount();

  /// Keluar dari sesi aplikasi
  Future<void> signOut();

  /// Aliran perubahan status autentikasi (true = login, false = logout)
  Stream<bool> authStateChanges();
}
