import 'package:equatable/equatable.dart';

/// Görev domain entity'si — To-Do ve günlük plan öğelerini kapsar.
class Task extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final TaskPriority priority;
  final TaskCategory category;
  final List<String> tags;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.reminderAt,
    this.isCompleted = false,
    this.completedAt,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.general,
    this.tags = const [],
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    TaskPriority? priority,
    TaskCategory? category,
    List<String>? tags,
  }) =>
      Task(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        createdAt: createdAt,
        dueDate: dueDate ?? this.dueDate,
        reminderAt: reminderAt ?? this.reminderAt,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
        priority: priority ?? this.priority,
        category: category ?? this.category,
        tags: tags ?? this.tags,
      );

  bool get isOverdue =>
      !isCompleted &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  @override
  List<Object?> get props =>
      [id, userId, title, isCompleted, completedAt, priority, dueDate];
}

enum TaskPriority { low, medium, high, urgent }

enum TaskCategory {
  general,
  work,
  personal,
  health,
  shopping,
  family,
  education,
}

extension TaskPriorityExt on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Düşük';
      case TaskPriority.medium:
        return 'Orta';
      case TaskPriority.high:
        return 'Yüksek';
      case TaskPriority.urgent:
        return 'Acil';
    }
  }
}

extension TaskCategoryExt on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.general:
        return 'Genel';
      case TaskCategory.work:
        return 'İş';
      case TaskCategory.personal:
        return 'Kişisel';
      case TaskCategory.health:
        return 'Sağlık';
      case TaskCategory.shopping:
        return 'Alışveriş';
      case TaskCategory.family:
        return 'Aile';
      case TaskCategory.education:
        return 'Eğitim';
    }
  }
}
