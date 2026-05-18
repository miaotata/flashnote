import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._();

  // 优先级颜色
  static const priorityHigh = Color(0xFFFF3B30); // 红色
  static const priorityMedium = Color(0xFFFF9500); // 橙色
  static const priorityLow = Color(0xFF34C759); // 绿色

  // 四象限背景
  static const quadrantUrgentImportant = Color(0xFFFF3B30); // 红：紧急且重要
  static const quadrantNotUrgentImportant = Color(0xFF007AFF); // 蓝：不紧急但重要
  static const quadrantUrgentNotImportant = Color(0xFFFF9500); // 橙：紧急但不重要
  static const quadrantNotUrgentNotImportant = Color(0xFF8E8E93); // 灰：不紧急不重要

  // 标签默认颜色池
  static const tagColors = [
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF007AFF),
    Color(0xFF5856D6),
    Color(0xFFAF52DE),
    Color(0xFFFF2D55),
  ];

  // 每日焦点
  static const dailyFocusLimit = 3;
  static const dailyFocusBadge = Color(0xFFFFD60A); // 金色标记
}
