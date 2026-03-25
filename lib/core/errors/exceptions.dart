// Data katmanında fırlatılan exception türleri.
// Bu exception'lar Repository'de yakalanarak Failure'a dönüştürülür.
// Not: "App" ön eki sqflite.DatabaseException ile çakışmayı önler.

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({this.message = 'Sunucu hatası.', this.statusCode});
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'İnternet bağlantısı yok.']);
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Önbellek hatası.']);
  @override
  String toString() => 'CacheException: $message';
}

/// Uygulama DB exception'ı — sqflite.DatabaseException ile çakışmaz.
class AppDatabaseException implements Exception {
  final String message;
  final Object? cause;
  const AppDatabaseException([this.message = 'Veritabanı hatası.', this.cause]);
  @override
  String toString() => 'AppDatabaseException: $message | cause: $cause';
}

class SecurityException implements Exception {
  final String message;
  const SecurityException([this.message = 'Güvenlik ihlali tespit edildi.']);
  @override
  String toString() => 'SecurityException: $message';
}

class ConsentException implements Exception {
  const ConsentException();
  @override
  String toString() =>
      'ConsentException: Kullanıcı onayı alınmadan sistem başlatılamaz.';
}
