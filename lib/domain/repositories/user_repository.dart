import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/errors/failures.dart';

/// Kullanıcı repository sözleşmesi (Domain katmanı — soyut).
abstract class IUserRepository {
  Future<Either<Failure, List<User>>> getAllUsers();
  Future<Either<Failure, User>> getUserById(String userId);
  Future<Either<Failure, User>> createUser(User user);
  Future<Either<Failure, User>> updateUser(User user);
  Future<Either<Failure, bool>> deleteUser(String userId);
  Future<Either<Failure, User?>> getActiveUser();
  Future<Either<Failure, bool>> setActiveUser(String userId);
  Future<Either<Failure, bool>> verifyPin(String userId, String pin);
}
