import 'package:drift/drift.dart' show Value;
import '../database/database.dart';

class TagRepository {
  final AppDatabase _db;

  TagRepository(this._db);

  Future<List<TagData>> getAll() => _db.select(_db.tags).get();

  Future<int> insert(TagsCompanion tag) => _db.into(_db.tags).insert(tag);

  Future<int> delete(int id) =>
      (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();

  Future<void> addTagToNote(int noteId, int tagId) =>
      _db.into(_db.noteTags).insert(NoteTagsCompanion(
        noteId: Value(noteId),
        tagId: Value(tagId),
      ));

  Future<int> removeTagFromNote(int noteId, int tagId) {
    final q = (_db.delete(_db.noteTags)
      ..where((t) => t.noteId.equals(noteId))
      ..where((t) => t.tagId.equals(tagId)));
    return q.go();
  }

  Future<List<NoteData>> getNotesByTag(int tagId) async {
    final rows = await (_db.select(_db.noteTags)
          ..where((t) => t.tagId.equals(tagId)))
        .get();
    final noteIds = rows.map((r) => r.noteId).toList();
    if (noteIds.isEmpty) return [];
    return (_db.select(_db.notes)..where((t) => t.id.isIn(noteIds))).get();
  }

  Future<List<TagData>> getTagsByNote(int noteId) async {
    final rows = await (_db.select(_db.noteTags)
          ..where((t) => t.noteId.equals(noteId)))
        .get();
    final tagIds = rows.map((r) => r.tagId).toList();
    if (tagIds.isEmpty) return [];
    return (_db.select(_db.tags)..where((t) => t.id.isIn(tagIds))).get();
  }

  Future<List<TaskData>> getTasksByTag(int tagId) async {
    final noteTagRows = await (_db.select(_db.noteTags)
          ..where((t) => t.tagId.equals(tagId)))
        .get();
    final noteIds = noteTagRows.map((r) => r.noteId).toList();
    if (noteIds.isEmpty) return [];
    return (_db.select(_db.tasks)..where((t) => t.noteId.isIn(noteIds))).get();
  }

  Future<List<TagData>> getTagsByTask(int taskId) async {
    final task = await (_db.select(_db.tasks)
          ..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
    if (task == null) return [];
    return getTagsByNote(task.noteId);
  }

  Stream<List<TagData>> watchAll() => _db.select(_db.tags).watch();
}
