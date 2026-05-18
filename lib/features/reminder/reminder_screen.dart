import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/reminder_provider.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  final int taskId;
  final String taskTitle;

  const ReminderScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedHour = 9;
  int _selectedMinute = 0;
  String _repeatMode = 'once'; // once, daily, weekly, weekdays
  bool _isPersistent = false;

  static const _repeatOptions = [
    ('once', '仅一次', CupertinoIcons.clock),
    ('daily', '每天', CupertinoIcons.today),
    ('weekly', '每周', CupertinoIcons.calendar),
    ('weekdays', '工作日', CupertinoIcons.briefcase),
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final reminder =
        await ref.read(reminderForTaskProvider(widget.taskId).future);
    if (reminder != null && mounted) {
      setState(() {
        _isPersistent = reminder.isPersistent;
      });
    }
  }

  DateTime get _scheduledTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
        _selectedMinute,
      );

  Future<void> _save() async {
    if (_scheduledTime.isBefore(DateTime.now())) return;

    await ref.read(createTimeReminderProvider((
      taskId: widget.taskId,
      time: _scheduledTime,
      title: widget.taskTitle,
      repeatMode: _repeatMode,
    )).future);

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('提醒已设置'),
          content: Text(_repeatLabel()),
        ),
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  String _repeatLabel() {
    if (_repeatMode == 'once') {
      return '${_dateLabel()} ${_timeLabel()} 提醒一次';
    }
    final mode = _repeatOptions.firstWhere((o) => o.$1 == _repeatMode).$2;
    return '$_timeLabel $mode提醒';
  }

  String _dateLabel() {
    final now = DateTime.now();
    final diff = _selectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == 2) return '后天';
    return '${_selectedDate.month}月${_selectedDate.day}日';
  }

  String _timeLabel() {
    return '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final reminderAsync = ref.watch(reminderForTaskProvider(widget.taskId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('设置提醒'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _scheduledTime.isAfter(DateTime.now()) ? _save : null,
          child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 任务标题
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondarySystemBackground, context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.bell, size: 18, color: CupertinoColors.systemBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.taskTitle, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── 重复模式 ─────────────
            const Text('重复', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _repeatOptions.map((opt) {
                final selected = _repeatMode == opt.$1;
                return GestureDetector(
                  onTap: () => setState(() => _repeatMode = opt.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? CupertinoColors.systemBlue.withValues(alpha: 0.15)
                          : CupertinoDynamicColor.resolve(
                              CupertinoColors.secondarySystemBackground, context),
                      borderRadius: BorderRadius.circular(20),
                      border: selected
                          ? Border.all(color: CupertinoColors.systemBlue, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.$3,
                            size: 16,
                            color: selected ? CupertinoColors.systemBlue : CupertinoColors.secondaryLabel),
                        const SizedBox(width: 4),
                        Text(opt.$2,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? CupertinoColors.systemBlue : null)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ─── 日期选择（仅一次/每周时显示）─────
            if (_repeatMode != 'daily' && _repeatMode != 'weekdays') ...[
              const Text('日期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondarySystemBackground, context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 快捷日期按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickDateButton(
                            label: '明天',
                            days: 1,
                            selectedDate: _selectedDate,
                            onSelect: (d) => setState(() => _selectedDate = d),
                          ),
                          _QuickDateButton(
                            label: '后天',
                            days: 2,
                            selectedDate: _selectedDate,
                            onSelect: (d) => setState(() => _selectedDate = d),
                          ),
                          _QuickDateButton(
                            label: '下周',
                            days: 7,
                            selectedDate: _selectedDate,
                            onSelect: (d) => setState(() => _selectedDate = d),
                          ),
                        ],
                      ),
                      // 手动选日期
                      SizedBox(
                        height: 160,
                        child: CupertinoDatePicker(
                          key: ValueKey(_selectedDate),
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: _selectedDate,
                          minimumDate: DateTime.now(),
                          maximumDate: DateTime.now().add(const Duration(days: 365)),
                          onDateTimeChanged: (d) => setState(() => _selectedDate = d),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── 时间选择 ─────────────
            const Text('时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondarySystemBackground, context),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 预览行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_repeatMode != 'daily' && _repeatMode != 'weekdays')
                        Text('${_dateLabel()} ', style: const TextStyle(fontSize: 15)),
                      Text(_timeLabel(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text(_repeatOptions.firstWhere((o) => o.$1 == _repeatMode).$2,
                          style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: DateTime(2024, 1, 1, _selectedHour, _selectedMinute),
                      minuteInterval: 5,
                      onDateTimeChanged: (d) => setState(() {
                        _selectedHour = d.hour;
                        _selectedMinute = d.minute;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── 持久提醒 ─────────────
            Container(
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondarySystemBackground, context),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('未完成持续提醒', style: TextStyle(fontSize: 16)),
                        Text(
                          '开启后每天 9:00 自动检查未完成任务',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isPersistent,
                    onChanged: (v) => setState(() => _isPersistent = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 已有提醒 ─────────────
            reminderAsync.when(
              data: (reminder) {
                if (reminder == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('当前提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.time, size: 20, color: CupertinoColors.systemBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reminder.type == 'time' ? '时间提醒' : '位置提醒',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                if (reminder.isPersistent)
                                  const Text('持续提醒已开启',
                                      style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel)),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Text('延迟 10分钟', style: TextStyle(fontSize: 13)),
                            onPressed: () => _snooze(reminder.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _snooze(int reminderId) async {
    await ref.read(snoozeReminderProvider(reminderId).future);
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text('已延迟'),
          content: Text('10 分钟后再次提醒'),
        ),
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }
}

// ─── 快捷日期按钮 ──────────────────────

class _QuickDateButton extends StatelessWidget {
  final String label;
  final int days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _QuickDateButton({
    required this.label,
    required this.days,
    required this.selectedDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final target = DateTime.now().add(Duration(days: days));
    final targetDay = DateTime(target.year, target.month, target.day);
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isSelected = targetDay == selectedDay;

    return GestureDetector(
      onTap: () => onSelect(target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.systemBlue.withValues(alpha: 0.12)
              : CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? CupertinoColors.systemBlue : CupertinoColors.label.resolveFrom(context))),
      ),
    );
  }
}
