import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database.dart';
import '../../../main.dart';

/// 支持 [[ 自动补全的输入框
class BacklinkInput extends ConsumerStatefulWidget {
  final TextEditingController controller;

  const BacklinkInput({super.key, required this.controller});

  @override
  ConsumerState<BacklinkInput> createState() => _BacklinkInputState();
}

class _BacklinkInputState extends ConsumerState<BacklinkInput> {
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();
  List<NoteData> _suggestions = [];
  String _currentQuery = '';

  void _checkForBacklink(String text) {
    final lastOpen = text.lastIndexOf('[[');
    if (lastOpen == -1 || (lastOpen > 0 && text[lastOpen - 1] == '[')) {
      _hideSuggestions();
      return;
    }

    final afterOpen = text.substring(lastOpen + 2);
    final closeIdx = afterOpen.indexOf(']]');
    if (closeIdx != -1) {
      _hideSuggestions();
      return;
    }

    _currentQuery = afterOpen;
    _showSuggestions();
  }

  void _showSuggestions() async {
    final allNotes = await ref.read(noteRepoProvider).getAll();
    _suggestions = allNotes
        .where((n) => n.content.toLowerCase().contains(_currentQuery.toLowerCase()))
        .take(5)
        .toList();

    _overlayEntry?.remove();
    if (_suggestions.isEmpty || !mounted) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 40),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground, context),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _suggestions.map((note) {
                return GestureDetector(
                  onTap: () => _insertBacklink(note),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      note.content.length > 30
                          ? '${note.content.substring(0, 30)}...'
                          : note.content,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _insertBacklink(NoteData note) {
    final text = widget.controller.text;
    final lastOpen = text.lastIndexOf('[[');
    final before = text.substring(0, lastOpen);
    final title = note.content.length > 20
        ? '${note.content.substring(0, 20)}...'
        : note.content;
    widget.controller.text = '$before[[$title]]';
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    _hideSuggestions();
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideSuggestions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CupertinoTextField(
        controller: widget.controller,
        placeholder: '记录想法... 输入 [[ 链接其他笔记',
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        padding: const EdgeInsets.all(16),
        style: const TextStyle(fontSize: 17),
        onChanged: _checkForBacklink,
      ),
    );
  }
}
