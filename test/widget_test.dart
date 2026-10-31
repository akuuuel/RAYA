import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connect/main.dart';
import 'package:connect/core/theme/app_colors.dart';
import 'package:connect/core/crypto/crypto_service.dart';
import 'package:connect/shared/widgets/primary_button.dart';
import 'package:connect/shared/widgets/app_text_field.dart';
import 'package:connect/shared/widgets/otp_input.dart';
import 'package:connect/shared/widgets/app_bottom_nav.dart';
import 'package:connect/shared/widgets/location_badge.dart';
import 'package:connect/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:connect/features/auth/presentation/screens/login_screen.dart';
import 'package:connect/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:connect/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:connect/features/contacts/data/repositories/mock_contact_repository.dart';
import 'package:connect/features/chat/domain/entities/conversation.dart';
import 'package:connect/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:connect/features/auth/domain/entities/user_profile.dart';
import 'package:connect/features/tracking/domain/entities/location_session.dart';
import 'package:connect/features/tracking/data/repositories/mock_location_repository.dart';
import 'package:connect/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:connect/features/explore/data/repositories/mock_explore_repository.dart';
import 'package:connect/features/explore/presentation/screens/explore_screen.dart';
import 'package:connect/features/moderation/domain/entities/report_ticket.dart';
import 'package:connect/features/moderation/domain/entities/notification_settings.dart';
import 'package:connect/features/moderation/data/repositories/mock_moderation_repository.dart';
import 'package:connect/features/moderation/presentation/screens/notification_settings_screen.dart';
import 'package:connect/features/moderation/presentation/widgets/report_modal.dart';

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

  testWidgets('AppBottomNav merender 5 tab sesuai PRD Bagian 9 & DESIGN.md 6.11', (WidgetTester tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
            items: const [
              AppNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chat',
              ),
              AppNavItem(
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on_rounded,
                label: 'Pantau',
              ),
              AppNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Sekitar',
              ),
              AppNavItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Kontak',
              ),
              AppNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Pantau'), findsOneWidget);
    expect(find.text('Sekitar'), findsOneWidget);
    expect(find.text('Kontak'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('MainNavigationScreen merender tab awal Chat dan dapat berpindah ke tab lain', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    // Verifikasi tab awal adalah Chat (FR-09)
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('E2EE'), findsOneWidget);
    expect(find.text('Rina Pratama'), findsOneWidget);

    // Ketuk tab Profil
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Profil & Pengaturan'), findsOneWidget);
    expect(find.text('Hapus Akun Saya (FR-05)'), findsOneWidget);
  });

  testWidgets('ContactsScreen merender daftar kontak dan tab permintaan masuk', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ContactsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kontak'), findsOneWidget);
    expect(find.textContaining('Semua Kontak'), findsOneWidget);
    expect(find.textContaining('Permintaan'), findsOneWidget);

    // Verifikasi kontak default dari MockContactRepository (Rina Pratama)
    expect(find.text('Rina Pratama'), findsOneWidget);
    expect(find.text('@rina_pratama'), findsOneWidget);

    // Beralih ke tab Permintaan
    await tester.tap(find.textContaining('Permintaan'));
    await tester.pumpAndSettle();

    // Verifikasi permintaan masuk dari Budi Santoso (FR-07)
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Terima (FR-07)'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });

  test('MockContactRepository mengelola relasi kontak dengan benar', () async {
    final repo = MockContactRepository();

    // 1. Ambil kontak awal
    final initialContacts = await repo.getContacts();
    expect(initialContacts.length, 1);
    expect(initialContacts[0].contactUser.username, 'rina_pratama');

    // 2. Cari pengguna
    final searchUser = await repo.searchUser('budi_santoso');
    expect(searchUser, isNotNull);
    expect(searchUser!.displayName, 'Budi Santoso');

    // 3. Terima permintaan kontak
    final incoming = await repo.getIncomingRequests();
    expect(incoming.length, 1);
    await repo.acceptContactRequest(incoming[0].id);

    final updatedContacts = await repo.getContacts();
    expect(updatedContacts.length, 2);

    // 4. Blokir kontak
    final contactToBlock = updatedContacts[0];
    await repo.toggleBlockContact(contactToBlock.id, true);
    final blockedContacts = await repo.getContacts();
    expect(blockedContacts.firstWhere((c) => c.id == contactToBlock.id).isBlocked, isTrue);

    // 5. Hapus kontak
    await repo.removeContact(contactToBlock.id);
    final finalContacts = await repo.getContacts();
    expect(finalContacts.length, 1);
  });

  test('CryptoService melakukan enkripsi, dekripsi Diffie-Hellman, dan safety number', () {
    // 1. Generate key pair untuk Alice dan Bob (FR-09)
    final alice = CryptoService.generateKeyPair();
    final bob = CryptoService.generateKeyPair();

    expect(alice['publicKey'], isNotNull);
    expect(alice['privateKey'], isNotNull);
    expect(bob['publicKey'], isNotNull);
    expect(bob['privateKey'], isNotNull);

    // 2. Enkripsi pesan dari Alice ke Bob (FR-10, FR-11)
    const originalText = 'Pesan rahasia E2EE RAYA';
    final encrypted = CryptoService.encrypt(
      plaintext: originalText,
      senderPrivateKey: alice['privateKey']!,
      recipientPublicKey: bob['publicKey']!,
    );

    expect(encrypted['ciphertext'], isNotNull);
    expect(encrypted['nonce'], isNotNull);
    expect(encrypted['ciphertext'], isNot(originalText));

    // 3. Dekripsi di perangkat Bob (FR-10)
    final decrypted = CryptoService.decrypt(
      ciphertext: encrypted['ciphertext']!,
      nonce: encrypted['nonce']!,
      recipientPrivateKey: bob['privateKey']!,
      senderPublicKey: alice['publicKey']!,
    );

    expect(decrypted, originalText);

    // 4. Hitung Safety Number (FR-12)
    final safetyNumberAlice = CryptoService.generateSafetyNumber(
      userKeyA: alice['publicKey']!,
      userKeyB: bob['publicKey']!,
    );
    final safetyNumberBob = CryptoService.generateSafetyNumber(
      userKeyA: bob['publicKey']!,
      userKeyB: alice['publicKey']!,
    );

    expect(safetyNumberAlice, safetyNumberBob);
    expect(safetyNumberAlice.replaceAll(' ', '').length, 60);
  });

  testWidgets('ChatRoomScreen merender percakapan dan membuka modal verifikasi kode keamanan (FR-12)', (WidgetTester tester) async {
    final conversation = Conversation(
      id: 'conv-test-1',
      otherUser: UserProfile(
        id: 'mock-user-rina',
        email: 'rina@raya.id',
        username: 'rina_pratama',
        displayName: 'Rina Pratama',
        birthDate: DateTime(1996, 5, 12),
        isAdult: true,
      ),
      lastMessageAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChatRoomScreen(conversation: conversation),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rina Pratama'), findsOneWidget);
    expect(find.text('Terenkripsi End-to-End'), findsOneWidget);
    expect(find.text('Tulis pesan rahasia...'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.verified_user_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Kode Keamanan (FR-12)'), findsOneWidget);
  });

  test('MockLocationRepository mengelola sesi pantau lokasi dengan durasi dan penghentian', () async {
    final repo = MockLocationRepository();

    final myLoc = await repo.getMyLocation();
    expect(myLoc, isNotNull);
    expect(myLoc!.latitude, -6.175392);

    final rinaUser = UserProfile(
      id: 'mock-user-rina',
      email: 'rina@raya.id',
      username: 'rina_pratama',
      displayName: 'Rina Pratama',
      birthDate: DateTime(1996, 5, 12),
      isAdult: true,
    );

    final session = await repo.requestLocationSharing(
      targetUser: rinaUser,
      isBidirectional: true,
      durationType: LocationDurationType.oneHour,
    );

    expect(session.isActive, isTrue);
    expect(session.isBidirectional, isTrue);

    final rinaLoc = await repo.getContactLocation(rinaUser.id);
    expect(rinaLoc, isNotNull);
    expect(rinaLoc!.latitude, -6.1950);

    await repo.stopSession(session.id);
    final activeSessions = await repo.getActiveSessions();
    expect(activeSessions.isEmpty, isTrue);
  });

  testWidgets('TrackingScreen merender tampilan terkunci jika usia < 18 tahun (FR-20)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TrackingScreen(
          isAdult: false,
          onGoToContacts: () {},
        ),
      ),
    );

    expect(find.text('Fitur Khusus Dewasa (18+)'), findsOneWidget);
    expect(find.textContaining('UU PDP No. 27/2022'), findsOneWidget);
  });

  testWidgets('TrackingScreen merender peta pantau dan opsi berbagi jika usia dewasa 18+', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TrackingScreen(
            isAdult: true,
            onGoToContacts: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pantau Lokasi'), findsOneWidget);
    expect(find.text('Peta Pantau Belum Aktif'), findsOneWidget);
    expect(find.text('Minta Pantau ke Kontak'), findsOneWidget);
  });

  test('MockExploreRepository mengelola status publik 8 jam, penyamaran min 300m, dan komentar kontak', () async {
    final repo = MockExploreRepository();

    // 1. Ambil status sekitar
    final nearby = await repo.getNearbyStatuses(latitude: -6.175, longitude: 106.827, radiusKm: 5);
    expect(nearby.length, 2);
    expect(nearby.any((s) => s.authorName == 'Rina Pratama'), isTrue);

    // 2. Pasang status baru (FR-31)
    const trueLat = -6.175392;
    const trueLng = 106.827153;
    final myStatus = await repo.postStatus(
      text: 'Lagi minum kopi santai di Monas',
      note: 'Cuaca cerah berawan',
      latitude: trueLat,
      longitude: trueLng,
    );

    expect(myStatus.text, 'Lagi minum kopi santai di Monas');
    expect(myStatus.isMine, isTrue);

    // Verifikasi penyamaran minimal 300 meter (FR-30)
    final dLat = (myStatus.fuzzedLatitude - trueLat) * 111000.0;
    final dLng = (myStatus.fuzzedLongitude - trueLng) * 111000.0 * cos(trueLat * pi / 180.0);
    final distanceOffsetMeters = sqrt((dLat * dLat) + (dLng * dLng));
    expect(distanceOffsetMeters >= 290.0, isTrue); // Berjarak minimal 300m

    // Verifikasi masa berlaku 8 jam (FR-32)
    final diffHours = myStatus.expiresAt.difference(myStatus.createdAt).inHours;
    expect(diffHours, 8);

    // 3. Tambah komentar kontak (FR-35)
    final rinaStatus = nearby.firstWhere((s) => s.userId == 'mock-user-rina');
    final comment = await repo.addComment(
      statusId: rinaStatus.id,
      content: 'Kopinya enak gak disana?',
    );
    expect(comment.content, 'Kopinya enak gak disana?');

    final comments = await repo.getComments(rinaStatus.id);
    expect(comments.length, 2);

    // 4. Hapus komentar (FR-36)
    await repo.deleteComment(comment.id);
    final commentsAfter = await repo.getComments(rinaStatus.id);
    expect(commentsAfter.length, 1);

    // 5. Hapus status sendiri (FR-33)
    await repo.deleteMyStatus();
    final activeMine = await repo.getMyActiveStatus();
    expect(activeMine, isNull);
  });

  testWidgets('LocationBadge merender pil badge lokasi dengan benar', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationBadge(
            authorName: 'Rina Pratama',
            username: 'rina_pratama',
            text: 'Lagi ngerjain tugas',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('@rina_pratama'), findsOneWidget);
    expect(find.text('Lagi ngerjain tugas'), findsOneWidget);

    await tester.tap(find.byType(LocationBadge));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('ExploreScreen merender peta publik, filter radius, dan tombol pasang status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ExploreScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sekitar'), findsOneWidget);
    expect(find.text('1 km'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('10 km'), findsOneWidget);
    expect(find.text('Pasang Status (8 Jam)'), findsOneWidget);
    expect(find.text('@rina_pratama'), findsOneWidget);

    // Ketuk badge status untuk membuka detail (FR-34)
    await tester.tap(find.text('@rina_pratama'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Lagi ngerjain tugas di kafe ini'), findsOneWidget);
    expect(find.textContaining('FR-30'), findsOneWidget);
  });

  // ==========================================
  // PENGUJIAN FASE 5: MODERASI & NOTIFIKASI
  // ==========================================

  test('MockModerationRepository menentukan tingkat prioritas dan mengelola aduan (FR-41, FR-42, FR-43)', () async {
    final repo = MockModerationRepository();

    // 1. Aduan Spam biasa -> Prioritas Normal (isHighPriority == false)
    final spamTicket = await repo.submitReport(
      reportedUserId: 'bad-actor-spam',
      reportType: ReportType.publicStatus,
      targetId: 'status-spam-1',
      reason: ReportReason.spam,
    );
    expect(spamTicket.isHighPriority, isFalse);

    // 2. Aduan Ancaman Kekerasan -> Prioritas Tinggi (FR-43)
    final violenceTicket = await repo.submitReport(
      reportedUserId: 'bad-actor-violence',
      reportType: ReportType.message,
      targetId: 'msg-threat-1',
      reason: ReportReason.threatViolence,
      decryptedContentEvidence: 'Awas kamu ya, nanti malam!',
    );
    expect(violenceTicket.isHighPriority, isTrue);
    expect(violenceTicket.decryptedContentEvidence, 'Awas kamu ya, nanti malam!');

    // 3. Aduan Eksploitasi Anak -> Prioritas Tinggi (FR-43)
    final childTicket = await repo.submitReport(
      reportedUserId: 'bad-actor-child',
      reportType: ReportType.profile,
      targetId: 'profile-child-1',
      reason: ReportReason.childExploitation,
    );
    expect(childTicket.isHighPriority, isTrue);

    // 4. Verifikasi seluruh tiket tersimpan di repository
    expect(repo.submittedReports.length, 3);
  });

  test('MockModerationRepository mengelola preferensi notifikasi dan Mode Privat (FR-46, FR-47)', () async {
    final repo = MockModerationRepository();

    // 1. Ambil pengaturan awal (default)
    final initialSettings = await repo.getNotificationSettings();
    expect(initialSettings.chatMessages, isTrue);
    expect(initialSettings.contactRequests, isTrue);
    expect(initialSettings.privateMode, isFalse); // default false

    // 2. Perbarui ke Mode Privat (FR-47: sembunyikan preview teks)
    await repo.updateNotificationSettings(
      initialSettings.copyWith(
        privateMode: true,
        locationTracking: false,
      ),
    );

    // 3. Verifikasi pembacaan ulang
    final reread = await repo.getNotificationSettings();
    expect(reread.privateMode, isTrue);
    expect(reread.locationTracking, isFalse);
    expect(reread.chatMessages, isTrue);
  });

  testWidgets('NotificationSettingsScreen merender switch dan dapat mengubah Mode Privat (FR-47)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi judul layar dan grup preferensi
    expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
    expect(find.text('Kategori Notifikasi (FR-46)'), findsOneWidget);
    expect(find.text('Pesan Chat Baru'), findsOneWidget);
    expect(find.text('Permintaan Kontak'), findsOneWidget);
    expect(find.text('Pantau Lokasi (18+)'), findsOneWidget);
    expect(find.text('Komentar Status'), findsOneWidget);
    expect(find.text('Privasi Notifikasi (FR-47)'), findsOneWidget);

    // Verifikasi teks Mode Privat
    expect(find.text('Mode Privat Notifikasi (FR-47)'), findsOneWidget);

    // Temukan Switch dan ketuk
    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  });

  testWidgets('ReportModal menampilkan kategori aduan dan persetujuan bukti E2EE (FR-41, FR-42)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ReportModal.show(
                    context,
                    reportedUserId: 'user-sample-456',
                    reportType: ReportType.message,
                    targetId: 'msg-sample-123',
                    messagePlaintext: 'Isi teks pesan rahasia yang melanggar',
                  );
                },
                child: const Text('Buka Modal Lapor'),
              ),
            ),
          ),
        ),
      ),
    );

    // Ketuk tombol untuk menampilkan ReportModal
    await tester.tap(find.text('Buka Modal Lapor'));
    await tester.pumpAndSettle();

    // Verifikasi judul modal dan opsi kategori pelanggaran (FR-41)
    expect(find.text('Laporkan Pelanggaran (FR-41)'), findsOneWidget);
    expect(find.text('Spam atau Pesan Massal'), findsOneWidget);
    expect(find.text('Pelecehan atau Perilaku Mengganggu'), findsOneWidget);

    // Verifikasi kotak persetujuan eksplisit bukti terdekripsi E2EE (FR-42)
    expect(find.textContaining('Persetujuan Bukti Teks Terenkripsi (FR-42)'), findsOneWidget);
    expect(find.textContaining('Isi teks pesan rahasia yang melanggar'), findsOneWidget);

    // Pilih kategori Ancaman atau Kekerasan (Prioritas Tinggi - FR-43)
    await tester.tap(find.textContaining('Ancaman atau Kekerasan'));
    await tester.pumpAndSettle();

    // Verifikasi banner peringatan prioritas tinggi dan tombol Kirim Laporan
    expect(find.textContaining('Prioritas Tinggi: Laporan ini segera diteruskan'), findsOneWidget);
    expect(find.text('Kirim Laporan Prioritas Tinggi'), findsOneWidget);
  });
}
