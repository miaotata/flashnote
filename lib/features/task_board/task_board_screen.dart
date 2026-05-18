import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'providers/task_provider.dart';
import 'daily_focus_screen.dart';
import 'widgets/quadrant_grid.dart';
import 'widgets/tag_grouped_task_list.dart';

class TaskBoardScreen extends ConsumerWidget {
  const TaskBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('任务看板')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DailyFocusBanner(
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const DailyFocusScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ViewModeToggle(),
            const SizedBox(height: 12),
            _TaskView(),
          ],
        ),
      ),
    );
  }
}

class _DailyFocusBanner extends ConsumerWidget {
  final VoidCallback onTap;
  const _DailyFocusBanner({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(dailyFocusTasksProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
              AppColors.dailyFocusBadge, context,
            ).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.star_fill,
                size: 22, color: AppColors.dailyFocusBadge),
            const SizedBox(width: 12),
            Expanded(
              child: focusAsync.when(
                data: (tasks) {
                  final incomplete =
                      tasks.where((t) => !t.completed).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('今日焦点',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        incomplete > 0
                            ? '还有 $incomplete 项待完成'
                            : '已全部完成',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.secondaryLabel, context),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Text('加载中...'),
                error: (_, _) => const Text('今日焦点'),
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 18, color: CupertinoColors.tertiaryLabel),
          ],
        ),
      ),
    );
  }
}

class _ViewModeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(taskBoardViewModeProvider);

    return CupertinoSegmentedControl<String>(
      children: const {
        'quadrant': Text('四象限', style: TextStyle(fontSize: 13)),
        'tag': Text('按标签', style: TextStyle(fontSize: 13)),
      },
      groupValue: mode,
      onValueChanged: (v) {
        ref.read(taskBoardViewModeProvider.notifier).state = v;
      },
    );
  }
}

class _TaskView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(taskBoardViewModeProvider);

    if (mode == 'tag') {
      return const SizedBox(
        height: 500,
        child: TagGroupedTaskList(),
      );
    }

    return SizedBox(
      height: 500,
      child: QuadrantGrid(),
    );
  }
}
