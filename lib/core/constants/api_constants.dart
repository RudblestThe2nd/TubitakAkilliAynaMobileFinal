/// HuggingFace Dedicated Endpoint sabitleri.
class ApiConstants {
  ApiConstants._();

  // ── HuggingFace Dedicated Endpoint ───────────────────────────────────────
  static const String hfEndpointUrl =
      'YOUR_HF_ENDPOINT_URL';
  static const String hfToken = '''';

  // ── Base URL (api_service.dart uyumlulugu) ────────────────────────────────
  static String get baseUrl => hfEndpointUrl;

  // ── Endpoint'ler (HF icin hepsi root) ────────────────────────────────────
  static const String aiInferenceEndpoint = '/';
  static const String aiStatusEndpoint = '/';
  static const String voiceCommandEndpoint = '/';
  static const String userSyncEndpoint = '/';

  // ── Timeout Süreleri ──────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration sendTimeout = Duration(seconds: 60);

  // ── HTTP Headers ──────────────────────────────────────────────────────────
  static const String headerContentType = 'application/json';
  static const String headerAccept = 'application/json';
  static const String headerAuthorization = 'Authorization';
  static const String headerDeviceId = 'X-Device-ID';
  static const String headerApiVersion = 'X-API-Version';
  static const String apiVersion = 'v1';
}
