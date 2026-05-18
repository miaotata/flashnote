import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database.dart';
import '../../capture/note_detail_screen.dart';
import '../providers/integration_provider.dart';

/// 在聚合页展示的笔记卡片，带标签和反向链接信息
class NoteCard extends ConsumerWidget {
  final NoteData note;
  final VoidCallback? onTap;

  const NoteCard({super.key, required this.note, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsByNoteProvider(note.id));
    final backlinksAsync = ref.watch(backlinksForNoteProvider(note.id));

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => NoteDetailScreen(noteId: note.id),
              ),
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondarySystemBackground, context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 笔记内容
            Text(
              note.content,
              style: const TextStyle(fontSize: 14, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // 底部信息行
            Row(
              children: [
                // 标签
                Expanded(
                  child: tagsAsync.when(
                    data: (tags) => tags.isEmpty
                        ? const SizedBox.shrink()
                        : Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: tags.map((t) => _TagDot(tag: t)).toList(),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                // 反向链接数量
                backlinksAsync.when(
                  data: (backlinks) {
                    if (backlinks.isEmpty) return const SizedBox.shrink();
                    return Row(
                      children: [
                        Icon(
                          CupertinoIcons.link,
                          size: 12,
                          color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${backlinks.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                // 时间
                Text(
                  _formatDate(note.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TagDot extends StatelessWidget {
  final TagData tag;
  const _TagDot({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _parseColor(tag.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.name,
        style: TextStyle(fontSize: 10, color: _parseColor(tag.color)),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return CupertinoColors.systemBlue;
    }
  }
}
