import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Güvenlik katmanı:
///  - Kullanıcı onayı (consent) kontrolü
///  - Oturum token yönetimi (FlutterSecureStorage)
///  - Cihaz kimliği üretimi
///  - TLS sertifikası parmak izi doğrulama hook'u
abstract class ISecurityLayer {
  Future<bool> isConsentGranted();
  Future<void> grantConsent();
  Future<void> revokeConsent();
  Future<String?> getAuthToken();
  Future<void> saveAuthToken(String token);
  Future<void> clearSession();
  Future<String> getDeviceId();
  bool isSessionExpired(DateTime lastActivity);
}

class SecurityLayer implements ISecurityLayer {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  SecurityLayer({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs;

  // ── Kullanıcı Onayı ───────────────────────────────────────────────────────

  @override
  Future<bool> isConsentGranted() async {
    return _prefs.getBool(AppConstants.prefUserConsent) ?? false;
  }

  /// Sistem, onay verilmeden hiçbir veri işlemi başlatamaz.
  Future<void> requireConsent() async {
    final granted = await isConsentGranted();
    if (!granted) throw const ConsentException();
  }

  @override
  Future<void> grantConsent() async {
    await _prefs.setBool(AppConstants.prefUserConsent, true);
  }

  @override
  Future<void> revokeConsent() async {
    await _prefs.setBool(AppConstants.prefUserConsent, false);
    await clearSession();
  }

  // ── Token Yönetimi ────────────────────────────────────────────────────────

  @override
  Future<String?> getAuthToken() async {
    return _secureStorage.read(key: AppConstants.secureKeyUserToken);
  }

  @override
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.secureKeyUserToken,
      value: token,
    );
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(key: AppConstants.secureKeyUserToken);
  }

  // ── Cihaz Kimliği ─────────────────────────────────────────────────────────

  @override
  Future<String> getDeviceId() async {
    final existing =
        await _secureStorage.read(key: AppConstants.secureKeyDeviceId);
    if (existing != null) return existing;

    final newId = const Uuid().v4();
    await _secureStorage.write(
      key: AppConstants.secureKeyDeviceId,
      value: newId,
    );
    return newId;
  }

  // ── Oturum Süresi ─────────────────────────────────────────────────────────

  @override
  bool isSessionExpired(DateTime lastActivity) {
    return DateTime.now().difference(lastActivity) >
        AppConstants.sessionTimeout;
  }

  // ── Yardımcı: TLS Parmak İzi Doğrulama ───────────────────────────────────
  /// Dio interceptor içinde çağrılacak hook.
  /// Gerçek uygulamada sunucu sertifika hash'i buraya eklenir.
  static bool verifyCertificateFingerprint(
    List<int> derEncodedCert, {
    required String expectedSha256,
  }) {
    // Örnek implementasyon: gerçek projede dart:io'nun X509Certificate ile doğrulanır
    final encoded = base64Encode(derEncodedCert);
    return encoded == expectedSha256;
  }

  // ── Yardımcı: Güvenli Rastgele Değer ─────────────────────────────────────
  static String generateSecureRandom({int length = 32}) {
    final rng = Random.secure();
    final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).substring(0, length);
  }
}
