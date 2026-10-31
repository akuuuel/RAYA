import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi AuthRepository yang menghubungkan aplikasi klien ke Supabase.
/// Menggunakan Supabase Auth bawaan (Email OTP) — tidak memerlukan Resend atau Edge Function.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<bool> authStateChanges() {
    return _client.auth.onAuthStateChange.map((data) {
      return data.session != null;
    });
  }

  /// Mengirim OTP ke email menggunakan Supabase Auth bawaan.
  @override
  Future<void> requestEmailOtp(String email) async {
    final sanitizedEmail = email.trim().toLowerCase();

    await _client.auth.signInWithOtp(
      email: sanitizedEmail,
      shouldCreateUser: true,
    );
  }

  /// Memverifikasi OTP yang dikirim oleh Supabase Auth.
  /// Menangani fallback OtpType (email, signup, magiclink) untuk pengguna baru & lama.
  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();
    final sanitizedOtp = otp.trim();

    AuthResponse response;
    try {
      response = await _client.auth.verifyOTP(
        email: sanitizedEmail,
        token: sanitizedOtp,
        type: OtpType.email,
      );
    } on AuthException {
      try {
        // Untuk pengguna baru yang belum terdaftar di auth.users, Supabase memakai token 'signup'
        response = await _client.auth.verifyOTP(
          email: sanitizedEmail,
          token: sanitizedOtp,
          type: OtpType.signup,
        );
      } on AuthException {
        try {
          response = await _client.auth.verifyOTP(
            email: sanitizedEmail,
            token: sanitizedOtp,
            type: OtpType.magiclink,
          );
        } on AuthException catch (e) {
          throw Exception(e.message);
        }
      }
    }

    final session = response.session;
    final user = response.user;

    if (session == null || user == null) {
      throw Exception('Kode OTP tidak valid atau sudah kedaluwarsa. Silakan coba lagi.');
    }

    // Cek apakah profil sudah lengkap (username & birth_date wajib sudah diisi)
    final existingProfile = await _client
        .from('profiles')
        .select('id, username, birth_date, is_adult')
        .eq('id', user.id)
        .maybeSingle();

    final isNewUser = existingProfile == null ||
        existingProfile['username'] == null ||
        existingProfile['birth_date'] == null;
    final isAdult = (existingProfile?['is_adult'] as bool?) ?? false;

    return AuthResult(
      userId: user.id,
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
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi tidak ditemukan. Silakan masuk kembali.');
    }

    final sanitizedUsername = username.trim().toLowerCase();
    final dateStr = birthDate.toIso8601String().split('T').first;

    final updateData = {
      'username': sanitizedUsername,
      'display_name': displayName.trim(),
      'avatar_url': avatarUrl,
      'birth_date': dateStr,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Update row profil yang sudah dibuat oleh database trigger
    final updated = await _client
        .from('profiles')
        .update(updateData)
        .eq('id', user.id)
        .select()
        .maybeSingle();

    if (updated != null) {
      return UserProfile.fromJson(updated);
    }

    // Fallback upsert jika baris profil belum pernah dibuat
    final fullData = {
      'id': user.id,
      'email': user.email ?? '',
      ...updateData,
    };

    final response = await _client
        .from('profiles')
        .upsert(fullData)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  @override
  Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status != 200) {
      final data = response.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'] as String
          : 'Gagal menghapus akun. Silakan coba lagi.';
      throw Exception(message);
    }

    await _client.auth.signOut();
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
