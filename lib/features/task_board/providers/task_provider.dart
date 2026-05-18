import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../data/database/database.dart';
import '../../../main.dart';
import '../../settings/providers/settings_provider.dart';

// 任务版本号 — mutation 后 +1 触发 quadrant/tag 视图强制刷新
final taskVersionProvider = StateProvider<int>((ref) => 0);

// 所有任务
final tasksProvider = StreamProvider<List<TaskData>>((ref) {
  return ref.watch(taskRepoProvider).watchAll();
});

// 每日焦点任务
final dailyFocusTasksProvider = StreamProvider<List<TaskData>>((ref) {
  return ref.watch(taskRepoProvider).watchDailyFocus();
});

// 每日焦点计数
final dailyFocusCountProvider = FutureProvider<int>((ref) {
  return ref.watch(taskRepoProvider).countDailyFocus();
});

// 升级笔记为任务
final promoteToTaskProvider =
    FutureProvider.family<void, ({int noteId, String priority, String urgency, String importance})>(
  (ref, params) async {
    final taskRepo = ref.watch(taskRepoProvider);
    await taskRepo.insert(TasksCompanion(
      noteId: Value(params.noteId),
      priority: Value(params.priority),
      urgency: Value(params.urgency),
      importance: Value(params.importance),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
    ref.read(taskVersionProvider.notifier).state++;
  },
);

// 切换每日焦点（上限 3 个）
final toggleDailyFocusProvider = FutureProvider.family<void, int>((ref, taskId) async {
  final taskRepo = ref.watch(taskRepoProvider);
  final tasks = await taskRepo.getAll();
  final task = tasks.where((t) => t.id == taskId).firstOrNull;
  if (task == null) return;

  if (!task.isDailyFocus) {
    final count = await taskRepo.countDailyFocus();
    final limit = ref.read(dailyFocusLimitProvider);
    if (count >= limit) return;
  }

  await taskRepo.update(taskId, TasksCompanion(
    isDailyFocus: Value(!task.isDailyFocus),
    updatedAt: Value(DateTime.now()),
  ));
  ref.read(taskVersionProvider.notifier).state++;
  ref.invalidate(dailyFocusTasksProvider);
  ref.invalidate(dailyFocusCountProvider);
});

// 切换完成状态
final toggleTaskCompleteProvider = FutureProvider.family<void, int>((ref, taskId) async {
  final taskRepo = ref.watch(taskRepoProvider);
  final tasks = await taskRepo.getAll();
  final task = tasks.where((t) => t.id == taskId).firstOrNull;
  if (task == null) return;
  await taskRepo.toggleComplete(taskId, !task.completed);
  ref.read(taskVersionProvider.notifier).state++;
});

// 更新优先级
final updateTaskPriorityProvider =
    FutureProvider.family<void, ({int taskId, String priority})>(
  (ref, params) async {
    final taskRepo = ref.watch(taskRepoProvider);
    await taskRepo.update(params.taskId, TasksCompanion(
      priority: Value(params.priority),
      updatedAt: Value(DateTime.now()),
    ));
  },
);

// 四象限分组（监听 tasksProvider + taskVersionProvider 确保响应式刷新）
final quadrantTasksProvider =
    FutureProvider<Map<int, List<MapEntry<TaskData, NoteData?>>>>((ref) async {
  ref.watch(taskVersionProvider);
  final tasksAsync = ref.watch(tasksProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  final noteRepo = ref.watch(noteRepoProvider);

  final grouped = <int, List<MapEntry<TaskData, NoteData?>>>{
    0: [], 1: [], 2: [], 3: [],
  };

  for (final task in tasks) {
    final quadrant = _quadrantIndex(task.urgency, task.importance);
    final note = await noteRepo.getById(task.noteId);
    grouped[quadrant]!.add(MapEntry(task, note));
  }

  return grouped;
});

// 删除任务（软删除）
final deleteTaskProvider = FutureProvider.family<void, int>((ref, taskId) async {
  final taskRepo = ref.watch(taskRepoProvider);
  await taskRepo.softDelete(taskId);
  ref.read(taskVersionProvider.notifier).state++;
  ref.invalidate(dailyFocusTasksProvider);
});

// 看板视图模式
final taskBoardViewModeProvider = StateProvider<String>((ref) => 'quadrant');

// 按标签分组的任务
final tagGroupedTasksProvider =
    FutureProvider<Map<TagData, List<MapEntry<TaskData, NoteData?>>>>((ref) async {
  ref.watch(taskVersionProvider);
  final tagRepo = ref.watch(tagRepoProvider);
  final noteRepo = ref.watch(noteRepoProvider);
  final allTags = await tagRepo.getAll();

  final grouped = <TagData, List<MapEntry<TaskData, NoteData?>>>{};

  for (final tag in allTags) {
    final tasks = await tagRepo.getTasksByTag(tag.id);
    if (tasks.isNotEmpty) {
      final entries = <MapEntry<TaskData, NoteData?>>[];
      for (final task in tasks) {
        final note = await noteRepo.getById(task.noteId);
        entries.add(MapEntry(task, note));
      }
      grouped[tag] = entries;
    }
  }

  return grouped;
});

int _quadrantIndex(String urgency, String importance) {
  if (urgency == 'urgent' && importance == 'important') return 0;
  if (urgency == 'not_urgent' && importance == 'important') return 1;
  if (urgency == 'urgent' && importance == 'not_important') return 2;
  return 3;
}
