import 'package:dartz/dartz.dart' hide Task;

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/task_model.dart';

/// Görev repository implementasyonu.
class TaskRepositoryImpl implements ITaskRepository {
  final DatabaseHelper _db;

  TaskRepositoryImpl({required DatabaseHelper db}) : _db = db;

  @override
  Future<Either<Failure, List<Task>>> getTasksByUser(String userId) async {
    try {
      // Tamamlanmış görevler 1 günden eskiyse gizle
      final cutoff = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      final rows = await _db.rawQuery(
        '''
        SELECT * FROM ${AppConstants.tableTasks}
        WHERE user_id = ?
          AND NOT (
            is_completed = 1
            AND completed_at IS NOT NULL
            AND completed_at < ?
          )
        ORDER BY created_at DESC
        ''',
        [userId, cutoff],
      );
      return Right(rows.map(TaskModel.fromMap).toList());
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> getTodayTasks(String userId) async {
    try {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 1));

      final rows = await _db.rawQuery(
        '''
        SELECT * FROM ${AppConstants.tableTasks}
        WHERE user_id = ?
          AND (
            due_date IS NULL
            OR (due_date >= ? AND due_date < ?)
          )
        ORDER BY
          CASE priority
            WHEN 'urgent' THEN 1
            WHEN 'high'   THEN 2
            WHEN 'medium' THEN 3
            ELSE 4
          END,
          created_at DESC
        ''',
        [userId, start.toIso8601String(), end.toIso8601String()],
      );
      return Right(rows.map(TaskModel.fromMap).toList());
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Task>> getTaskById(String taskId) async {
    try {
      final rows = await _db.query(
        AppConstants.tableTasks,
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const Left(DatabaseFailure('Görev bulunamadı.'));
      }
      return Right(TaskModel.fromMap(rows.first));
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      final model = TaskModel.fromEntity(task);
      await _db.insert(AppConstants.tableTasks, model.toMap());
      return Right(task);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    try {
      final model = TaskModel.fromEntity(task);
      await _db.update(
        AppConstants.tableTasks,
        model.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      return Right(task);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTask(String taskId) async {
    try {
      final count = await _db.delete(
        AppConstants.tableTasks,
        where: 'id = ?',
        whereArgs: [taskId],
      );
      return Right(count > 0);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleTaskCompletion(String taskId) async {
    try {
      final rows = await _db.query(
        AppConstants.tableTasks,
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (rows.isEmpty) return const Left(DatabaseFailure('Görev yok.'));

      final current = (rows.first['is_completed'] as int) == 1;
      final nowBeingCompleted = !current;
      await _db.update(
        AppConstants.tableTasks,
        {
          'is_completed': nowBeingCompleted ? 1 : 0,
          // Tamamlanınca zamanı kaydet; geri alınınca sıfırla
          'completed_at': nowBeingCompleted
              ? DateTime.now().toIso8601String()
              : null,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
      return Right(nowBeingCompleted);
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> searchTasks(
    String userId,
    String query,
  ) async {
    try {
      final rows = await _db.rawQuery(
        '''
        SELECT * FROM ${AppConstants.tableTasks}
        WHERE user_id = ?
          AND (title LIKE ? OR description LIKE ?)
        ORDER BY created_at DESC
        ''',
        [userId, '%$query%', '%$query%'],
      );
      return Right(rows.map(TaskModel.fromMap).toList());
    } on AppDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
