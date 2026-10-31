/// Konfigurasi aplikasi yang dimuat dari environment variables
/// melalui `--dart-define-from-file=config.json` atau `--dart-define=KEY=VALUE`.
/// 
/// Dilarang keras menaruh rahasia backend (service_role, API key Resend,
/// atau kredensial admin) di file ini atau kode klien mana pun.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key_for_local_dev',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'local',
  );

  /// Menentukan apakah aplikasi berjalan dalam mode mock (terisolasi tanpa backend)
  /// Default true agar pengujian unit dan lokal tidak membutuhkan koneksi server.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  static bool get isLocal => environment == 'local';
}
