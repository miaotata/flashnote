import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'deleted_items_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('设置'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),

            // ─── 任务设置 ──────────────────
            _sectionTitle('任务设置'),
            CupertinoFormSection.insetGrouped(
              header: const Text('调整每日焦点可标记的任务数量'),
              children: [
                _buildDailyFocusRow(context, ref),
              ],
            ),
            const SizedBox(height: 8),

            // ─── 外观设置 ──────────────────
            _sectionTitle('外观'),
            CupertinoFormSection.insetGrouped(
              header: const Text('选择主题模式'),
              children: [
                _buildThemeRow(context, ref),
              ],
            ),
            const SizedBox(height: 8),

            // ─── 提醒设置 ──────────────────
            _sectionTitle('提醒设置'),
            CupertinoFormSection.insetGrouped(
              header: const Text('控制通知和默认提醒时间'),
              children: [
                _buildNotificationRow(context, ref),
                _buildReminderTimeRow(context, ref),
              ],
            ),
            const SizedBox(height: 8),

            // ─── 排序设置 ──────────────────
            _sectionTitle('排序'),
            CupertinoFormSection.insetGrouped(
              header: const Text('设置看板任务排序方式'),
              children: [
                _buildSortRow(context, ref),
              ],
            ),
            const SizedBox(height: 8),

            // ─── 数据管理 ──────────────────
            _sectionTitle('数据管理'),
            CupertinoFormSection.insetGrouped(
              children: [
                _buildDeletedRow(context, ref),
                _buildClearDataRow(context, ref),
              ],
            ),
            const SizedBox(height: 8),

            // ─── 关于 ─────────────────────
            _sectionTitle('关于'),
            CupertinoFormSection.insetGrouped(
              header: const Text('闪念笔记 FlashNote'),
              children: [
                _buildInfoRow('版本', '1.0.0'),
                _buildInfoRow('数据存储', '纯本地 (SQLite)'),
                _buildInfoRow('平台', 'Android / iOS / Web'),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return CupertinoListTile(
      title: Text(label),
      trailing: Text(value, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
    );
  }

  // ─── 每日焦点 ──────────────────────

  Widget _buildDailyFocusRow(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(dailyFocusLimitProvider);

    return CupertinoListTile(
      title: const Text('每日焦点上限'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: limit > 1
                ? () => ref.read(dailyFocusLimitProvider.notifier).state = limit - 1
                : null,
            child: Icon(CupertinoIcons.minus_circle, size: 22,
                color: limit > 1 ? null : CupertinoColors.systemGrey3),
          ),
          Text('$limit',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.label, context),
              )),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: limit < 5
                ? () => ref.read(dailyFocusLimitProvider.notifier).state = limit + 1
                : null,
            child: Icon(CupertinoIcons.plus_circle, size: 22,
                color: limit < 5 ? null : CupertinoColors.systemGrey3),
          ),
        ],
      ),
    );
  }

  // ─── 主题选择 ──────────────────────

  Widget _buildThemeRow(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return CupertinoListTile(
      title: const Text('主题模式'),
      trailing: CupertinoSegmentedControl<String>(
        children: const {
          'system': Text('跟随系统', style: TextStyle(fontSize: 12)),
          'light': Text('浅色', style: TextStyle(fontSize: 12)),
          'dark': Text('深色', style: TextStyle(fontSize: 12)),
        },
        groupValue: currentMode,
        onValueChanged: (v) {
          ref.read(themeModeProvider.notifier).setMode(v);
        },
      ),
    );
  }

  // ─── 通知开关 ──────────────────────

  Widget _buildNotificationRow(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationsEnabledProvider);

    return CupertinoListTile(
      title: const Text('启用通知'),
      trailing: CupertinoSwitch(
        value: enabled,
        onChanged: (v) =>
            ref.read(notificationsEnabledProvider.notifier).state = v,
      ),
    );
  }

  // ─── 默认提醒时间 ──────────────────

  Widget _buildReminderTimeRow(BuildContext context, WidgetRef ref) {
    final hour = ref.watch(defaultReminderHourProvider);
    final minute = ref.watch(defaultReminderMinuteProvider);

    return CupertinoListTile(
      title: const Text('默认提醒时间'),
      trailing: GestureDetector(
        onTap: () => _showTimePicker(context, ref, hour, minute),
        child: Text(
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 17),
        ),
      ),
      onTap: () => _showTimePicker(context, ref, hour, minute),
    );
  }

  void _showTimePicker(BuildContext context, WidgetRef ref, int hour, int minute) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 240,
        padding: const EdgeInsets.only(top: 6),
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemBackground, context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2024, 1, 1, hour, minute),
                onDateTimeChanged: (dt) {
                  ref.read(defaultReminderHourProvider.notifier).state = dt.hour;
                  ref.read(defaultReminderMinuteProvider.notifier).state = dt.minute;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 排序方式 ──────────────────────

  Widget _buildSortRow(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(taskSortModeProvider);

    return CupertinoListTile(
      title: const Text('排序方式'),
      trailing: GestureDetector(
        onTap: () => _showSortPicker(context, ref, mode),
        child: Text(_sortLabel(mode),
            style: const TextStyle(fontSize: 14, color: CupertinoColors.activeBlue)),
      ),
      onTap: () => _showSortPicker(context, ref, mode),
    );
  }

  void _showSortPicker(BuildContext context, WidgetRef ref, String mode) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('排序方式'),
        actions: [
          _sortAction(context, ref, 'created', '创建时间'),
          _sortAction(context, ref, 'updated', '编辑时间'),
          _sortAction(context, ref, 'priority', '重要程度'),
          _sortAction(context, ref, 'urgency', '紧急程度'),
          _sortAction(context, ref, 'completed', '完成时间'),
          _sortAction(context, ref, 'manual', '手动排序'),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _sortAction(BuildContext context, WidgetRef ref, String value, String label) {
    return CupertinoActionSheetAction(
      onPressed: () {
        ref.read(taskSortModeProvider.notifier).setMode(value);
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (ref.read(taskSortModeProvider) == value)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.checkmark_alt, size: 16),
            ),
        ],
      ),
    );
  }

  String _sortLabel(String mode) {
    switch (mode) {
      case 'created':
        return '创建时间';
      case 'updated':
        return '编辑时间';
      case 'priority':
        return '重要程度';
      case 'urgency':
        return '紧急程度';
      case 'completed':
        return '完成时间';
      case 'manual':
        return '手动排序';
      default:
        return '创建时间';
    }
  }

  // ─── 最近删除 ──────────────────────

  Widget _buildDeletedRow(BuildContext context, WidgetRef ref) {
    return CupertinoListTile(
      title: const Text('最近删除'),
      trailing: const Icon(CupertinoIcons.chevron_right,
          size: 18, color: CupertinoColors.tertiaryLabel),
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (_) => const DeletedItemsScreen()));
      },
    );
  }

  // ─── 清空数据 ──────────────────────

  Widget _buildClearDataRow(BuildContext context, WidgetRef ref) {
    return CupertinoListTile(
      title: const Text('清空所有数据', style: TextStyle(color: CupertinoColors.systemRed)),
      trailing: const Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed, size: 20),
      onTap: () => _confirmClear(context, ref),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('清空所有数据'),
        content: const Text('此操作不可恢复，将删除所有笔记、任务、标签和提醒。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(clearAllDataProvider.future);
    }
  }
}
