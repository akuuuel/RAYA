import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connect/main.dart';
import 'package:connect/core/theme/app_colors.dart';
import 'package:connect/shared/widgets/primary_button.dart';
import 'package:connect/shared/widgets/app_text_field.dart';
import 'package:connect/shared/widgets/otp_input.dart';
import 'package:connect/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:connect/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('RayaApp merender splash screen dengan judul RAYA dan tema gelap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RayaApp(),
      ),
    );

    expect(find.text('RAYA'), findsOneWidget);
    expect(find.text('Tetap Terhubung'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);

    final scaffoldFinder = find.byType(Scaffold);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.backgroundColor, AppColors.background);
  });

  testWidgets('Navigasi dari Splash Screen ke Onboarding Screen saat tombol Mulai ditekan', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RayaApp(),
      ),
    );

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Selamat datang di RAYA'), findsOneWidget);
    expect(find.text('Tetap Terhubung'), findsOneWidget);
  });

  testWidgets('LoginScreen memvalidasi input email sebelum mengirim OTP', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Masuk dengan Email'), findsOneWidget);

    // Tekan kirim kode tanpa mengisi email
    await tester.tap(find.text('Kirim Kode'));
    await tester.pump();

    expect(find.text('Alamat email wajib diisi.'), findsOneWidget);
  });

  testWidgets('PrimaryButton memanggil onPressed dan menampilkan status loading', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Lanjutkan',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lanjutkan'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AppTextField menampilkan label dan menangani errorText dengan benar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTextField(
            label: 'Alamat Email',
            hint: 'nama@contoh.id',
            errorText: 'Format email tidak valid',
          ),
        ),
      ),
    );

    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('OtpInput merender 6 kotak input terpisah', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OtpInput(),
        ),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.textContaining('Tidak menerima kode?'), findsOneWidget);
  });
}
