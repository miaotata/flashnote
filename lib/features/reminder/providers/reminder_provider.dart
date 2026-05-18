import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../data/database/database.dart';
import '../../../main.dart';

// 所有任务 ID 集合（已有提醒的）
final reminderTaskIdsProvider = FutureProvider<Set<int>>((ref) async {
  final reminders = await ref.watch(reminderRepoProvider).getAll();
  return reminders.map((r) => r.taskId).toSet();
});

// 所有提醒列表
final remindersProvider = FutureProvider<List<ReminderData>>((ref) {
  return ref.watch(reminderRepoProvider).getAll();
});

// 某任务的提醒
final reminderForTaskProvider =
    FutureProvider.family<ReminderData?, int>((ref, taskId) {
  return ref.watch(reminderRepoProvider).getByTaskId(taskId);
});

// 创建时间提醒
final createTimeReminderProvider =
    FutureProvider.family<void, ({int taskId, DateTime time, String title, String repeatMode})>(
  (ref, params) async {
    final reminderRepo = ref.watch(reminderRepoProvider);
    final notif = ref.watch(notificationServiceProvider);

    final existing = await reminderRepo.getByTaskId(params.taskId);
    if (existing != null) {
      try {
        await notif.cancel(existing.id);
      } catch (_) {}
      await reminderRepo.deleteByTaskId(params.taskId);
    }

    final config = jsonEncode({
      'time': params.time.toIso8601String(),
      'repeat': params.repeatMode,
      'hour': params.time.hour,
      'minute': params.time.minute,
    });

    await reminderRepo.insert(
      RemindersCompanion(
        taskId: Value(params.taskId),
        type: const Value('time'),
        configJson: Value(config),
        createdAt: Value(DateTime.now()),
      ),
    );

    final newReminder = await reminderRepo.getByTaskId(params.taskId);
    if (newReminder != null) {
      // 根据重复模式调度多个通知
      if (params.repeatMode == 'daily') {
        // 每天：未来 30 天
        for (var i = 0; i < 30; i++) {
          final d = params.time.add(Duration(days: i));
          await notif.scheduleTimeReminder(
            id: newReminder.id + i,
            title: '每日提醒',
            body: params.title,
            scheduledTime: d,
            payload: params.taskId.toString(),
          );
        }
      } else if (params.repeatMode == 'weekly') {
        for (var i = 0; i < 12; i++) {
          final d = params.time.add(Duration(days: i * 7));
          await notif.scheduleTimeReminder(
            id: newReminder.id + i,
            title: '每周提醒',
            body: params.title,
            scheduledTime: d,
            payload: params.taskId.toString(),
          );
        }
      } else if (params.repeatMode == 'weekdays') {
        var count = 0;
        var d = params.time;
        while (count < 40) {
          final wd = d.weekday;
          if (wd >= DateTime.monday && wd <= DateTime.friday) {
            await notif.scheduleTimeReminder(
              id: newReminder.id + count,
              title: '工作日提醒',
              body: params.title,
              scheduledTime: d,
              payload: params.taskId.toString(),
            );
            count++;
          }
          d = d.add(const Duration(days: 1));
        }
      } else {
        // once
        await notif.scheduleTimeReminder(
          id: newReminder.id,
          title: '任务提醒',
          body: params.title,
          scheduledTime: params.time,
          payload: params.taskId.toString(),
        );
      }
    }
    ref.invalidate(reminderTaskIdsProvider);
    ref.invalidate(remindersProvider);
  },
);

// 延迟提醒
final snoozeReminderProvider =
    FutureProvider.family<void, int>((ref, reminderId) async {
  final reminderRepo = ref.watch(reminderRepoProvider);
  final notif = ref.watch(notificationServiceProvider);
  final reminder = await reminderRepo
      .getAll()
      .then((list) => list.where((r) => r.id == reminderId).firstOrNull);

  if (reminder != null) {
    final taskRepo = ref.watch(taskRepoProvider);
    final task = await taskRepo
        .getAll()
        .then((list) => list.where((t) => t.id == reminder.taskId).firstOrNull);

    await notif.snooze(
      oldId: reminder.id,
      newId: reminder.id + 1000,
      title: '任务提醒',
      body: task != null ? '任务 #${task.id}' : '延迟提醒',
      payload: reminder.taskId.toString(),
    );

    await reminderRepo.incrementSnooze(reminder.id);
    ref.invalidate(reminderTaskIdsProvider);
  }
});

// 持续提醒检查
final checkPersistentRemindersProvider = FutureProvider<void>((ref) async {
  final taskRepo = ref.watch(taskRepoProvider);
  final reminderRepo = ref.watch(reminderRepoProvider);
  final notif = ref.watch(notificationServiceProvider);

  final overdue = await taskRepo.getOverdueIncomplete();

  for (final task in overdue) {
    final reminder = await reminderRepo.getByTaskId(task.id);
    if (reminder != null && reminder.isPersistent) {
      try {
        await notif.scheduleTimeReminder(
          id: reminder.id + 2000,
          title: '未完成任务',
          body: '昨天有未完成的任务，请查看',
          scheduledTime: DateTime.now()
              .add(const Duration(hours: 8))
              .copyWith(hour: 9, minute: 0),
        );
      } catch (_) {}
    }
  }
});
