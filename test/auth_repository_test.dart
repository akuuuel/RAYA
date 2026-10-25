import 'package:flutter_test/flutter_test.dart';
import 'package:connect/features/auth/data/repositories/mock_auth_repository.dart';

void main() {
  group('AuthRepository Unit Test (FR-01 s.d. FR-05)', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('FR-01: Validasi format email menolak email yang tidak valid', () async {
      expect(
        () => repository.requestEmailOtp('email_tanpa_domain'),
        throwsA(isA<Exception>()),
      );
    });

    test('FR-01 & FR-02: Kirim OTP berhasil dan verifikasi dengan kode yang benar menghasilkan sesi', () async {
      await repository.requestEmailOtp('pengguna@raya.id');
      final result = await repository.verifyEmailOtp(
        email: 'pengguna@raya.id',
        otp: MockAuthRepository.testOtp,
      );

      expect(result.email, 'pengguna@raya.id');
      expect(result.isNewUser, isTrue);
      expect(repository.isLoggedIn, isTrue);
    });

    test('FR-02: Kode OTP salah mengurangi sisa percobaan dan menolak setelah batas habis', () async {
      await repository.requestEmailOtp('pengguna@raya.id');

      // Percobaan salah ke-1 sampai ke-4
      for (int i = 1; i <= 4; i++) {
        expect(
          () => repository.verifyEmailOtp(email: 'pengguna@raya.id', otp: '000000'),
          throwsA(predicate((e) => e.toString().contains('Sisa ${5 - i} percobaan'))),
        );
      }

      // Percobaan salah ke-5 (batas habis)
      expect(
        () => repository.verifyEmailOtp(email: 'pengguna@raya.id', otp: '000000'),
        throwsA(predicate((e) => e.toString().contains('Batas percobaan habis'))),
      );
    });

    test('FR-04: Pengguna berusia 18 tahun ke atas ditandai isAdult = true', () async {
      await repository.requestEmailOtp('dewasa@raya.id');
      await repository.verifyEmailOtp(email: 'dewasa@raya.id', otp: MockAuthRepository.testOtp);

      final now = DateTime.now();
      final birthDate20YearsAgo = DateTime(now.year - 20, now.month, now.day);

      final profile = await repository.completeProfile(
        username: 'dewasa_user',
        displayName: 'Pengguna Dewasa',
        birthDate: birthDate20YearsAgo,
      );

      expect(profile.isAdult, isTrue);
    });

    test('FR-04: Pengguna berusia di bawah 18 tahun ditandai isAdult = false dan pendaftaran tetap sukses', () async {
      await repository.requestEmailOtp('remaja@raya.id');
      await repository.verifyEmailOtp(email: 'remaja@raya.id', otp: MockAuthRepository.testOtp);

      final now = DateTime.now();
      final birthDate15YearsAgo = DateTime(now.year - 15, now.month, now.day);

      final profile = await repository.completeProfile(
        username: 'remaja_user',
        displayName: 'Pengguna Remaja',
        birthDate: birthDate15YearsAgo,
      );

      expect(profile.isAdult, isFalse);
    });

    test('FR-05: Hapus akun membersihkan sesi dan data profil', () async {
      await repository.requestEmailOtp('hapus@raya.id');
      await repository.verifyEmailOtp(email: 'hapus@raya.id', otp: MockAuthRepository.testOtp);
      await repository.completeProfile(
        username: 'user_hapus',
        displayName: 'User Hapus',
        birthDate: DateTime(2000, 1, 1),
      );

      expect(repository.isLoggedIn, isTrue);
      await repository.deleteAccount();

      expect(repository.isLoggedIn, isFalse);
      final profile = await repository.getCurrentProfile();
      expect(profile, isNull);
    });
  });
}
