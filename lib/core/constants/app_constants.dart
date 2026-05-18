class AppConstants {
  AppConstants._();

  static const appName = '闪念笔记';
  static const maxDailyFocus = 3;
  static const snoozeMinutes = 10;
  static const geofenceRadiusMeters = 200;

  // 笔记类型
  static const noteTypeText = 'text';
  static const noteTypeVoice = 'voice';

  // 任务优先级
  static const priorityHigh = 'high';
  static const priorityMedium = 'medium';
  static const priorityLow = 'low';

  // 紧急/重要枚举
  static const flagUrgent = 'urgent';
  static const flagNotUrgent = 'not_urgent';
  static const flagImportant = 'important';
  static const flagNotImportant = 'not_important';

  // 提醒类型
  static const reminderTypeTime = 'time';
  static const reminderTypeLocation = 'location';
}
