import 'dart:async';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi Mock Repository untuk pengujian unit dan pengembangan lokal terisolasi.
/// Menerapkan aturan bisnis PRD v0.3 (FR-01 s.d. FR-05) secara persis.
class MockAuthRepository implements AuthRepository {
  final _authStateController = StreamController<bool>.broadcast();
  
  String? _pendingEmail;
  String? _currentOtp;
  DateTime? _otpExpiresAt;
  int _attempts = 0;
  static const int maxAttempts = 5;

  UserProfile? _currentUserProfile;
  bool _isLoggedIn = false;
  final Set<String> _registeredUsers = {'user@raya.id', 'test@example.com'};

  /// Default mock OTP untuk mempermudah testing lokal
  static const String testOtp = '123456';

  @override
  Stream<bool> authStateChanges() => _authStateController.stream;

  @override
  Future<AuthResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();
    if (!_registeredUsers.contains(sanitizedEmail)) {
      throw Exception('Akun belum terdaftar. Silakan pilih Daftar Akun Baru.');
    }
    _isLoggedIn = true;
    _authStateController.add(true);
    return AuthResult(
      userId: _currentUserProfile?.id ?? 'mock-user-uuid-1',
      email: sanitizedEmail,
      isNewUser: _currentUserProfile == null,
      isAdult: _currentUserProfile?.isAdult ?? false,
    );
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();
    if (_registeredUsers.contains(sanitizedEmail)) {
      throw Exception('Email ini sudah terdaftar. Silakan pilih tombol Masuk.');
    }
    _registeredUsers.add(sanitizedEmail);
    _pendingEmail = sanitizedEmail;
    _currentOtp = testOtp;
    _otpExpiresAt = DateTime.now().add(const Duration(minutes: 10));
    _attempts = 0;
  }

  @override
  Future<void> requestEmailOtp(String email, {bool shouldCreateUser = true}) async {
    final sanitizedEmail = email.trim().toLowerCase();
    if (!sanitizedEmail.contains('@') || !sanitizedEmail.contains('.')) {
      throw Exception('Format alamat email tidak valid.');
    }

    if (!shouldCreateUser && !_registeredUsers.contains(sanitizedEmail)) {
      throw Exception('Akun belum terdaftar. Silakan pilih Daftar Akun Baru.');
    }

    _pendingEmail = sanitizedEmail;
    _currentOtp = testOtp;
    _otpExpiresAt = DateTime.now().add(const Duration(minutes: 10));
    _attempts = 0;
  }

  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();
    final sanitizedOtp = otp.trim();

    if (_pendingEmail != sanitizedEmail || _currentOtp == null || _otpExpiresAt == null) {
      throw Exception('Kode OTP tidak valid atau belum diminta. Silakan minta kode baru.');
    }

    if (DateTime.now().isAfter(_otpExpiresAt!)) {
      throw Exception('Kode OTP telah kedaluwarsa. Silakan minta kode baru.');
    }

    if (_attempts >= maxAttempts) {
      throw Exception('Batas percobaan terlampaui. Silakan minta kode baru.');
    }

    if (sanitizedOtp != _currentOtp) {
      _attempts++;
      final remaining = maxAttempts - _attempts;
      if (remaining > 0) {
        throw Exception('Kode salah. Sisa $remaining percobaan.');
      } else {
        throw Exception('Kode salah. Batas percobaan habis. Silakan minta kode baru.');
      }
    }

    // OTP Benar
    _isLoggedIn = true;
    _authStateController.add(true);

    final isNewUser = _currentUserProfile == null;
    final isAdult = _currentUserProfile?.isAdult ?? false;

    return AuthResult(
      userId: _currentUserProfile?.id ?? 'mock-user-uuid-1',
      email: sanitizedEmail,
      isNewUser: isNewUser,
      isAdult: isAdult,
    );
  }

  @override
  Future<UserProfile> completeProfile({
    required String username,
    required String displayName,
    required DateTime birthDate,
    String? avatarUrl,
  }) async {
    final sanitizedUsername = username.trim().toLowerCase();
    if (sanitizedUsername.length < 3 || sanitizedUsername.length > 30) {
      throw Exception('Username harus terdiri dari 3 hingga 30 karakter.');
    }

    final isAdult = UserProfile.calculateLocalIsAdult(birthDate);

    final profile = UserProfile(
      id: 'mock-user-uuid-1',
      email: _pendingEmail ?? 'pengguna@raya.id',
      username: sanitizedUsername,
      displayName: displayName.trim(),
      avatarUrl: avatarUrl,
      birthDate: birthDate,
      isAdult: isAdult,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentUserProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentUserProfile == null) {
      throw Exception('Sesi pengguna tidak aktif.');
    }
    _currentUserProfile = _currentUserProfile!.copyWith(
      displayName: displayName ?? _currentUserProfile!.displayName,
      username: username ?? _currentUserProfile!.username,
      bio: bio ?? _currentUserProfile!.bio,
      avatarUrl: avatarUrl ?? _currentUserProfile!.avatarUrl,
      updatedAt: DateTime.now(),
    );
    return _currentUserProfile!;
  }

  @override
  Future<UserProfile?> getCurrentProfile() async {
    return _currentUserProfile;
  }

  @override
  Future<void> deleteAccount() async {
    _currentUserProfile = null;
    _isLoggedIn = false;
    _pendingEmail = null;
    _currentOtp = null;
    _authStateController.add(false);
  }

  @override
  Future<void> signOut() async {
    _isLoggedIn = false;
    _authStateController.add(false);
  }
}
