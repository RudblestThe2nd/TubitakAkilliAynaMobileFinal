import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/task.dart';

/// Swipe-to-delete ve tamamlama checkbox'ı içeren görev kartı.
class TaskCardWidget extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onSpeak;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: task.isCompleted
                ? const LinearGradient(
                    colors: [Color(0xFF1A1A24), Color(0xFF1A1A24)],
                  )
                : AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.isCompleted
                  ? AppTheme.dividerColor
                  : _priorityColor.withValues(alpha: 0.3),
              width: task.isCompleted ? 1 : 1.5,
            ),
            boxShadow: task.isCompleted ? [] : AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tamamlama Toggle
                _CheckCircle(
                  isCompleted: task.isCompleted,
                  color: _priorityColor,
                  onTap: onToggle,
                ),
                const SizedBox(width: 12),
                // İçerik
                Expanded(child: _TaskContent(task: task)),
                const SizedBox(width: 4),
                // Sesli okuma + Öncelik rozeti
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PriorityBadge(priority: task.priority),
                    if (onSpeak != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onSpeak,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.volume_up_outlined,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppTheme.error;
      case TaskPriority.high:
        return AppTheme.warning;
      case TaskPriority.medium:
        return AppTheme.primary;
      case TaskPriority.low:
        return AppTheme.textDisabled;
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Görevi Sil',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Bu görevi silmek istediğinize emin misiniz?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  const _CheckCircle({
    required this.isCompleted,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? color : Colors.transparent,
          border: Border.all(
            color: isCompleted ? color : color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

class _TaskContent extends StatelessWidget {
  final Task task;
  const _TaskContent({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: task.isCompleted
                ? AppTheme.textDisabled
                : AppTheme.textPrimary,
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        if (task.description != null && task.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.description!,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            // Kategori
            _ChipLabel(
              label: task.category.label,
              icon: Icons.label_outline,
              color: AppTheme.primary.withValues(alpha: 0.7),
            ),
            // Son tarih
            if (task.dueDate != null) ...[
              const SizedBox(width: 8),
              _ChipLabel(
                label: DateFormat('d MMM', 'tr_TR').format(task.dueDate!),
                icon: task.isOverdue ? Icons.warning_amber : Icons.schedule,
                color: task.isOverdue ? AppTheme.error : AppTheme.textSecondary,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ChipLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority == TaskPriority.low) return const SizedBox.shrink();

    Color color;
    switch (priority) {
      case TaskPriority.urgent:
        color = AppTheme.error;
      case TaskPriority.high:
        color = AppTheme.warning;
      default:
        color = AppTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: AppTheme.error),
    );
  }
}
