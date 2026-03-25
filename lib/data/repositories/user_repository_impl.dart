import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/user_model.dart';

/// Kullanıcı repository implementasyonu.
class UserRepositoryImpl implements IUserRepository {
  final DatabaseHelper _db;
  final SharedPreferences _prefs;

  UserRepositoryImpl({
    required DatabaseHelper db,
    required SharedPreferences prefs,
  })  : _db = db,
        _prefs = prefs;

  @override
  Future<Either<Failure, List<User>>> getAllUsers() async {
    try {
      final rows = await _db.query(
        AppConstants.tableUsers,
        orderBy: 'created_at ASC',
      );
      return Right(rows.map(UserModel.fromMap).toList());
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final rows = await _db.query(
        AppConstants.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const Left(DatabaseFailure('Kullanıcı bulunamadı.'));
      }
      return Right(UserModel.fromMap(rows.first));
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> createUser(User user) async {
    try {
      final hashedPin = _hashPin(user.pin);
      final model = UserModel.fromEntity(user.copyWith(pin: hashedPin));
      await _db.insert(AppConstants.tableUsers, model.toMap());
      return Right(model);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    try {
      final model = UserModel.fromEntity(user);
      await _db.update(
        AppConstants.tableUsers,
        model.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return Right(user);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUser(String userId) async {
    try {
      final count = await _db.delete(
        AppConstants.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (userId == _prefs.getString(AppConstants.prefActiveUserId)) {
        await _prefs.remove(AppConstants.prefActiveUserId);
      }
      return Right(count > 0);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User?>> getActiveUser() async {
    final id = _prefs.getString(AppConstants.prefActiveUserId);
    if (id == null || id.isEmpty) return const Right(null);
    return getUserById(id);
  }

  @override
  Future<Either<Failure, bool>> setActiveUser(String userId) async {
    try {
      await _prefs.setString(AppConstants.prefActiveUserId, userId);
      await _db.update(
        AppConstants.tableUsers,
        {'last_login_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return const Right(true);
    } catch (e) {
      return const Left(CacheFailure('Aktif kullanıcı kaydedilemedi.'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String userId, String pin) async {
    try {
      final rows = await _db.query(
        AppConstants.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isEmpty) return const Left(DatabaseFailure('Kullanıcı yok.'));

      final storedHash = rows.first['pin'] as String;
      final isValid = storedHash == _hashPin(pin);
      return Right(isValid);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
