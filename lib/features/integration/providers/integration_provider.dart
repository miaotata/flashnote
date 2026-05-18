import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../data/database/database.dart';
import '../../../main.dart';

// 所有标签
final allTagsProvider = StreamProvider<List<TagData>>((ref) {
  return ref.watch(tagRepoProvider).watchAll();
});

// 某标签下的所有笔记
final notesByTagProvider = FutureProvider.family<List<NoteData>, int>((ref, tagId) {
  return ref.watch(tagRepoProvider).getNotesByTag(tagId);
});

// 某笔记的所有标签
final tagsByNoteProvider = FutureProvider.family<List<TagData>, int>((ref, noteId) {
  return ref.watch(tagRepoProvider).getTagsByNote(noteId);
});

// 搜索笔记
final searchNotesProvider = FutureProvider.family<List<NoteData>, String>((ref, query) {
  return ref.watch(noteRepoProvider).search(query);
});

// 某笔记的反向链接
final backlinksForNoteProvider = FutureProvider.family<List<NoteData>, int>((ref, noteId) {
  return ref.watch(noteRepoProvider).getBacklinks(noteId);
});

// ─── 标签操作 ─────────────────────────

final createTagProvider = FutureProvider.family<void, ({String name, String color})>(
  (ref, params) async {
    await ref.watch(tagRepoProvider).insert(TagsCompanion(
      name: Value(params.name),
      color: Value(params.color),
      createdAt: Value(DateTime.now()),
    ));
  },
);

final addTagToNoteProvider = FutureProvider.family<void, ({int noteId, int tagId})>(
  (ref, params) async {
    await ref.watch(tagRepoProvider).addTagToNote(params.noteId, params.tagId);
  },
);

final removeTagFromNoteProvider = FutureProvider.family<void, ({int noteId, int tagId})>(
  (ref, params) async {
    await ref.watch(tagRepoProvider).removeTagFromNote(params.noteId, params.tagId);
  },
);

final deleteTagProvider = FutureProvider.family<void, int>((ref, tagId) async {
  await ref.watch(tagRepoProvider).delete(tagId);
});

// ─── 反向链接解析 ──────────────────────

List<String> parseBacklinkTargets(String text) {
  final regex = RegExp(r'\[\[(.+?)\]\]');
  return regex.allMatches(text).map((m) => m.group(1)!.trim()).toList();
}

Future<void> saveBacklinks(
  int sourceNoteId,
  String content,
) async {
  // 此函数需配合 ref 使用，调用时传入 noteRepo 和 db
}
