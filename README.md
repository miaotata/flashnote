# 闪念笔记 FlashNote

> 快速捕捉转瞬即逝的想法 — 智能提醒 + 任务可视化 + 想法整合

**Android** · **iOS** · **Web** | Flutter 跨平台 | 纯本地 SQLite | Cupertino UI 风格

---

## 功能

| 模块 | 功能 |
|------|------|
| **快速记录** | 文本输入、语音录音、图片附件、摇一摇触发 |
| **智能提醒** | 时间提醒（每天/每周/工作日重复）、位置围栏、延迟 10 分钟、未完成持续提醒 |
| **任务可视化** | 艾森豪威尔四象限、优先级颜色标记（红/橙/绿）、每日焦点（上限可配） |
| **想法整合** | `[[反向链接]]` 自动关联、标签系统、全文搜索、聚合视图 |
| **数据管理** | 软删除 + 30 天回收站、纯本地存储、设置持久化 |
| **主题** | 跟随系统 / 浅色 / 深色切换 |

## 技术栈

| 层 | 选型 |
|----|------|
| 框架 | Flutter 3.x (Dart) |
| 数据库 | drift (SQLite ORM) |
| 状态管理 | Riverpod |
| UI | Cupertino (iOS 风格) |
| 通知 | flutter_local_notifications |
| 位置 | geolocator |
| 语音 | 原生录音 |
| 传感器 | sensors_plus |

## 快速开始

```bash
# 安装依赖
flutter pub get

# 连接设备后运行
flutter run

# 构建 APK
flutter build apk --debug

# Web 开发
flutter run -d web-server --web-port=8080
```

## 项目结构

```
lib/
├── main.dart                    # 入口 + 全局 Provider
├── app.dart                     # 4 Tab 导航
├── core/theme/                  # 颜色常量 + 主题定义
├── data/
│   ├── database/database.dart   # 6 张表 Drift 定义
│   ├── repositories/            # 数据仓库层
│   └── services/                # 通知 / 位置 / 录音 / 摇一摇
├── features/
│   ├── capture/                 # 快速记录（文本 + 语音 + 图片）
│   ├── reminder/                # 智能提醒（时间 + 位置 + 重复）
│   ├── task_board/              # 四象限 + 每日焦点 + 任务卡片
│   ├── integration/             # 标签聚合 + [[反向链接]] + 搜索
│   └── settings/                # 设置页
└── shared/widgets/              # 共享组件
```

## 数据模型

```
Note ──┬── Task ──── Reminder
       └── Tag (多对多)
       └── Backlink (自引用 [[...]])
```

## License

MIT
