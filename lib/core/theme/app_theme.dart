import 'package:flutter/cupertino.dart';

/// 跟随系统的 Cupertino 主题配置
class AppTheme {
  AppTheme._();

  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF007AFF),
      scaffoldBackgroundColor: Color(0xFFF2F2F7),
      barBackgroundColor: Color(0xFFF2F2F7),
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          color: Color(0xFF1C1C1E),
        ),
      ),
    );
  }

  static CupertinoThemeData get darkTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF0A84FF),
      scaffoldBackgroundColor: Color(0xFF000000),
      barBackgroundColor: Color(0xFF1C1C1E),
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
