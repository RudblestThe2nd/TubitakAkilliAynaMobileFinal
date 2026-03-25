/// Uygulama genelinde kullanılan sabit değerler.
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Mirror';
  static const String appVersion = '1.0.0';

  // ── SQLite ────────────────────────────────────────────────────────────────
  static const String dbName = 'smart_mirror.db';
  static const int dbVersion = 2;

  // ── Tablolar ──────────────────────────────────────────────────────────────
  static const String tableUsers = 'users';
  static const String tableTasks = 'tasks';
  static const String tableReminders = 'reminders';

  // ── SharedPreferences Anahtarları ─────────────────────────────────────────
  static const String prefActiveUserId = 'active_user_id';
  static const String prefThemeMode = 'theme_mode';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefUserConsent = 'user_consent_granted';

  // ── Animasyon Süreleri (ms) ───────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 700);

  // ── Ses Tanıma ────────────────────────────────────────────────────────────
  static const Duration voiceListenTimeout = Duration(seconds: 5);
  static const Duration voicePauseThreshold = Duration(seconds: 2);
  static const double voiceConfidenceThreshold = 0.75;

  // ── Güvenlik ─────────────────────────────────────────────────────────────
  static const String secureKeyUserToken = 'user_auth_token';
  static const String secureKeyDeviceId = 'device_id';
  static const int maxLoginAttempts = 5;
  static const Duration sessionTimeout = Duration(hours: 8);
}
