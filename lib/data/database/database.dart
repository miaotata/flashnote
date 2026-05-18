import 'package:drift/drift.dart';
import 'connection/connection_native.dart'
    if (dart.library.js_interop) 'connection/connection_web.dart';

part 'database.g.dart';

// ─── 表定义 ────────────────────────────────────────

@DataClassName('NoteData')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get audioPath => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TaskData')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().references(Notes, #id)();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get urgency => text().withDefault(const Constant('not_urgent'))();
  TextColumn get importance =>
      text().withDefault(const Constant('important'))();
  BoolColumn get isDailyFocus => boolean().withDefault(const Constant(false))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TagData')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#007AFF'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 笔记-标签 多对多关联表
@DataClassName('NoteTagData')
class NoteTags extends Table {
  IntColumn get noteId => integer().references(Notes, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}

@DataClassName('ReminderData')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();
  TextColumn get type => text()(); // 'time' or 'location'
  TextColumn get configJson => text()(); // JSON 配置
  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
  BoolColumn get isPersistent =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastTriggered => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 反向链接表
@DataClassName('BacklinkData')
class Backlinks extends Table {
  IntColumn get sourceNoteId => integer().references(Notes, #id)();
  IntColumn get targetNoteId => integer().references(Notes, #id)();

  @override
  Set<Column> get primaryKey => {sourceNoteId, targetNoteId};
}

// ─── 数据库 ────────────────────────────────────────

@DriftDatabase(tables: [
  Notes,
  Tasks,
  Tags,
  NoteTags,
  Reminders,
  Backlinks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createQueryExecutor());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            await m.addColumn(notes, notes.imagePath);
          }
          if (from <= 2) {
            await m.addColumn(notes, notes.deletedAt);
            await m.addColumn(tasks, tasks.deletedAt);
            await m.addColumn(tasks, tasks.sortOrder);
          }
        },
      );
}
