import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_service.dart';
import '../../models/task_model.dart';

/// AI model ile uzak iletişim datasource'u.
/// NGINX API Gateway üzerinden TensorFlow modeline bağlanır.
abstract class IAiRemoteDataSource {
  Future<String> processVoiceCommand(String transcript, {String context = '', List<Map<String, String>> history = const []});
  Future<String> inferAiResponse(String prompt);
  Future<List<AiTaskSuggestion>> getAiTaskSuggestions(String userId);
  Future<bool> checkAiModelStatus();
}

class AiRemoteDataSource implements IAiRemoteDataSource {
  final ApiService _apiService;

  AiRemoteDataSource({required ApiService apiService})
      : _apiService = apiService;

  // ── Ses Komutu İşleme ─────────────────────────────────────────────────────

  /// Ses tanıma metni → NGINX Gateway → TensorFlow modeli → Yanıt metni
  @override
  Future<String> processVoiceCommand(String transcript, {String context = '', List<Map<String, String>> history = const []}) async {
    try {
      final response = await _apiService.sendVoiceCommand(transcript, context: context, history: history);
      final reply = response['response'] as String?;
      if (reply == null || reply.isEmpty) {
        throw const ServerException(message: 'AI boş yanıt döndürdü.');
      }
      return reply;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Ses komutu işlenemedi: $e');
    }
  }

  // ── AI Çıkarımı ───────────────────────────────────────────────────────────

  @override
  Future<String> inferAiResponse(String prompt) async {
    try {
      final response = await _apiService.inferAi(prompt);
      return (response['generated_text'] as String?) ?? '';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'AI çıkarımı başarısız: $e');
    }
  }

  // ── AI Görev Önerileri ────────────────────────────────────────────────────

  @override
  Future<List<AiTaskSuggestion>> getAiTaskSuggestions(String userId) async {
    try {
      final response = await _apiService.post(
        '/api/v1/ai/task-suggestions',
        body: {'user_id': userId},
      );
      final items = response['suggestions'] as List<dynamic>? ?? [];
      return items
          .map((e) => AiTaskSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Görev önerileri alınamadı: $e');
    }
  }

  // ── Model Durumu ──────────────────────────────────────────────────────────

  @override
  Future<bool> checkAiModelStatus() async {
    try {
      final response = await _apiService.get('/api/v1/ai/status');
      return (response['status'] as String?) == 'healthy';
    } catch (_) {
      return false;
    }
  }
}
