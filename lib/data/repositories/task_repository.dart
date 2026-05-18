import 'package:drift/drift.dart' show Value;
import '../database/database.dart';

class TaskRepository {
  final AppDatabase _db;

  TaskRepository(this._db);

  Future<List<TaskData>> getAll() =>
      (_db.select(_db.tasks)..where((t) => t.deletedAt.isNull())).get();

  Future<List<TaskData>> getIncomplete() =>
      (_db.select(_db.tasks)
            ..where((t) => t.completed.equals(false))
            ..where((t) => t.deletedAt.isNull()))
          .get();

  Future<List<TaskData>> getDailyFocus() =>
      (_db.select(_db.tasks)
            ..where((t) => t.isDailyFocus.equals(true))
            ..where((t) => t.deletedAt.isNull()))
          .get();

  Future<List<TaskData>> getDeleted() =>
      (_db.select(_db.tasks)..where((t) => t.deletedAt.isNotNull())).get();

  Future<int> countDailyFocus() async {
    final list = await getDailyFocus();
    return list.length;
  }

  Future<int> insert(TasksCompanion task) =>
      _db.into(_db.tasks).insert(task);

  Future<int> update(int id, TasksCompanion task) =>
      (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(task);

  Future<int> toggleComplete(int id, bool completed) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        completed: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 软删除
  Future<void> softDelete(int id) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  /// 彻底删除
  Future<int> hardDelete(int id) =>
      (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();

  /// 清理超过 7 天的已删除项
  Future<void> purgeOldDeleted() {
    return _db.customStatement(
      "DELETE FROM tasks WHERE deleted_at IS NOT NULL AND deleted_at < ?",
      [DateTime.now().subtract(const Duration(days: 7)).toIso8601String()],
    );
  }

  /// 更新手动排序位置
  Future<void> updateSortOrder(int id, int? sortOrder) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(sortOrder: Value(sortOrder)),
    );
  }

  Stream<List<TaskData>> watchAll() =>
      (_db.select(_db.tasks)..where((t) => t.deletedAt.isNull())).watch();

  Stream<List<TaskData>> watchDailyFocus() =>
      (_db.select(_db.tasks)
            ..where((t) => t.isDailyFocus.equals(true))
            ..where((t) => t.deletedAt.isNull()))
          .watch();

  Future<List<TaskData>> getOverdueIncomplete() {
    return _db.select(_db.tasks).get().then((tasks) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return tasks
          .where((t) =>
              t.deletedAt == null &&
              !t.completed &&
              t.dueDate != null &&
              t.dueDate!.isBefore(yesterday))
          .toList();
    });
  }
}
