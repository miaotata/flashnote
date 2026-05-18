import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/database/database.dart';
import 'data/repositories/note_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/tag_repository.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/services/notification_service.dart';

// ─── 数据库 ───────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// ─── 数据仓库（全局共享）─────────────

final noteRepoProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref.watch(databaseProvider));
});

final taskRepoProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(databaseProvider));
});

final tagRepoProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.watch(databaseProvider));
});

final reminderRepoProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(ref.watch(databaseProvider));
});

// ─── 服务 ────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().initialize();
  } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FlashNoteApp(),
    ),
  );
}
