import 'package:drift/drift.dart' show Value;
import '../database/database.dart';

class NoteRepository {
  final AppDatabase _db;

  NoteRepository(this._db);

  Future<List<NoteData>> getAll() => _db.select(_db.notes).get();

  Future<List<NoteData>> getActive() =>
      (_db.select(_db.notes)..where((t) => t.deletedAt.isNull())).get();

  Future<List<NoteData>> getDeleted() =>
      (_db.select(_db.notes)..where((t) => t.deletedAt.isNotNull())).get();

  Future<NoteData?> getById(int id) =>
      (_db.select(_db.notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insert(NotesCompanion note) =>
      _db.into(_db.notes).insert(note);

  Future<int> update(int id, NotesCompanion note) =>
      (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(note);

  /// 软删除
  Future<void> softDelete(int id) {
    return (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  /// 彻底删除
  Future<int> hardDelete(int id) =>
      (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();

  /// 清理超过 7 天的已删除项
  Future<void> purgeOldDeleted() {
    return _db.customStatement(
      "DELETE FROM notes WHERE deleted_at IS NOT NULL AND deleted_at < ?",
      [DateTime.now().subtract(const Duration(days: 7)).toIso8601String()],
    );
  }

  Stream<List<NoteData>> watchAll() =>
      (_db.select(_db.notes)..where((t) => t.deletedAt.isNull())).watch();

  Future<List<NoteData>> search(String query) {
    return _db.select(_db.notes).get().then((notes) {
      final q = query.toLowerCase();
      return notes.where((n) =>
          n.deletedAt == null && n.content.toLowerCase().contains(q)).toList();
    });
  }

  Future<List<NoteData>> getBacklinks(int noteId) async {
    final rows = await (_db.select(_db.backlinks)
          ..where((t) => t.targetNoteId.equals(noteId)))
        .get();
    final sourceIds = rows.map((r) => r.sourceNoteId).toList();
    if (sourceIds.isEmpty) return [];
    return (_db.select(_db.notes)..where((t) => t.id.isIn(sourceIds))).get();
  }
}
