import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import 'providers/integration_provider.dart';
import 'widgets/note_card.dart';

class TagCollectionScreen extends ConsumerStatefulWidget {
  const TagCollectionScreen({super.key});

  @override
  ConsumerState<TagCollectionScreen> createState() =>
      _TagCollectionScreenState();
}

class _TagCollectionScreenState extends ConsumerState<TagCollectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedTagId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateTagSheet() {
    final nameCtrl = TextEditingController();
    String selectedColor = AppColors.tagColors.first.toHex();

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('新建标签'),
        actions: [
          CupertinoTextField(
            controller: nameCtrl,
            placeholder: '标签名称',
            padding: const EdgeInsets.all(12),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          // 颜色选择器
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppColors.tagColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color.toHex();
                  });
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selectedColor == color.toHex()
                        ? Border.all(color: CupertinoColors.label, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          CupertinoActionSheetAction(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                ref.read(createTagProvider((
                  name: nameCtrl.text.trim(),
                  color: selectedColor,
                )));
              }
              Navigator.pop(context);
            },
            child: const Text('创建'),
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

  void _showTagActionsSheet(TagData tag) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(tag.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => _TagDetailScreen(tag: tag),
                ),
              );
            },
            child: const Text('查看该标签下所有笔记'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(deleteTagProvider(tag.id));
              if (_selectedTagId == tag.id) {
                setState(() => _selectedTagId = null);
              }
              Navigator.pop(context);
            },
            child: const Text('删除标签'),
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

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(allTagsProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('想法聚合'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showCreateTagSheet,
          child: const Icon(CupertinoIcons.add, size: 24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: '搜索笔记...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            // 标签云
            tagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '还没有标签，点右上角 + 创建',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // "全部" 按钮
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _TagFilterChip(
                          label: '全部',
                          isSelected: _selectedTagId == null,
                          onTap: () => setState(() => _selectedTagId = null),
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                      ...tags.map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _TagFilterChip(
                              label: tag.name,
                              isSelected: _selectedTagId == tag.id,
                              onTap: () => setState(() => _selectedTagId = tag.id),
                              color: _parseHexColor(tag.color),
                              onLongPress: () => _showTagActionsSheet(tag),
                            ),
                          )),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 20),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // 笔记列表
            Expanded(
              child: _buildNoteList(ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteList(WidgetRef ref) {
    // 如果有搜索查询，优先显示搜索结果
    if (_searchQuery.isNotEmpty) {
      final results = ref.watch(searchNotesProvider(_searchQuery));
      return results.when(
        data: (notes) => _noteListView(notes),
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => const Center(child: Text('搜索失败')),
      );
    }

    // 如果有选中的标签，显示该标签下的笔记
    if (_selectedTagId != null) {
      final notesAsync = ref.watch(notesByTagProvider(_selectedTagId!));
      return notesAsync.when(
        data: (notes) => _noteListView(notes),
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => const Center(child: Text('加载失败')),
      );
    }

    // 默认：显示空状态
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.tray,
            size: 48,
            color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            '搜索笔记或选择标签查看聚合',
            style: TextStyle(fontSize: 14, color: CupertinoColors.tertiaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _noteListView(List<NoteData> notes) {
    if (notes.isEmpty) {
      return Center(
        child: Text(
          '没有找到笔记',
          style: TextStyle(color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.6)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notes.length,
      itemBuilder: (context, index) => NoteCard(note: notes[index]),
    );
  }

  Color _parseHexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return CupertinoColors.systemBlue;
    }
  }
}

// ─── 标签过滤 Chip ──────────────────────────

class _TagFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color color;

  const _TagFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : null,
          ),
        ),
      ),
    );
  }
}

// ─── 标签详情页 ───────────────────────────

class _TagDetailScreen extends ConsumerWidget {
  final TagData tag;

  const _TagDetailScreen({required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesByTagProvider(tag.id));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(tag.name),
      ),
      child: SafeArea(
        child: notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return const Center(
                child: Text('该标签下还没有笔记',
                    style: TextStyle(color: CupertinoColors.tertiaryLabel)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (_, index) => NoteCard(note: notes[index]),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => const Center(child: Text('加载失败')),
        ),
      ),
    );
  }
}

extension ColorHex on Color {
  String toHex() {
    return '#${toARGB32().toRadixString(16).substring(2)}';
  }
}
