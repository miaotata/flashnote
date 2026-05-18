import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/material.dart' as mat show Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/theme/app_colors.dart';
import '../../../data/database/database.dart';
import '../providers/task_provider.dart';
import '../../reminder/providers/reminder_provider.dart';
import '../../../main.dart';
import '../../capture/note_detail_screen.dart';
import 'task_card.dart';

class QuadrantGrid extends ConsumerWidget {
  const QuadrantGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadrantAsync = ref.watch(quadrantTasksProvider);
    final reminderIds = ref.watch(reminderTaskIdsProvider).valueOrNull ?? {};

    return quadrantAsync.when(
      data: (grouped) => _buildGrid(context, ref, grouped, reminderIds),
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, _) => const Center(
        child: Text('加载失败',
            style: TextStyle(color: CupertinoColors.systemRed)),
      ),
    );
  }

  void _showMoveConfirm(BuildContext context, WidgetRef ref, TaskData task,
      String targetLabel, Color color) {
    // Determine target urgency/importance from label
    String urgency = 'urgent';
    String importance = 'important';
    if (targetLabel == '不紧急但重要') {
      urgency = 'not_urgent'; importance = 'important';
    } else if (targetLabel == '紧急但不重要') {
      urgency = 'urgent'; importance = 'not_important';
    } else if (targetLabel == '不紧急不重要') {
      urgency = 'not_urgent'; importance = 'not_important';
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('移动任务'),
        message: Text('将任务移动到「$targetLabel」？\n任务的重要/紧急程度将同步更新'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              ref.read(taskRepoProvider).update(task.id, TasksCompanion(
                urgency: Value(urgency),
                importance: Value(importance),
                updatedAt: Value(DateTime.now()),
              ));
              ref.read(taskVersionProvider.notifier).state++;
            },
            child: Text('移动到$targetLabel'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref,
      Map<int, List<MapEntry<TaskData, NoteData?>>> grouped,
      Set<int> reminderIds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfW = (constraints.maxWidth - 8) / 2;
        final halfH = (constraints.maxHeight - 8) / 2;
        return Column(
          children: [
            Row(children: [
              _quadrant(context, ref, label: '紧急且重要', color: AppColors.quadrantUrgentImportant,
                  tasks: grouped[0] ?? [], width: halfW, height: halfH, reminderIds: reminderIds),
              const SizedBox(width: 8),
              _quadrant(context, ref, label: '不紧急但重要', color: AppColors.quadrantNotUrgentImportant,
                  tasks: grouped[1] ?? [], width: halfW, height: halfH, reminderIds: reminderIds),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _quadrant(context, ref, label: '紧急但不重要', color: AppColors.quadrantUrgentNotImportant,
                  tasks: grouped[2] ?? [], width: halfW, height: halfH, reminderIds: reminderIds),
              const SizedBox(width: 8),
              _quadrant(context, ref, label: '不紧急不重要', color: AppColors.quadrantNotUrgentNotImportant,
                  tasks: grouped[3] ?? [], width: halfW, height: halfH, reminderIds: reminderIds),
            ]),
          ],
        );
      },
    );
  }

  Widget _quadrant(BuildContext context, WidgetRef ref,
      {required String label, required Color color,
       required List<MapEntry<TaskData, NoteData?>> tasks,
       required double width, required double height,
       required Set<int> reminderIds}) {
    return DragTarget<TaskData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) =>
          _showMoveConfirm(context, ref, details.data, label, color),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return mat.Material(
          color: Colors.transparent,
          child: Container(
            width: width, height: height, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hovering ? color.withValues(alpha: 0.18)
                  : CupertinoDynamicColor.resolve(color.withValues(alpha: 0.08), context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: hovering ? color : color.withValues(alpha: 0.2),
                  width: hovering ? 2 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
              const SizedBox(height: 4),
              Expanded(
                child: tasks.isEmpty
                    ? Center(child: Text('—', style: TextStyle(fontSize: 18,
                        color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.4))))
                    : ListView(children: tasks.map((entry) {
                        final card = _TaskCardWithTags(
                          key: ValueKey('quad_${entry.key.id}'),
                          task: entry.key, note: entry.value,
                          hasReminder: reminderIds.contains(entry.key.id),
                          onToggleComplete: () => ref.read(toggleTaskCompleteProvider(entry.key.id)),
                          onToggleFocus: () => ref.read(toggleDailyFocusProvider(entry.key.id)),
                          onDelete: () => ref.read(deleteTaskProvider(entry.key.id)),
                          onTapTask: () {
                            if (entry.value != null) {
                              Navigator.of(context).push(CupertinoPageRoute(
                                  builder: (_) => NoteDetailScreen(noteId: entry.value!.id)));
                            }
                          },
                        );
                        return LongPressDraggable<TaskData>(
                          data: entry.key,
                          feedback: mat.Material(color: Colors.transparent,
                              child: Opacity(opacity: 0.8, child: card)),
                          childWhenDragging: Opacity(opacity: 0.3, child: card),
                          child: card,
                        );
                      }).toList()),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _TaskCardWithTags extends ConsumerWidget {
  final TaskData task;
  final NoteData? note;
  final bool hasReminder;
  final VoidCallback onToggleComplete;
  final VoidCallback onToggleFocus;
  final VoidCallback onDelete;
  final VoidCallback? onTapTask;

  const _TaskCardWithTags({
    super.key, required this.task, required this.note,
    required this.hasReminder, required this.onToggleComplete,
    required this.onToggleFocus, required this.onDelete, this.onTapTask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<TagData>>(
      future: ref.read(tagRepoProvider).getTagsByTask(task.id),
      builder: (context, snapshot) {
        return TaskCard(
          task: task, note: note, hasReminder: hasReminder, tags: snapshot.data,
          onToggleComplete: onToggleComplete, onToggleFocus: onToggleFocus,
          onDelete: onDelete, onTap: onTapTask,
        );
      },
    );
  }
}
