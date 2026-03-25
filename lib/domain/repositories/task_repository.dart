import 'package:dartz/dartz.dart' hide Task;
import '../entities/task.dart';
import '../../core/errors/failures.dart';

/// Görev repository sözleşmesi (Domain katmanı — soyut).
abstract class ITaskRepository {
  Future<Either<Failure, List<Task>>> getTasksByUser(String userId);
  Future<Either<Failure, List<Task>>> getTodayTasks(String userId);
  Future<Either<Failure, Task>> getTaskById(String taskId);
  Future<Either<Failure, Task>> createTask(Task task);
  Future<Either<Failure, Task>> updateTask(Task task);
  Future<Either<Failure, bool>> deleteTask(String taskId);
  Future<Either<Failure, bool>> toggleTaskCompletion(String taskId);
  Future<Either<Failure, List<Task>>> searchTasks(String userId, String query);
}
