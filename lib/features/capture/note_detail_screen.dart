import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../data/database/database.dart';
import '../integration/providers/integration_provider.dart';
import '../../main.dart';
import '../../shared/widgets/fullscreen_image.dart';
import 'package:audioplayers/audioplayers.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final int noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final _editController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除笔记'),
        content: const Text('此操作不可恢复'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(noteRepoProvider).softDelete(widget.noteId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _saveEdit() async {
    final content = _editController.text.trim();
    if (content.isEmpty) return;

    await ref.read(noteRepoProvider).update(
          widget.noteId,
          NotesCompanion(
            content: Value(content),
            updatedAt: Value(DateTime.now()),
          ),
        );

    setState(() => _isEditing = false);
    // 刷新
    ref.invalidate(backlinksForNoteProvider(widget.noteId));
  }

  void _startEdit(String currentContent) {
    _editController.text = currentContent;
    setState(() => _isEditing = true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NoteData?>(
      future: ref.read(noteRepoProvider).getById(widget.noteId),
      builder: (context, snapshot) {
        final note = snapshot.data;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(_isEditing ? '编辑笔记' : '笔记详情'),
            trailing: note == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isEditing)
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => _startEdit(note.content),
                          child: const Text('编辑', style: TextStyle(fontSize: 15)),
                        ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: _delete,
                        child: const Icon(CupertinoIcons.trash, size: 20),
                      ),
                    ],
                  ),
          ),
          child: SafeArea(
            child: note == null
                ? const Center(child: CupertinoActivityIndicator())
                : _isEditing
                    ? _buildEditView(note)
                    : _buildDetailView(context, note),
          ),
        );
      },
    );
  }

  Widget _buildEditView(NoteData note) {
    final hasImage = note.imagePath != null && note.imagePath!.isNotEmpty;
    final hasAudio = note.type == 'voice' && note.audioPath != null && note.audioPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 图片编辑区
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => FullScreenImage(imagePath: note.imagePath!),
                  ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Image.file(File(note.imagePath!),
                          height: 120, width: double.infinity, fit: BoxFit.cover),
                      Positioned(
                        top: 4, right: 4,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(4),
                          color: CupertinoColors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () async {
                            await ref.read(noteRepoProvider).update(
                              widget.noteId,
                              NotesCompanion(imagePath: const Value(null)),
                            );
                            setState(() => _isEditing = false);
                            Future.microtask(() => setState(() => _isEditing = true));
                          },
                          child: const Icon(CupertinoIcons.xmark,
                              color: CupertinoColors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 音频编辑区
          if (hasAudio)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.waveform,
                        color: CupertinoColors.systemGreen, size: 18),
                    const SizedBox(width: 6),
                    const Text('语音记录',
                        style: TextStyle(
                            color: CupertinoColors.systemGreen, fontSize: 13)),
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.all(4),
                      onPressed: () async {
                        await ref.read(noteRepoProvider).update(
                          widget.noteId,
                          NotesCompanion(audioPath: const Value(null), type: const Value('text')),
                        );
                        setState(() => _isEditing = false);
                        Future.microtask(() => setState(() => _isEditing = true));
                      },
                      child: const Icon(CupertinoIcons.trash,
                          size: 16, color: CupertinoColors.systemRed),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: CupertinoTextField(
              controller: _editController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              padding: const EdgeInsets.all(16),
              style: const TextStyle(fontSize: 17),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('取消'),
              ),
              CupertinoButton.filled(
                onPressed: _saveEdit,
                child: const Text('保存修改'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, NoteData note) {
    final tagsAsync = ref.watch(tagsByNoteProvider(note.id));
    final backlinksAsync = ref.watch(backlinksForNoteProvider(note.id));

    final hasImage = note.imagePath != null && note.imagePath!.isNotEmpty;
    final hasAudio = note.type == 'voice' && note.audioPath != null && note.audioPath!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 音频播放区
        if (hasAudio) _AudioPlayerBar(audioPath: note.audioPath!),
        // 图片区
        if (hasImage)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => FullScreenImage(imagePath: note.imagePath!),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(note.imagePath!),
                    width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ),
        // 内容区
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.secondarySystemBackground, context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            note.content,
            style: const TextStyle(fontSize: 17, height: 1.6),
          ),
        ),
        const SizedBox(height: 20),

        // 元信息
        _sectionTitle('信息'),
        const SizedBox(height: 8),
        _infoRow('类型', note.type == 'voice' ? '语音笔记' : '文字笔记'),
        _infoRow('创建时间', _formatDateTime(note.createdAt)),
        _infoRow('更新时间', _formatDateTime(note.updatedAt)),
        const SizedBox(height: 20),

        // 标签
        _sectionTitle('标签'),
        const SizedBox(height: 8),
        tagsAsync.when(
          data: (tags) => _TagsSection(
            noteId: note.id,
            tags: tags,
          ),
          loading: () => const CupertinoActivityIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        // 反向链接
        _sectionTitle('反向链接'),
        const SizedBox(height: 8),
        backlinksAsync.when(
          data: (backlinks) {
            if (backlinks.isEmpty) {
              return Text('还没有笔记引用这条',
                  style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.6)));
            }
            return Column(
              children: backlinks.map((b) => _BacklinkRow(note: b)).toList(),
            );
          },
          loading: () => const CupertinoActivityIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── 标签区域 ────────────────────────────

class _TagsSection extends ConsumerWidget {
  final int noteId;
  final List<TagData> tags;

  const _TagsSection({required this.noteId, required this.tags});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTagsAsync = ref.watch(allTagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _parseColor(tag.color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tag.name,
                        style: TextStyle(fontSize: 12, color: _parseColor(tag.color))),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        ref.read(removeTagFromNoteProvider(
                            (noteId: noteId, tagId: tag.id)));
                        ref.invalidate(tagsByNoteProvider(noteId));
                      },
                      child: Icon(CupertinoIcons.xmark_circle_fill, size: 14,
                          color: _parseColor(tag.color).withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),

        // 添加标签
        allTagsAsync.when(
          data: (allTags) {
            final available = allTags.where((t) => !tags.any((mt) => mt.id == t.id)).toList();
            if (available.isEmpty) {
              return Text('所有标签已添加',
                  style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.6)));
            }
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: available.map((tag) {
                return GestureDetector(
                  onTap: () {
                    ref.read(addTagToNoteProvider(
                        (noteId: noteId, tagId: tag.id)));
                    ref.invalidate(tagsByNoteProvider(noteId));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: _parseColor(tag.color).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.plus, size: 12,
                            color: _parseColor(tag.color).withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(tag.name,
                            style: TextStyle(fontSize: 12, color: _parseColor(tag.color))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CupertinoActivityIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
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

// ─── 反向链接行 ──────────────────────────

class _AudioPlayerBar extends StatefulWidget {
  final String audioPath;
  const _AudioPlayerBar({required this.audioPath});

  @override
  State<_AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<_AudioPlayerBar> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(widget.audioPath));
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondarySystemBackground, context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                size: 28,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 8),
              Text(
                _isPlaying ? '播放中...' : '点击播放录音',
                style: TextStyle(
                    fontSize: 15, color: CupertinoColors.secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BacklinkRow extends StatelessWidget {
  final NoteData note;
  const _BacklinkRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => NoteDetailScreen(noteId: note.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondarySystemBackground, context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.link, size: 14,
                color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note.content.length > 50
                    ? '${note.content.substring(0, 50)}...'
                    : note.content,
                style: const TextStyle(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 14,
                color: CupertinoColors.tertiaryLabel.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
