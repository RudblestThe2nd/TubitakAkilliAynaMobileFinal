import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/task.dart';
import '../../../domain/usecases/task_usecases.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class LoadTasksEvent extends TaskEvent {
  final String userId;
  const LoadTasksEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadTodayTasksEvent extends TaskEvent {
  final String userId;
  const LoadTodayTasksEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AddTaskEvent extends TaskEvent {
  final Task task;
  const AddTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class EditTaskEvent extends TaskEvent {
  final Task task;
  const EditTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class RemoveTaskEvent extends TaskEvent {
  final String taskId;
  const RemoveTaskEvent(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class ToggleTaskEvent extends TaskEvent {
  final String taskId;
  const ToggleTaskEvent(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class SearchTasksEvent extends TaskEvent {
  final String userId;
  final String query;
  const SearchTasksEvent({required this.userId, required this.query});
  @override
  List<Object?> get props => [userId, query];
}

class FilterTasksEvent extends TaskEvent {
  final TaskCategory? category;
  final TaskPriority? priority;
  final bool showCompleted;
  const FilterTasksEvent({
    this.category,
    this.priority,
    this.showCompleted = true,
  });
  @override
  List<Object?> get props => [category, priority, showCompleted];
}

// ── States ─────────────────────────────────────────────────────────────────

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final List<Task> filteredTasks;
  final TaskCategory? activeCategory;
  final TaskPriority? activePriority;
  final bool showCompleted;

  // ignore: prefer_const_constructors_in_immutables
  TaskLoaded({
    required this.tasks,
    List<Task>? filteredTasks,
    this.activeCategory,
    this.activePriority,
    this.showCompleted = true,
  }) : filteredTasks = filteredTasks ?? tasks;

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get pendingCount => tasks.where((t) => !t.isCompleted).length;
  double get completionRate =>
      tasks.isEmpty ? 0 : completedCount / tasks.length;

  @override
  List<Object?> get props =>
      [tasks, filteredTasks, activeCategory, activePriority, showCompleted];
}

class TaskOperationSuccess extends TaskState {
  final String message;
  final List<Task> tasks;
  const TaskOperationSuccess({required this.message, required this.tasks});
  @override
  List<Object?> get props => [message, tasks];
}

class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ───────────────────────────────────────────────────────────────────

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksByUser _getTasksByUser;
  final GetTodayTasks _getTodayTasks;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;
  final ToggleTaskCompletion _toggleTask;
  final SearchTasks _searchTasks;

  List<Task> _currentTasks = <Task>[];

  TaskBloc({
    required GetTasksByUser getTasksByUser,
    required GetTodayTasks getTodayTasks,
    required CreateTaskUseCase createTask,
    required UpdateTaskUseCase updateTask,
    required DeleteTaskUseCase deleteTask,
    required ToggleTaskCompletion toggleTask,
    required SearchTasks searchTasks,
  })  : _getTasksByUser = getTasksByUser,
        _getTodayTasks = getTodayTasks,
        _createTask = createTask,
        _updateTask = updateTask,
        _deleteTask = deleteTask,
        _toggleTask = toggleTask,
        _searchTasks = searchTasks,
        super(const TaskInitial()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<LoadTodayTasksEvent>(_onLoadTodayTasks);
    on<AddTaskEvent>(_onAddTask);
    on<EditTaskEvent>(_onEditTask);
    on<RemoveTaskEvent>(_onRemoveTask);
    on<ToggleTaskEvent>(_onToggleTask);
    on<SearchTasksEvent>(_onSearchTasks);
    on<FilterTasksEvent>(_onFilterTasks);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(const TaskLoading());
    final result = await _getTasksByUser(event.userId);
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (tasks) {
        _currentTasks = List<Task>.from(tasks);
        emit(TaskLoaded(tasks: _currentTasks));
      },
    );
  }

  Future<void> _onLoadTodayTasks(
    LoadTodayTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(const TaskLoading());
    final result = await _getTodayTasks(event.userId);
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (tasks) {
        _currentTasks = List<Task>.from(tasks);
        emit(TaskLoaded(tasks: _currentTasks));
      },
    );
  }

  Future<void> _onAddTask(
    AddTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _createTask(CreateTaskParams(task: event.task));
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (task) {
        _currentTasks = <Task>[task, ..._currentTasks];
        emit(TaskOperationSuccess(message: 'Görev eklendi.', tasks: _currentTasks));
        emit(TaskLoaded(tasks: _currentTasks));
      },
    );
  }

  Future<void> _onEditTask(
    EditTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _updateTask(event.task);
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (updated) {
        _currentTasks = _currentTasks
            .map<Task>((t) => t.id == updated.id ? updated : t)
            .toList();
        emit(TaskLoaded(tasks: _currentTasks));
      },
    );
  }

  Future<void> _onRemoveTask(
    RemoveTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _deleteTask(event.taskId);
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (_) {
        _currentTasks =
            _currentTasks.where((t) => t.id != event.taskId).toList();
        emit(TaskOperationSuccess(message: 'Görev silindi.', tasks: _currentTasks));
        emit(TaskLoaded(tasks: _currentTasks));
      },
    );
  }

  Future<void> _onToggleTask(
    ToggleTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _toggleTask(event.taskId);
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (isCompleted) {
        _currentTasks = _currentTasks.map<Task>((t) {
          if (t.id != event.taskId) return t;
          return t.copyWith(
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
            clearCompletedAt: !isCompleted,
          );
        }).toList();
        emit(TaskLoaded(tasks: _currentTasks));
      },
    );
  }

  Future<void> _onSearchTasks(
    SearchTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(TaskLoaded(tasks: _currentTasks));
      return;
    }
    final result = await _searchTasks(event.userId, event.query);
    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (tasks) => emit(TaskLoaded(tasks: tasks, filteredTasks: tasks)),
    );
  }

  void _onFilterTasks(FilterTasksEvent event, Emitter<TaskState> emit) {
    var filtered = List<Task>.from(_currentTasks);
    if (event.category != null) {
      filtered = filtered.where((t) => t.category == event.category).toList();
    }
    if (event.priority != null) {
      filtered = filtered.where((t) => t.priority == event.priority).toList();
    }
    if (!event.showCompleted) {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    }
    emit(TaskLoaded(
      tasks: _currentTasks,
      filteredTasks: filtered,
      activeCategory: event.category,
      activePriority: event.priority,
      showCompleted: event.showCompleted,
    ));
  }
}
