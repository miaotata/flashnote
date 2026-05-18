import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/capture/capture_screen.dart';
import 'features/task_board/task_board_screen.dart';
import 'features/integration/tag_collection_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/providers/settings_provider.dart';
import 'data/services/shake_detector.dart';
import 'features/reminder/providers/reminder_provider.dart';
import 'main.dart';

class FlashNoteApp extends ConsumerWidget {
  const FlashNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoApp(
      title: '闪念笔记',
      debugShowCheckedModeBanner: false,
      home: const _ThemedMainTabs(),
    );
  }
}

class _ThemedMainTabs extends ConsumerWidget {
  const _ThemedMainTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    Widget child = const MainTabs();

    if (themeMode == 'light') {
      child = CupertinoTheme(
        data: AppTheme.lightTheme,
        child: child,
      );
    } else if (themeMode == 'dark') {
      child = CupertinoTheme(
        data: AppTheme.darkTheme,
        child: child,
      );
    }

    return child;
  }
}

class MainTabs extends ConsumerStatefulWidget {
  const MainTabs({super.key});

  @override
  ConsumerState<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends ConsumerState<MainTabs> {
  final _tabController = CupertinoTabController();
  ShakeDetector? _shakeDetector;
  Timer? _persistentCheckTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _shakeDetector = ShakeDetector(
        onShake: () => _tabController.index = 0,
      )..start();
    }
    _persistentCheckTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => ref.read(checkPersistentRemindersProvider),
    );
    Future.microtask(() => ref.read(checkPersistentRemindersProvider));
    Future.microtask(() => _purgeOldDeleted(ref));
  }

  @override
  void dispose() {
    _shakeDetector?.stop();
    _persistentCheckTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _purgeOldDeleted(WidgetRef ref) {
    ref.read(noteRepoProvider).purgeOldDeleted();
    ref.read(taskRepoProvider).purgeOldDeleted();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_pencil),
            activeIcon: Icon(CupertinoIcons.square_pencil_fill),
            label: '记录',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: '看板',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tags),
            activeIcon: Icon(CupertinoIcons.tags_solid),
            label: '聚合',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear_alt),
            activeIcon: Icon(CupertinoIcons.gear_alt_fill),
            label: '设置',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const CaptureScreen();
          case 1:
            return const TaskBoardScreen();
          case 2:
            return const TagCollectionScreen();
          case 3:
            return const SettingsScreen();
          default:
            return const CaptureScreen();
        }
      },
    );
  }
}
