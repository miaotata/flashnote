import 'package:drift/drift.dart' show Value;
import '../database/database.dart';

class ReminderRepository {
  final AppDatabase _db;

  ReminderRepository(this._db);

  Future<List<ReminderData>> getAll() => _db.select(_db.reminders).get();

  Future<ReminderData?> getByTaskId(int taskId) =>
      (_db.select(_db.reminders)..where((t) => t.taskId.equals(taskId)))
          .getSingleOrNull();

  Future<int> insert(RemindersCompanion reminder) =>
      _db.into(_db.reminders).insert(reminder);

  Future<int> update(int id, RemindersCompanion reminder) =>
      (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
          .write(reminder);

  Future<int> delete(int id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();

  Future<int> deleteByTaskId(int taskId) =>
      (_db.delete(_db.reminders)..where((t) => t.taskId.equals(taskId))).go();

  Future<List<ReminderData>> getPersistentReminders() =>
      (_db.select(_db.reminders)..where((t) => t.isPersistent.equals(true)))
          .get();

  Future<int> incrementSnooze(int id) async {
    final reminder = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (reminder == null) return 0;
    return (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      RemindersCompanion(
        snoozeCount: Value(reminder.snoozeCount + 1),
        lastTriggered: Value(DateTime.now()),
      ),
    );
  }
}
