import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../security/security_layer.dart';

/// HuggingFace Dedicated Endpoint ile iletisim katmani.
class ApiService {
  late final Dio _dio;
  final SecurityLayer _security;

  ApiService({required SecurityLayer security}) : _security = security {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.hfEndpointUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': ApiConstants.headerContentType,
          'Accept': ApiConstants.headerAccept,
          'Authorization': 'Bearer ${ApiConstants.hfToken}',
        },
      ),
    );
  }

  // Hallusinasyon kontrolu
  bool _hasNoTasks(String context) {
    if (context.isEmpty) return true;
    return [
      'icin gorev yok',
      'için görev yok',
      'gorev yok',
      'görev yok',
      'plan yok',
    ].any((k) => context.contains(k));
  }

  // Qwen prompt olustur
  String _buildPrompt({
    required String instruction,
    required String context,
    required List<Map<String, String>> history,
  }) {
    const system =
        'Sen Turkce konusan akilli ayna asistanisin. '
        'Asagidaki GOREV LISTESINDE yazan bilgileri kullanarak cevap ver. '
        'Gorev listesinde olmayan hicbir seyi soyleme, uydurma, tahmin etme.';

    final buffer = StringBuffer();
    buffer.write('<|im_start|>system\n$system<|im_end|>\n');

    final recent =
        history.length > 10 ? history.sublist(history.length - 10) : history;
    for (final msg in recent) {
      final role = msg['role'] == 'user' ? 'user' : 'assistant';
      buffer.write('<|im_start|>$role\n${msg['content']}<|im_end|>\n');
    }

    final userMsg = context.isNotEmpty
        ? '$instruction\n\nGOREV LISTESI:\n$context'
        : instruction;

    buffer.write('<|im_start|>user\n$userMsg<|im_end|>\n');
    buffer.write('<|im_start|>assistant\n');
    return buffer.toString();
  }

  // HF'e istek at, yanit parse et
  Future<String> _callHf(String prompt) async {
    try {
      final response = await _dio.post(
        '/',
        data: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 150,
            'temperature': 0.1,
            'repetition_penalty': 1.2,
            'do_sample': true,
            'return_full_text': false,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String generated = '';
        if (data is List && data.isNotEmpty) {
          generated = data[0]['generated_text'] ?? '';
        } else if (data is Map) {
          generated = data['generated_text'] ?? '';
        }
        generated = generated.trim();
        if (generated.contains('<|im_end|>')) {
          generated = generated.split('<|im_end|>')[0].trim();
        }
        return generated.isEmpty
            ? 'Bir sorun olustu, lutfen tekrar deneyin.'
            : generated;
      }
      throw ServerException(
        message: 'HF API hatasi: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'Baglanti hatasi');
    }
  }

  // ── AI Ozelinde: Ses Komutu ───────────────────────────────────────────────

  Future<Map<String, dynamic>> sendVoiceCommand(
    String transcript, {
    String context = '',
    List<Map<String, String>> history = const [],
  }) async {
    await _security.requireConsent();

    if (_hasNoTasks(context)) {
      return {'response': 'Belirtilen gun icin herhangi bir planin bulunmuyor.'};
    }

    final prompt = _buildPrompt(
      instruction: transcript,
      context: context,
      history: history,
    );

    final reply = await _callHf(prompt);
    return {'response': reply};
  }

  Future<Map<String, dynamic>> inferAi(
    String prompt, {
    String context = '',
  }) async {
    await _security.requireConsent();
    final fullPrompt = _buildPrompt(
      instruction: prompt,
      context: context,
      history: [],
    );
    final reply = await _callHf(fullPrompt);
    return {'generated_text': reply};
  }

  // ── Genel HTTP metodlari (diger kodlar icin korundu) ─────────────────────

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    await _security.requireConsent();
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    await _security.requireConsent();
    try {
      final response = await _dio.post(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    await _security.requireConsent();
    try {
      final response = await _dio.put(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> delete(String endpoint) async {
    await _security.requireConsent();
    try {
      await _dio.delete(endpoint);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      return (response.data as Map<String, dynamic>?) ?? {};
    }
    throw ServerException(
      message: response.statusMessage ?? 'Sunucu hatasi',
      statusCode: statusCode,
    );
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException('Baglanti zaman asimina ugradi.');
      case DioExceptionType.connectionError:
        return const NetworkException('Sunucuya ulasilamiyor.');
      case DioExceptionType.badResponse:
        return ServerException(
          message: e.response?.statusMessage ?? 'Sunucu hatasi',
          statusCode: e.response?.statusCode,
        );
      default:
        return NetworkException(e.message ?? 'Bilinmeyen ag hatasi.');
    }
  }
}
