import 'package:equatable/equatable.dart';

/// Uygulama genelinde kullanılan hata türleri (Domain katmanına ait).
/// dartz Either<Failure, T> ile döndürülür.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Ağ bağlantısı kurulamadı.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({String message = 'Sunucu hatası.', this.statusCode})
      : super(message);

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Yerel veri okunamadı.']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Veritabanı işlemi başarısız.']);
}

class SecurityFailure extends Failure {
  const SecurityFailure([super.message = 'Güvenlik doğrulaması başarısız.']);
}

class VoiceFailure extends Failure {
  const VoiceFailure([super.message = 'Ses tanıma başlatılamadı.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Gerekli izinler verilmedi.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Beklenmeyen bir hata oluştu.']);
}
