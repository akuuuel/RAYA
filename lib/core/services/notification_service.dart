import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Layanan Notifikasi Lokal & Suara Bawaan Sistem Android (FR-15 & WhatsApp-like notification).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'raya_notifications_v3';
  static const String _channelName = 'Pesan & Notifikasi RAYA';
  static const String _channelDesc =
      'Notifikasi pesan obrolan terenkripsi dan permintaan pertemanan';

  String? activeConversationId;
  RealtimeChannel? _realtimeMessagesSubscription;
  RealtimeChannel? _realtimeRequestsSubscription;

  /// Inisialisasi plugin notifikasi dan pembuatan notification channel Android
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Logika ketika notifikasi diklik pengguna
      },
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      // Daftarkan channel prioritas tinggi dengan suara bawaan HP dan getar
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await androidImplementation.createNotificationChannel(androidChannel);
    }
  }

  /// Minta izin runtime notifikasi Android 13+ (API 33+) secara eksplisit saat UI aktif
  Future<bool> requestPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Menampilkan notifikasi banner dengan suara default perangkat dan getar
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Mulai memantau pesan dan permintaan masuk secara real-time via Supabase
  void startListening(String currentUserId) {
    stopListening();

    final client = Supabase.instance.client;

    // 1. Pantau Pesan Chat Masuk (INSERT ke tabel messages)
    _realtimeMessagesSubscription = client
        .channel('public:messages:$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: currentUserId,
          ),
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final senderId = newRecord['sender_id'] as String?;
            final messageType = newRecord['message_type'] as String? ?? 'text';

            String senderName = 'Teman';
            if (senderId != null) {
              try {
                final profile = await client
                    .from('profiles')
                    .select('display_name, username')
                    .eq('id', senderId)
                    .maybeSingle();
                if (profile != null) {
                  senderName = (profile['display_name'] as String?) ??
                      (profile['username'] as String?) ??
                      'Teman';
                }
              } catch (_) {}
            }

            String bodyText = 'Mengirim pesan terenkripsi';
            if (messageType == 'image') {
              bodyText = '📷 Mengirim foto / dokumen';
            } else if (messageType == 'voice') {
              bodyText = '🎙️ Mengirim pesan suara';
            }

            showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: senderName,
              body: bodyText,
              payload: 'chat:$senderId',
            );
          },
        )
        .subscribe();

    // 2. Pantau Permintaan Pertemanan Masuk (INSERT ke tabel contact_requests)
    _realtimeRequestsSubscription = client
        .channel('public:contact_requests:$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'contact_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentUserId,
          ),
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final senderId = newRecord['sender_id'] as String?;

            String senderName = 'Seseorang';
            if (senderId != null) {
              try {
                final profile = await client
                    .from('profiles')
                    .select('display_name, username')
                    .eq('id', senderId)
                    .maybeSingle();
                if (profile != null) {
                  senderName = (profile['display_name'] as String?) ??
                      (profile['username'] as String?) ??
                      'Seseorang';
                }
              } catch (_) {}
            }

            showNotification(
              id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1,
              title: 'Permintaan Pertemanan Baru',
              body: '$senderName ingin terhubung dengan Anda di RAYA.',
              payload: 'contact_request:$senderId',
            );
          },
        )
        .subscribe();
  }

  /// Hentikan listener ketika pengguna keluar (logout)
  void stopListening() {
    if (_realtimeMessagesSubscription != null) {
      Supabase.instance.client.removeChannel(_realtimeMessagesSubscription!);
      _realtimeMessagesSubscription = null;
    }
    if (_realtimeRequestsSubscription != null) {
      Supabase.instance.client.removeChannel(_realtimeRequestsSubscription!);
      _realtimeRequestsSubscription = null;
    }
  }
}

