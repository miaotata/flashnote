import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import '../../../main.dart';
import '../settings/providers/settings_provider.dart';
import '../reminder/providers/reminder_provider.dart';
import 'providers/task_provider.dart';
import '../capture/note_detail_screen.dart';
import 'widgets/task_card.dart';

class DailyFocusScreen extends ConsumerWidget {
  const DailyFocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(dailyFocusTasksProvider);
    final countAsync = ref.watch(dailyFocusCountProvider);
    final reminderIds = ref.watch(reminderTaskIdsProvider).valueOrNull ?? {};

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('今日焦点')),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dailyFocusBadge.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: countAsync.when(
                data: (count) {
                  final limit = ref.watch(dailyFocusLimitProvider);
                  return Text(
                    '今日焦点 $count / $limit',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  );
                },
                loading: () => const SizedBox(height: 20),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: focusAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.star,
                              size: 40,
                              color: CupertinoColors.tertiaryLabel
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          const Text('还没有今日焦点任务',
                              style: TextStyle(
                                  color: CupertinoColors.tertiaryLabel)),
                          const SizedBox(height: 4),
                          Text('在看板中点击星标设置',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.tertiaryLabel
                                      .withValues(alpha: 0.6))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return FutureBuilder<List<TagData>>(
                        future: ref.read(tagRepoProvider).getTagsByTask(task.id),
                        builder: (context, tagSnapshot) {
                          return FutureBuilder<NoteData?>(
                            future: ref.read(noteRepoProvider).getById(task.noteId),
                            builder: (context, noteSnapshot) {
                              return TaskCard(
                                key: ValueKey('focus_${task.id}'),
                                task: task,
                                note: noteSnapshot.data,
                                tags: tagSnapshot.data,
                                hasReminder: reminderIds.contains(task.id),
                                onToggleComplete: () {
                                  ref.read(toggleTaskCompleteProvider(task.id));
                                },
                                onToggleFocus: () {
                                  ref.read(toggleDailyFocusProvider(task.id));
                                },
                                onDelete: () {
                                  ref.read(deleteTaskProvider(task.id));
                                },
                                onTap: () {
                                  if (noteSnapshot.data != null) {
                                    Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (_) =>
                                          NoteDetailScreen(noteId: noteSnapshot.data!.id),
                                    ));
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (_, _) =>
                    const Center(child: Text('加载失败')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
