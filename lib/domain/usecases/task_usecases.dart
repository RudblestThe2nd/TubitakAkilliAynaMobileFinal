import 'package:dartz/dartz.dart' hide Task;
import 'package:equatable/equatable.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../core/errors/failures.dart';

/// Use case'ler: Domain iş mantığının en küçük birimleri (SRP).

class GetTasksByUser {
  final ITaskRepository repository;
  GetTasksByUser(this.repository);

  Future<Either<Failure, List<Task>>> call(String userId) =>
      repository.getTasksByUser(userId);
}

class GetTodayTasks {
  final ITaskRepository repository;
  GetTodayTasks(this.repository);

  Future<Either<Failure, List<Task>>> call(String userId) =>
      repository.getTodayTasks(userId);
}

class CreateTaskUseCase {
  final ITaskRepository repository;
  CreateTaskUseCase(this.repository);

  Future<Either<Failure, Task>> call(CreateTaskParams params) =>
      repository.createTask(params.task);
}

class CreateTaskParams extends Equatable {
  final Task task;
  const CreateTaskParams({required this.task});
  @override
  List<Object?> get props => [task];
}

class UpdateTaskUseCase {
  final ITaskRepository repository;
  UpdateTaskUseCase(this.repository);

  Future<Either<Failure, Task>> call(Task task) => repository.updateTask(task);
}

class DeleteTaskUseCase {
  final ITaskRepository repository;
  DeleteTaskUseCase(this.repository);

  Future<Either<Failure, bool>> call(String taskId) =>
      repository.deleteTask(taskId);
}

class ToggleTaskCompletion {
  final ITaskRepository repository;
  ToggleTaskCompletion(this.repository);

  Future<Either<Failure, bool>> call(String taskId) =>
      repository.toggleTaskCompletion(taskId);
}

class SearchTasks {
  final ITaskRepository repository;
  SearchTasks(this.repository);

  Future<Either<Failure, List<Task>>> call(String userId, String query) =>
      repository.searchTasks(userId, query);
}
