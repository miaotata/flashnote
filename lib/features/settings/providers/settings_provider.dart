import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';

// 每日焦点上限（1-5）
final dailyFocusLimitProvider = StateProvider<int>((ref) => 3);

// 默认启用通知
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

// 默认提醒时间（小时，0-23）
final defaultReminderHourProvider = StateProvider<int>((ref) => 9);
final defaultReminderMinuteProvider = StateProvider<int>((ref) => 0);

// 主题模式
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, String>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

class ThemeModeNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_prefs.getString('theme_mode') ?? 'system');

  void setMode(String mode) {
    state = mode;
    _prefs.setString('theme_mode', mode);
  }
}

// 任务排序模式
final taskSortModeProvider =
    StateNotifierProvider<TaskSortModeNotifier, String>((ref) {
  return TaskSortModeNotifier(ref.watch(sharedPreferencesProvider));
});

class TaskSortModeNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  TaskSortModeNotifier(this._prefs)
      : super(_prefs.getString('task_sort_mode') ?? 'created');

  void setMode(String mode) {
    state = mode;
    _prefs.setString('task_sort_mode', mode);
  }
}

// 清空所有数据
final clearAllDataProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.delete(db.reminders).go();
  await db.delete(db.noteTags).go();
  await db.delete(db.backlinks).go();
  await db.delete(db.tasks).go();
  await db.delete(db.tags).go();
  await db.delete(db.notes).go();
});
