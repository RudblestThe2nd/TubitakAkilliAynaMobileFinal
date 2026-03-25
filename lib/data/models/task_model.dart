import 'dart:convert';
import '../../domain/entities/task.dart';

/// Görev data modeli: JSON ↔ SQLite satırı ↔ Entity dönüşümleri.
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.createdAt,
    super.dueDate,
    super.reminderAt,
    super.isCompleted,
    super.completedAt,
    super.priority,
    super.category,
    super.tags,
  });

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      priority: _parsePriority(map['priority'] as String? ?? 'medium'),
      category: _parseCategory(map['category'] as String? ?? 'general'),
      tags: _parseTags(map['tags'] as String? ?? '[]'),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      reminderAt: map['reminder_at'] != null
          ? DateTime.parse(map['reminder_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
        'priority': priority.name,
        'category': category.name,
        'tags': json.encode(tags),
        'due_date': dueDate?.toIso8601String(),
        'reminder_at': reminderAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  // ── JSON (API) ────────────────────────────────────────────────────────────

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      TaskModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  /// Domain entity'yi model'e dönüştür.
  factory TaskModel.fromEntity(Task task) => TaskModel(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        createdAt: task.createdAt,
        dueDate: task.dueDate,
        reminderAt: task.reminderAt,
        isCompleted: task.isCompleted,
        completedAt: task.completedAt,
        priority: task.priority,
        category: task.category,
        tags: task.tags,
      );

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  static TaskPriority _parsePriority(String value) => TaskPriority.values
      .firstWhere((e) => e.name == value, orElse: () => TaskPriority.medium);

  static TaskCategory _parseCategory(String value) => TaskCategory.values
      .firstWhere((e) => e.name == value, orElse: () => TaskCategory.general);

  static List<String> _parseTags(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }
}

/// API yanıtından gelen AI görev önerisi modeli.
class AiTaskSuggestion {
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskCategory category;

  const AiTaskSuggestion({
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.general,
  });

  factory AiTaskSuggestion.fromJson(Map<String, dynamic> json) =>
      AiTaskSuggestion(
        title: json['title'] as String,
        description: json['description'] as String?,
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == (json['priority'] as String? ?? 'medium'),
          orElse: () => TaskPriority.medium,
        ),
        category: TaskCategory.values.firstWhere(
          (e) => e.name == (json['category'] as String? ?? 'general'),
          orElse: () => TaskCategory.general,
        ),
      );
}
