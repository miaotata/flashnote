import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ReorderableListView, Colors;
import 'package:flutter/material.dart' as material show Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import '../../main.dart';
import '../../features/capture/providers/capture_provider.dart';
import '../../features/capture/note_detail_screen.dart';
import '../../features/reminder/reminder_screen.dart';
import '../../features/task_board/providers/task_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../features/integration/providers/integration_provider.dart';
import 'fullscreen_image.dart';

final sortModeLabelProvider = Provider<String>((ref) {
  switch (ref.watch(taskSortModeProvider)) {
    case 'created': return '创建时间 ▼';
    case 'updated': return '编辑时间 ▼';
    case 'priority': return '重要程度 ▼';
    case 'urgency': return '紧急程度 ▼';
    case 'completed': return '完成时间 ▼';
    case 'manual': return '手动排序 ▼';
    default: return '创建时间 ▼';
  }
});

class RecentNotesList extends ConsumerWidget {
  const RecentNotesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final sortMode = ref.watch(taskSortModeProvider);

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return const Center(child: Text('还没有记录',
              style: TextStyle(color: CupertinoColors.tertiaryLabel)));
        }
        return tasksAsync.when(
          data: (tasks) {
            final taskNoteIds = tasks.map((t) => t.noteId).toSet();
            final noteToTaskId = {for (final t in tasks) t.noteId: t.id};
            var recent = notes.take(50).toList();
            recent = _sortNotes(recent, tasks, sortMode);

            if (sortMode == 'manual') {
              return _ManualOrderList(
                notes: recent, tasks: tasks,
                taskNoteIds: taskNoteIds, noteToTaskId: noteToTaskId,
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              itemBuilder: (context, index) {
                final note = recent[index];
                return _NoteRow(
                  key: ValueKey('note_${note.id}'),
                  note: note,
                  isTask: taskNoteIds.contains(note.id),
                  noteToTaskId: noteToTaskId,
                  sortMode: sortMode,
                  tasks: tasks,
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  List<NoteData> _sortNotes(List<NoteData> notes, List<TaskData> tasks, String mode) {
    switch (mode) {
      case 'created':
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'updated':
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case 'priority':
        notes.sort((a, b) {
          const prio = {'high': 0, 'medium': 1, 'low': 2};
          final tA = tasks.where((t) => t.noteId == a.id).firstOrNull;
          final tB = tasks.where((t) => t.noteId == b.id).firstOrNull;
          return (prio[tA?.priority] ?? 2).compareTo(prio[tB?.priority] ?? 2);
        });
      case 'urgency':
        notes.sort((a, b) {
          const urg = {'urgent': 0, 'not_urgent': 1};
          final tA = tasks.where((t) => t.noteId == a.id).firstOrNull;
          final tB = tasks.where((t) => t.noteId == b.id).firstOrNull;
          return (urg[tA?.urgency] ?? 1).compareTo(urg[tB?.urgency] ?? 1);
        });
      case 'completed':
        notes.sort((a, b) {
          final tA = tasks.where((t) => t.noteId == a.id).firstOrNull;
          final tB = tasks.where((t) => t.noteId == b.id).firstOrNull;
          if (tA?.completed == true && tB?.completed != true) return 1;
          if (tB?.completed == true && tA?.completed != true) return -1;
          return b.createdAt.compareTo(a.createdAt);
        });
      default:
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return notes;
  }
}

class _ManualOrderList extends ConsumerStatefulWidget {
  final List<NoteData> notes;
  final List<TaskData> tasks;
  final Set<int> taskNoteIds;
  final Map<int, int> noteToTaskId;

  const _ManualOrderList({
    required this.notes, required this.tasks,
    required this.taskNoteIds, required this.noteToTaskId,
  });

  @override
  ConsumerState<_ManualOrderList> createState() => _ManualOrderListState();
}

class _ManualOrderListState extends ConsumerState<_ManualOrderList> {
  late List<NoteData> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.notes);
  }

  @override
  void didUpdateWidget(_ManualOrderList old) {
    super.didUpdateWidget(old);
    if (old.notes != widget.notes) _items = List.from(widget.notes);
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      proxyDecorator: (child, index, animation) => material.Material(
        color: Colors.transparent,
        child: child,
      ),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
        for (var i = 0; i < _items.length; i++) {
          for (final task in widget.tasks.where((t) => t.noteId == _items[i].id)) {
            ref.read(taskRepoProvider).updateSortOrder(task.id, i);
          }
        }
      },
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final note = _items[index];
        return _NoteRow(
          key: ValueKey('note_${note.id}'),
          note: note,
          isTask: widget.taskNoteIds.contains(note.id),
          noteToTaskId: widget.noteToTaskId,
          sortMode: 'manual',
          tasks: widget.tasks,
        );
      },
    );
  }
}

class _NoteRow extends ConsumerWidget {
  final NoteData note;
  final bool isTask;
  final Map<int, int> noteToTaskId;
  final String sortMode;
  final List<TaskData> tasks;

  const _NoteRow({
    super.key, required this.note, required this.isTask,
    required this.noteToTaskId, required this.sortMode, required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = note.imagePath != null && note.imagePath!.isNotEmpty;
    final metaText = _buildMeta();

    return Dismissible(
      key: Key('note_dismiss_${note.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref.read(deleteNoteProvider(note.id)),
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
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => NoteDetailScreen(noteId: note.id)));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondarySystemBackground, context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (hasImage)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(CupertinoPageRoute(
                      builder: (_) => FullScreenImage(imagePath: note.imagePath!),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(File(note.imagePath!),
                          width: 44, height: 44, fit: BoxFit.cover),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.content.isNotEmpty)
                      Text(
                        note.content.length > 35
                            ? '${note.content.substring(0, 35)}...'
                            : note.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: isTask
                              ? CupertinoDynamicColor.resolve(
                                  CupertinoColors.tertiaryLabel, context)
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (metaText != null)
                      Padding(
                        padding: EdgeInsets.only(top: note.content.isNotEmpty ? 2 : 0),
                        child: Text(metaText,
                            style: TextStyle(fontSize: 11,
                                color: CupertinoColors.secondaryLabel)),
                      ),
                  ],
                ),
              ),
              _actBtn(child: const Icon(CupertinoIcons.tag, size: 18),
                  onTap: () => _showTagSheet(context, ref)),
              _actBtn(child: const Text('升级', style: TextStyle(fontSize: 12)),
                  onTap: () => _showPromoteSheet(context, ref)),
              _actBtn(child: const Icon(CupertinoIcons.bell, size: 18),
                  onTap: () => _setReminder(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  String? _buildMeta() {
    final task = tasks.where((t) => t.noteId == note.id).firstOrNull;
    final fmt = DateFormat('MM-dd HH:mm');
    switch (sortMode) {
      case 'created':
        return '创建于 ${fmt.format(note.createdAt)}';
      case 'updated':
        return '编辑于 ${fmt.format(note.updatedAt)}';
      case 'priority':
        if (task == null) return null;
        const labels = {'high': '高', 'medium': '中', 'low': '低'};
        return '重要程度：${labels[task.priority] ?? '-'}';
      case 'urgency':
        if (task == null) return null;
        const labels = {'urgent': '紧急', 'not_urgent': '不紧急'};
        return '紧急程度：${labels[task.urgency] ?? '-'}';
      case 'completed':
        if (task?.completed == true && task!.completedAt != null) {
          return '完成于 ${fmt.format(task.completedAt!)}';
        }
        return null;
    }
    return null;
  }

  Widget _actBtn({required Widget child, required VoidCallback onTap}) {
    return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: onTap, child: child);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除记录'),
        content: Text(note.content.length > 50
            ? '${note.content.substring(0, 50)}...' : note.content),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    return result == true;
  }

  void _showTagSheet(BuildContext context, WidgetRef ref) {
    FocusManager.instance.primaryFocus?.unfocus();
    final nameController = TextEditingController();
    String selectedColor = '#007AFF';
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => CupertinoActionSheet(
          title: const Text('添加标签'),
          actions: [
            CupertinoActionSheetAction(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoTextField(
                    controller: nameController,
                    placeholder: '新标签名称', autofocus: true),
              ),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              onPressed: () {},
              child: _ColorPicker(
                selectedColor: selectedColor,
                onColorSelected: (c) => setLocalState(() => selectedColor = c),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final tagRepo = ref.read(tagRepoProvider);
                final tagId = await tagRepo.insert(
                    TagsCompanion(name: Value(name), color: Value(selectedColor)));
                await tagRepo.addTagToNote(note.id, tagId);
                ref.invalidate(allTagsProvider);
                ref.invalidate(tagsByNoteProvider(note.id));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('创建并添加'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ),
      ),
    );
  }

  void _showPromoteSheet(BuildContext context, WidgetRef ref) {
    FocusManager.instance.primaryFocus?.unfocus();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('升级为任务'),
        message: Text(note.content.length > 50
            ? '${note.content.substring(0, 50)}...' : note.content),
        actions: [
          _promo(context, ref, '紧急且重要', AppColors.priorityHigh,
              'urgent', 'important', 'high'),
          _promo(context, ref, '重要但不紧急', AppColors.quadrantNotUrgentImportant,
              'not_urgent', 'important', 'high'),
          _promo(context, ref, '紧急但不重要', AppColors.quadrantUrgentNotImportant,
              'urgent', 'not_important', 'medium'),
          _promo(context, ref, '不紧急不重要', CupertinoColors.systemGrey,
              'not_urgent', 'not_important', 'low'),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _promo(BuildContext context, WidgetRef ref, String label,
      Color c, String urgency, String importance, String priority) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context);
        ref.read(promoteToTaskProvider(
            (noteId: note.id, priority: priority, urgency: urgency, importance: importance)));
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        Text(label),
      ]),
    );
  }

  void _setReminder(BuildContext context, WidgetRef ref) async {
    int taskId;
    if (isTask) {
      taskId = noteToTaskId[note.id]!;
    } else {
      final taskRepo = ref.read(taskRepoProvider);
      taskId = await taskRepo.insert(TasksCompanion(
        noteId: Value(note.id),
        priority: const Value('medium'),
        urgency: const Value('not_urgent'),
        importance: const Value('important'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    }
    if (context.mounted) {
      Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => ReminderScreen(taskId: taskId, taskTitle: note.content),
      ));
    }
  }
}

class _ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const _ColorPicker({required this.selectedColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: AppColors.tagColors.map((c) {
        final hex = c.toARGB32().toRadixString(16).padLeft(8, '0');
        final hexStr = '#${hex.substring(2)}';
        final selected = hexStr == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(hexStr),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: CupertinoColors.label, width: 3)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
