import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database.dart';
import '../../../main.dart';
import '../../reminder/providers/reminder_provider.dart';
import '../providers/task_provider.dart';
import 'task_card.dart';

class TagGroupedTaskList extends ConsumerWidget {
  const TagGroupedTaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(tagGroupedTasksProvider);
    final reminderIds = ref.watch(reminderTaskIdsProvider).valueOrNull ?? {};

    return groupedAsync.when(
      data: (grouped) {
        if (grouped.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.tag,
                    size: 40, color: CupertinoColors.tertiaryLabel),
                const SizedBox(height: 8),
                const Text('没有已标记的任务',
                    style: TextStyle(color: CupertinoColors.tertiaryLabel)),
                const SizedBox(height: 4),
                Text('为笔记添加标签后升级为任务即可查看',
                    style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.tertiaryLabel
                            .withValues(alpha: 0.6))),
              ],
            ),
          );
        }

        final entries = grouped.entries.toList();
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final tag = entries[index].key;
            final tasks = entries[index].value;
            final tagColor =
                Color(int.parse(tag.color.replaceFirst('#', '0xFF')));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(tag.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tagColor)),
                      const SizedBox(width: 8),
                      Text('${tasks.length} 个任务',
                          style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.tertiaryLabel)),
                    ],
                  ),
                ),
                ...tasks.map((entry) => GestureDetector(
                      onLongPress: () => _showTagMenu(
                          context, ref, entry.key, entry.value, tag),
                      child: _TaskCardWithTags(
                        key: ValueKey('tag_${entry.key.id}'),
                        task: entry.key,
                        note: entry.value,
                        hasReminder: reminderIds.contains(entry.key.id),
                        onToggleComplete: () {
                          ref.read(toggleTaskCompleteProvider(entry.key.id));
                        },
                        onToggleFocus: () {
                          ref.read(toggleDailyFocusProvider(entry.key.id));
                        },
                        onDelete: () {
                          ref.read(deleteTaskProvider(entry.key.id));
                        },
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, _) => const Center(child: Text('加载失败')),
    );
  }

  void _showTagMenu(BuildContext context, WidgetRef ref, TaskData task,
      NoteData? note, TagData tag) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('任务操作'),
        message: Text(note?.content ?? '任务 #${task.id}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              ref.read(tagRepoProvider).removeTagFromNote(task.noteId, tag.id);
              ref.invalidate(tagGroupedTasksProvider);
            },
            child: Text('从「${tag.name}」移出',
                style: const TextStyle(color: CupertinoColors.systemOrange)),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(deleteTaskProvider(task.id));
            },
            child: const Text('删除任务'),
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
}

class _TaskCardWithTags extends ConsumerWidget {
  final TaskData task;
  final NoteData? note;
  final bool hasReminder;
  final VoidCallback onToggleComplete;
  final VoidCallback onToggleFocus;
  final VoidCallback onDelete;

  const _TaskCardWithTags({
    super.key,
    required this.task,
    required this.note,
    required this.hasReminder,
    required this.onToggleComplete,
    required this.onToggleFocus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<TagData>>(
      future: ref.read(tagRepoProvider).getTagsByTask(task.id),
      builder: (context, snapshot) {
        return TaskCard(
          task: task,
          note: note,
          hasReminder: hasReminder,
          tags: snapshot.data,
          onToggleComplete: onToggleComplete,
          onToggleFocus: onToggleFocus,
          onDelete: onDelete,
        );
      },
    );
  }
}
