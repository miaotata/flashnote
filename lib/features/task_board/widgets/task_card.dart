import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/database.dart';
import '../../../shared/widgets/priority_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskData task;
  final NoteData? note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onToggleFocus;
  final VoidCallback? onDelete;
  final bool hasReminder;
  final List<TagData>? tags;

  const TaskCard({
    super.key,
    required this.task,
    this.note,
    this.onTap,
    this.onToggleComplete,
    this.onToggleFocus,
    this.onDelete,
    this.hasReminder = false,
    this.tags,
  });

  Color get _borderColor {
    switch (task.priority) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
        return AppColors.priorityLow;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  Future<bool> _confirmDismiss(BuildContext context) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除任务'),
        content: Text(note?.content ?? '任务 #${task.id}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    if (onDelete == null) {
      return _buildCard(context);
    }

    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDismiss(context),
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondarySystemBackground, context),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: _borderColor, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggleComplete,
              child: Icon(
                task.completed
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 22,
                color: task.completed
                    ? AppColors.priorityLow
                    : CupertinoColors.systemGrey3,
              ),
            ),
            if (note != null && note!.imagePath != null && note!.imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(File(note!.imagePath!),
                      width: 36, height: 36, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note?.content ?? '任务 #${task.id}',
                    style: TextStyle(
                      fontSize: 13,
                      decoration:
                          task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed
                          ? CupertinoColors.tertiaryLabel
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: PriorityBadge(priority: task.priority),
                      ),
                      if (tags != null && tags!.isNotEmpty)
                        Flexible(
                          child: Row(
                            children: [
                              const SizedBox(width: 6),
                              ...tags!.take(3).map((t) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Container(
                                      width: 7, height: 7,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(
                                            t.color.replaceFirst('#', '0xFF'))),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (hasReminder)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(CupertinoIcons.bell_fill,
                    size: 14, color: CupertinoColors.systemBlue),
              ),
            GestureDetector(
              onTap: onToggleFocus,
              child: Icon(
                task.isDailyFocus
                    ? CupertinoIcons.star_fill
                    : CupertinoIcons.star,
                size: 16,
                color: task.isDailyFocus
                    ? AppColors.dailyFocusBadge
                    : CupertinoColors.systemGrey3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
