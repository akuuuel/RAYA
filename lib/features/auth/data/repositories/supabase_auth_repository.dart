import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi AuthRepository yang menghubungkan aplikasi klien ke Supabase.
/// Memanggil Edge Function untuk OTP dan tabel `profiles` via RLS.
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

  @override
  Future<void> requestEmailOtp(String email) async {
    final sanitizedEmail = email.trim().toLowerCase();

    final response = await _client.functions.invoke(
      'request-otp',
      body: {'email': sanitizedEmail},
    );

    if (response.status != 200) {
      final data = response.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'] as String
          : 'Gagal mengirim kode OTP. Silakan coba beberapa saat lagi.';
      throw Exception(message);
    }
  }

  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();
    final sanitizedOtp = otp.trim();

    final response = await _client.functions.invoke(
      'verify-otp',
      body: {
        'email': sanitizedEmail,
        'otp': sanitizedOtp,
      },
    );

    final data = response.data;
    if (response.status != 200 || (data is Map && data['success'] != true)) {
      final message = (data is Map && data['message'] != null)
          ? data['message'] as String
          : 'Verifikasi OTP gagal. Silakan coba lagi.';
      throw Exception(message);
    }

    final userId = data['userId'] as String;
    final isNewUser = data['isNewUser'] as bool? ?? false;
    final isAdult = data['isAdult'] as bool? ?? false;

    // Jika hashedToken tersedia, set session auth
    final hashedToken = data['hashedToken'] as String?;
    if (hashedToken != null) {
      await _client.auth.verifyOTP(
        type: OtpType.magiclink,
        tokenHash: hashedToken,
      );
    }

    return AuthResult(
      userId: userId,
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

    // Simpan ke tabel profiles (is_adult akan diverifikasi oleh trigger server)
    final profileData = {
      'id': user.id,
      'email': user.email ?? '',
      'username': sanitizedUsername,
      'display_name': displayName.trim(),
      'avatar_url': avatarUrl,
      'birth_date': dateStr,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('profiles')
        .upsert(profileData)
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
