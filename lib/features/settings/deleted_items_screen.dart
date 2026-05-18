import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../main.dart';

final deletedNotesProvider = FutureProvider<List<NoteData>>((ref) {
  return ref.watch(noteRepoProvider).getDeleted();
});

final deletedTasksProvider = FutureProvider<List<TaskData>>((ref) {
  return ref.watch(taskRepoProvider).getDeleted();
});

class DeletedItemsScreen extends ConsumerWidget {
  const DeletedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('最近删除')),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondarySystemBackground, context),
              child: const Text('7 天后自动彻底删除',
                  style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                  textAlign: TextAlign.center),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DeletedSection<NoteData>(
                    title: '已删除的笔记',
                    provider: deletedNotesProvider,
                    remainingLabel: (d) {
                      final days = 7 -
                          DateTime.now().difference(d.deletedAt!).inDays;
                      return '${days.clamp(0, 7)}天后彻底删除';
                    },
                    content: (d) => d.content,
                    onHardDelete: (id) => ref.read(hardDeleteNoteProvider(id)),
                  ),
                  const SizedBox(height: 16),
                  _DeletedSection<TaskData>(
                    title: '已删除的任务',
                    provider: deletedTasksProvider,
                    remainingLabel: (d) {
                      final days = 7 -
                          DateTime.now().difference(d.deletedAt!).inDays;
                      return '${days.clamp(0, 7)}天后彻底删除';
                    },
                    content: (d) => '任务 #${d.id}',
                    onHardDelete: (id) => ref.read(hardDeleteTaskProvider(id)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final hardDeleteNoteProvider =
    FutureProvider.family<void, int>((ref, id) async {
  await ref.watch(noteRepoProvider).hardDelete(id);
  ref.invalidate(deletedNotesProvider);
});

final hardDeleteTaskProvider =
    FutureProvider.family<void, int>((ref, id) async {
  await ref.watch(taskRepoProvider).hardDelete(id);
  ref.invalidate(deletedTasksProvider);
});

class _DeletedSection<T> extends ConsumerWidget {
  final String title;
  final FutureProvider<List<T>> provider;
  final String Function(T) remainingLabel;
  final String Function(T) content;
  final void Function(int) onHardDelete;

  const _DeletedSection({
    required this.title,
    required this.provider,
    required this.remainingLabel,
    required this.content,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        async.when(
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('暂无已删除项',
                      style: TextStyle(
                          color: CupertinoColors.tertiaryLabel)),
                ),
              );
            }
            return Column(
              children: items.map((item) {
                final dynamicItem = item as dynamic;
                final id = dynamicItem.id as int;
                return Dismissible(
                  key: Key('deleted_${T}_$id'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmHardDelete(context, id),
                  onDismissed: (_) => onHardDelete(id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.delete,
                        color: CupertinoColors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                          CupertinoColors.secondarySystemBackground,
                          context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(content(dynamicItem as T),
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(remainingLabel(dynamicItem),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: CupertinoColors.secondaryLabel)),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: const Text('彻底删除',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemRed)),
                          onPressed: () async {
                            final ok = await _confirmHardDelete(context, id);
                            if (ok) onHardDelete(id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<bool> _confirmHardDelete(BuildContext context, int id) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('彻底删除'),
        content: const Text('删除后不可恢复'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
    return result == true;
  }
}
