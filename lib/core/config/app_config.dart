/// Konfigurasi aplikasi yang dimuat dari environment variables
/// melalui `--dart-define-from-file=config.json`.
/// 
/// Dilarang keras menaruh rahasia backend (service_role, API key Resend,
/// atau Firebase Admin) di file ini atau kode klien mana pun.
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

  static bool get isLocal => environment == 'local';
}
