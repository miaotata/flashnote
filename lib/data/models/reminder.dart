class Reminder {
  final int id;
  final int taskId;
  final String type; // 'time' | 'location'
  final String configJson; // JSON string
  final int snoozeCount;
  final bool isPersistent;
  final DateTime? lastTriggered;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.taskId,
    required this.type,
    required this.configJson,
    required this.snoozeCount,
    required this.isPersistent,
    this.lastTriggered,
    required this.createdAt,
  });
}
