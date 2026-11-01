/// Konfigurasi aplikasi yang dimuat dari environment variables
/// melalui `--dart-define-from-file=config.json` atau `--dart-define=KEY=VALUE`.
/// 
/// Dilarang keras menaruh rahasia backend (service_role, API key Resend,
/// atau kredensial admin) di file ini atau kode klien mana pun.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iphwxqrphembssezpwwb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwaHd4cXJwaGVtYnNzZXpwd3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1OTk0NDMsImV4cCI6MjEwODE3NTQ0M30.EJDA9rq9L7yLFl7nS3YSJ2eKY90e46rOE2UFt8OX16Y',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  /// Menentukan apakah aplikasi berjalan dalam mode mock
  /// Default false agar selalu terhubung ke server Supabase Production.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );

  static bool get isLocal => environment == 'local';
}
