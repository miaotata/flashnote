class Task {
  final int id;
  final int noteId;
  final String priority; // 'high' | 'medium' | 'low'
  final String urgency; // 'urgent' | 'not_urgent'
  final String importance; // 'important' | 'not_important'
  final bool isDailyFocus;
  final bool completed;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.noteId,
    required this.priority,
    required this.urgency,
    required this.importance,
    required this.isDailyFocus,
    required this.completed,
    this.completedAt,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 象限位置: 0=紧急且重要, 1=不紧急但重要, 2=紧急但不重要, 3=不紧急不重要
  int get quadrantIndex {
    final isUrgent = urgency == 'urgent';
    final isImportant = importance == 'important';
    if (isUrgent && isImportant) return 0;
    if (!isUrgent && isImportant) return 1;
    if (isUrgent && !isImportant) return 2;
    return 3;
  }
}
