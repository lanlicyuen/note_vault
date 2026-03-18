# Note Vault - 技术架构文档

## 1. 技术架构方案

### 1.1 核心技术栈
| 层级 | 技术选型 | 说明 |
|------|---------|------|
| UI 框架 | Flutter 3.x | 支持 Web + Android 共享 UI |
| UI 组件 | Material 3 | 深色主题、现代设计语言 |
| 状态管理 | Riverpod 2.x | 响应式、可测试、依赖注入 |
| 路由 | go_router | 声明式路由，支持深链接 |
| Markdown | flutter_markdown | 内容渲染 |
| 本地存储 | SharedPreferences + Hive | 轻量级本地持久化 |

### 1.2 分层架构

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Screens   │  │   Widgets   │  │   Providers     │  │
│  │  (页面)     │  │  (组件)     │  │  (状态管理)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                    Domain Layer                          │
│  ┌─────────────┐  ┌─────────────────────────────────┐   │
│  │   Models    │  │   Repository Interfaces         │   │
│  │  (数据模型) │  │   (抽象接口)                    │   │
│  └─────────────┘  └─────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                    Data Layer                            │
│  ┌───────────────────┐  ┌───────────────────────────┐   │
│  │ LocalRepository   │  │ ApiRepository (预留)      │   │
│  │ (本地存储实现)    │  │ (API + PostgreSQL 预留)   │   │
│  └───────────────────┘  └───────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 1.3 数据流向
```
User Action → Provider → Repository → Data Source
                  ↓
              UI Update ← Model ← Data
```

### 1.4 阶段演进策略
```
阶段 1 (当前)                    阶段 2 (未来)
┌─────────────────┐              ┌─────────────────┐
│  Flutter UI     │              │  Flutter UI     │
│  (Web/Android)  │              │  (不变)         │
├─────────────────┤              ├─────────────────┤
│  Providers      │              │  Providers      │
│  (不变)         │              │  (不变)         │
├─────────────────┤              ├─────────────────┤
│ NoteRepository  │              │ NoteRepository  │
│       ↓         │              │       ↓         │
│ LocalNoteRepo   │  ──切换──>   │ ApiNoteRepo     │
│       ↓         │              │       ↓         │
│ SharedPreferences│             │  REST API       │
│ / Hive          │              │       ↓         │
└─────────────────┘              │  PostgreSQL     │
                                 └─────────────────┘
```

---

## 2. 项目目录结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # App 配置 (Theme, Router)
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart       # Material 3 深色主题
│   │   └── colors.dart          # 科技感配色
│   ├── constants/
│   │   └── app_constants.dart   # 常量定义
│   └── utils/
│       ├── date_utils.dart      # 日期工具
│       └── clipboard_utils.dart # 剪贴板工具
│
├── models/
│   ├── note.dart                # Note 数据模型
│   ├── note_type.dart           # Note 类型枚举
│   └── command_group.dart       # 命令组枚举
│
├── repositories/
│   ├── note_repository.dart     # Note 仓库抽象接口
│   └── local_note_repository.dart  # 本地存储实现
│
├── providers/
│   ├── notes_provider.dart      # Note 状态管理
│   ├── auth_provider.dart       # 认证状态管理
│   └── filter_provider.dart     # 筛选状态管理
│
├── screens/
│   ├── login/
│   │   └── login_screen.dart    # 登录页
│   ├── home/
│   │   └── home_screen.dart     # 首页
│   ├── note_detail/
│   │   └── note_detail_screen.dart   # Note 详情页
│   └── note_edit/
│       └── note_edit_screen.dart     # Note 编辑页
│
├── widgets/
│   ├── common/
│   │   ├── app_scaffold.dart    # 通用脚手架
│   │   ├── search_bar.dart      # 搜索栏
│   │   └── empty_state.dart     # 空状态
│   ├── banner/
│   │   └── hero_banner.dart     # 顶部轮播 Banner
│   ├── note/
│   │   ├── note_card.dart       # Note 卡片
│   │   ├── note_list.dart       # Note 列表
│   │   ├── note_filter_panel.dart # 筛选面板
│   │   ├── secret_field.dart    # 密码字段(隐藏/显示)
│   │   ├── command_field.dart   # 命令字段(一键复制)
│   │   └── markdown_preview.dart # Markdown 预览
│   └── layout/
│       └── responsive_layout.dart # 响应式布局
│
└── router/
    └── app_router.dart          # go_router 路由配置
```

---

## 3. 页面结构草图

### 3.1 整体页面流程
```
┌──────────────┐     ┌──────────────┐
│  Splash      │ ──→ │   Login      │
│  (启动页)    │     │   (登录页)   │
└──────────────┘     └──────┬───────┘
                            │ 登录成功
                            ↓
                     ┌──────────────┐
                     │     Home     │
                     │   (首页)     │
                     └──────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              ↓             ↓             ↓
       ┌──────────┐  ┌──────────┐  ┌──────────┐
       │ Note详情 │  │ Note编辑 │  │  新建    │
       └──────────┘  └──────────┘  └──────────┘
```

### 3.2 首页布局 (桌面端)
```
┌─────────────────────────────────────────────────────────────┐
│  [Logo]  Note Vault              [搜索框]         [用户]   │  ← App Bar
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Hero Banner / 轮播区                    │   │  ← 顶部展示区
│  │     ●  ○  ○   [功能介绍轮播]                        │   │     (高度适中)
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌────────────────────────────────────┐  │
│  │   筛选面板    │  │                                    │  │
│  │              │  │                                    │  │
│  │  [搜索]      │  │     Note 列表                      │  │
│  │              │  │     ┌────────────────────────┐    │  │
│  │  类型:       │  │     │ Note Card              │    │  │
│  │  □ note      │  │     │ Title / Type / Tags    │    │  │
│  │  □ secret    │  │     └────────────────────────┘    │  │
│  │  □ command   │  │     ┌────────────────────────┐    │  │
│  │  □ link      │  │     │ Note Card              │    │  │
│  │              │  │     │ Title / Type / Tags    │    │  │
│  │  标签:       │  │     └────────────────────────┘    │  │
│  │  [tag1] [tag2]│  │                                    │  │
│  │              │  │     [+ 新建 Note]                  │  │
│  │  [收藏]      │  │                                    │  │
│  │  [已归档]    │  │                                    │  │
│  └──────────────┘  └────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 首页布局 (移动端)
```
┌─────────────────────┐
│  [≡] Note Vault [+] │  ← App Bar
├─────────────────────┤
│  [搜索框]           │
├─────────────────────┤
│  ┌───────────────┐  │
│  │  Banner 轮播  │  │  ← 顶部展示区
│  └───────────────┘  │
├─────────────────────┤
│  [筛选] [类型] [标签]│  ← 筛选栏
├─────────────────────┤
│  ┌───────────────┐  │
│  │  Note Card    │  │
│  └───────────────┘  │
│  ┌───────────────┐  │  ← Note 列表
│  │  Note Card    │  │
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │  Note Card    │  │
│  └───────────────┘  │
└─────────────────────┘
```

### 3.4 Note 详情页
```
┌─────────────────────────────────────────────────────────────┐
│  [← 返回]    Note 详情                    [编辑] [删除]    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ## Note Title                                              │
│  ─────────────────────                                      │
│  类型: secret    标签: [api] [key]     2024-01-15          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │  Markdown 内容预览                                  │   │
│  │                                                     │   │
│  │  - 支持代码高亮                                     │   │
│  │  - 支持表格                                         │   │
│  │  - 支持链接                                         │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Secret Value:                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ••••••••••••••••••                    [显示] [复制]│   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. 数据模型设计

### 4.1 Note 类型枚举
```dart
enum NoteType {
  note('note', '笔记', Icons.note),
  secret('secret', '密钥', Icons.key),
  command('command', '命令', Icons.terminal),
  link('link', '链接', Icons.link);

  final String value;
  final String label;
  final IconData icon;
  
  const NoteType(this.value, this.label, this.icon);
}
```

### 4.2 命令组枚举
```dart
enum CommandGroup {
  start('start', '启动'),
  stop('stop', '停止'),
  restart('restart', '重启'),
  delete('delete', '删除'),
  deploy('deploy', '部署'),
  backup('backup', '备份');

  final String value;
  final String label;
  
  const CommandGroup(this.value, this.label);
}
```

### 4.3 Note 数据模型
```dart
class Note {
  final String id;
  final String title;
  final NoteType type;
  final String content;        // Markdown 内容
  final String? value;         // secret 专用
  final String? url;           // 链接类型专用
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final CommandGroup? commandGroup;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    this.value,
    this.url,
    List<String>? tags,
    this.isFavorite = false,
    this.isArchived = false,
    this.commandGroup,
    required this.createdAt,
    required this.updatedAt,
  });

  // copyWith, fromJson, toJson 方法
}
```

### 4.4 Repository 接口设计
```dart
/// 抽象接口 - UI 层只依赖此接口
abstract class NoteRepository {
  Future<List<Note>> getAll();
  Future<Note?> getById(String id);
  Future<void> save(Note note);
  Future<void> delete(String id);
  Future<List<Note>> search(String query);
  Future<List<Note>> getByType(NoteType type);
  Future<List<Note>> getByTag(String tag);
  Future<List<Note>> getFavorites();
}

/// 本地实现 - 阶段 1 使用
class LocalNoteRepository implements NoteRepository {
  // SharedPreferences / Hive 实现
}

/// API 实现 - 阶段 2 预留
class ApiNoteRepository implements NoteRepository {
  // HTTP Client + REST API 实现
  // 连接 PostgreSQL 后端
}
```

---

## 5. MVP 开发顺序

### Phase 1: 项目骨架 (第二步)
- [ ] 1.1 创建 Flutter 项目
- [ ] 1.2 配置 pubspec.yaml 依赖
- [ ] 1.3 创建目录结构
- [ ] 1.4 配置 Material 3 深色主题
- [ ] 1.5 设置 go_router 路由
- [ ] 1.6 验证项目可运行

### Phase 2: 数据层 (第三步开始)
- [ ] 2.1 创建数据模型 (Note, NoteType, CommandGroup)
- [ ] 2.2 创建 NoteRepository 抽象接口
- [ ] 2.3 实现 LocalNoteRepository (Mock 数据)
- [ ] 2.4 创建 Providers (Riverpod)

### Phase 3: 登录功能
- [ ] 3.1 登录页 UI
- [ ] 3.2 简单本地认证逻辑
- [ ] 3.3 AuthProvider 状态管理
- [ ] 3.4 路由守卫

### Phase 4: 首页框架
- [ ] 4.1 顶部 Banner 轮播区
- [ ] 4.2 筛选面板
- [ ] 4.3 Note 列表区
- [ ] 4.4 响应式布局 (桌面/移动)

### Phase 5: Note 功能
- [ ] 5.1 Note 卡片组件
- [ ] 5.2 Note 详情页
- [ ] 5.3 Note 编辑页
- [ ] 5.4 新建 Note

### Phase 6: 高级功能
- [ ] 6.1 搜索功能
- [ ] 6.2 类型/标签筛选
- [ ] 6.3 收藏功能
- [ ] 6.4 Markdown 预览
- [ ] 6.5 Secret 隐藏/显示
- [ ] 6.6 Command 一键复制

### Phase 7: 持久化
- [ ] 7.1 SharedPreferences 存储
- [ ] 7.2 数据持久化测试

### Phase 8: 部署
- [ ] 8.1 Flutter Web 构建
- [ ] 8.2 Android Debug APK 构建
- [ ] 8.3 部署文档

---

## 6. 配色方案 (科技感深色主题)

```dart
// 主色调
const Color primaryColor      = Color(0xFF6366F1);  // Indigo
const Color primaryLight      = Color(0xFF818CF8);
const Color primaryDark       = Color(0xFF4F46E5);

// 背景色
const Color background        = Color(0xFF0F0F23);  // 深色背景
const Color surface           = Color(0xFF1A1A2E);  // 卡片背景
const Color surfaceVariant    = Color(0xFF16213E);  // 次级背景

// 边框/分割
const Color border            = Color(0xFF2D2D44);  // 边框色
const Color divider           = Color(0xFF252540);

// 文字
const Color textPrimary       = Color(0xFFE4E4E7);
const Color textSecondary     = Color(0xFFA1A1AA);
const Color textMuted         = Color(0xFF71717A);

// 强调色
const Color accent            = Color(0xFF22D3EE);  // Cyan
const Color success           = Color(0xFF10B981);  // Green
const Color warning           = Color(0xFFF59E0B);  // Amber
const Color error             = Color(0xFFEF4444);  // Red

// 类型颜色
const Color noteTypeColor     = Color(0xFF6366F1);  // 笔记 - Indigo
const Color secretTypeColor   = Color(0xFFEC4899);  // 密钥 - Pink
const Color commandTypeColor  = Color(0xFF22D3EE);  // 命令 - Cyan
const Color linkTypeColor     = Color(0xFF10B981);  // 链接 - Green
```

---

## 7. 未来扩展路径

### 从 LocalNoteRepository 切换到 ApiNoteRepository

```dart
// 阶段 1: 使用本地仓库
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return LocalNoteRepository();
});

// 阶段 2: 切换到 API 仓库 (只需改这一处)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return ApiNoteRepository(
    baseUrl: 'https://api.yourserver.com',
    httpClient: Dio(),
  );
});
```

UI 层代码完全不需要修改，因为它们只依赖 `NoteRepository` 接口。