# Note Vault - 部署说明

## 环境要求

- Flutter SDK 3.x
- Chrome 浏览器 (Web 开发)
- Android Studio / Android SDK (Android 开发)

---

## 一、Flutter Web 本地运行

### 1. 启动开发服务器

```bash
cd d:\Dev\note_md
flutter run -d chrome
```

或者指定端口：

```bash
flutter run -d chrome --web-port=8080
```

### 2. 访问应用

浏览器会自动打开，或手动访问：
- http://localhost:端口号

---

## 二、Flutter Web 构建部署

### 1. 构建 Web 版本

```bash
cd d:\Dev\note_md
flutter build web
```

构建产物位于：`build/web/`

### 2. 部署到服务器

#### 方式 A: Nginx 部署

1. 将 `build/web/` 目录上传到服务器

2. Nginx 配置示例：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    root /var/www/note_vault;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

#### 方式 B: 静态托管

可以直接部署到：
- Vercel
- Netlify
- GitHub Pages
- Cloudflare Pages

只需将 `build/web/` 目录内容上传即可。

---

## 三、Android Debug APK 构建

### 1. 构建 Debug APK

```bash
cd d:\Dev\note_md
flutter build apk --debug
```

APK 文件位于：`build/app/outputs/flutter-apk/app-debug.apk`

### 2. 构建 Release APK

```bash
flutter build apk --release
```

### 3. 安装到设备

```bash
# 通过 USB 连接设备后
flutter install

# 或手动安装 APK
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 四、从 LocalNoteRepository 切换到 ApiNoteRepository

### 当前架构 (阶段 1)

```
┌─────────────────┐
│  Flutter UI     │
├─────────────────┤
│  Providers      │
├─────────────────┤
│ NoteRepository  │ ← 接口
│       ↓         │
│ LocalNoteRepo   │ ← 当前实现
│       ↓         │
│ SharedPreferences│
└─────────────────┘
```

### 未来架构 (阶段 2)

```
┌─────────────────┐
│  Flutter UI     │
├─────────────────┤
│  Providers      │
├─────────────────┤
│ NoteRepository  │ ← 接口 (不变)
│       ↓         │
│ ApiNoteRepo     │ ← 新实现
│       ↓         │
│  REST API       │
│       ↓         │
│  PostgreSQL     │
└─────────────────┘
```

### 切换步骤

#### 1. 创建 ApiNoteRepository

新建文件 `lib/repositories/api_note_repository.dart`:

```dart
import 'package:dio/dio.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import 'note_repository.dart';

class ApiNoteRepository implements NoteRepository {
  final Dio _dio;
  final String baseUrl;

  ApiNoteRepository({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  @override
  Future<List<Note>> getAll() async {
    final response = await _dio.get('/notes');
    return (response.data as List)
        .map((json) => Note.fromJson(json))
        .toList();
  }

  @override
  Future<Note?> getById(String id) async {
    try {
      final response = await _dio.get('/notes/$id');
      return Note.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> save(Note note) async {
    if (await getById(note.id) != null) {
      await _dio.put('/notes/${note.id}', data: note.toJson());
    } else {
      await _dio.post('/notes', data: note.toJson());
    }
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete('/notes/$id');
  }

  // ... 实现其他方法
}
```

#### 2. 修改 Provider

修改 `lib/providers/notes_provider.dart`:

```dart
// 阶段 1: 本地存储
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return LocalNoteRepository();
});

// 阶段 2: API 存储 (只需改这里)
// final noteRepositoryProvider = Provider<NoteRepository>((ref) {
//   return ApiNoteRepository(
//     baseUrl: 'https://api.yourserver.com/api/v1',
//   );
// });
```

#### 3. UI 层无需修改

因为 UI 层只依赖 `NoteRepository` 接口，所以切换实现后 UI 代码完全不需要改动。

---

## 五、后端 API 设计参考 (阶段 2)

### API 端点

```
GET    /api/v1/notes          # 获取所有笔记
GET    /api/v1/notes/:id      # 获取单个笔记
POST   /api/v1/notes          # 创建笔记
PUT    /api/v1/notes/:id      # 更新笔记
DELETE /api/v1/notes/:id      # 删除笔记
GET    /api/v1/notes/search   # 搜索笔记
GET    /api/v1/tags           # 获取所有标签
```

### PostgreSQL 表结构

```sql
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL,
    content TEXT,
    value TEXT,
    url VARCHAR(500),
    tags TEXT[],
    is_favorite BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    command_group VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notes_type ON notes(type);
CREATE INDEX idx_notes_tags ON notes USING GIN(tags);
CREATE INDEX idx_notes_favorite ON notes(is_favorite);
```

---

## 六、常用命令速查

| 命令 | 说明 |
|------|------|
| `flutter doctor` | 检查环境 |
| `flutter pub get` | 安装依赖 |
| `flutter run -d chrome` | Web 开发运行 |
| `flutter build web` | 构建 Web |
| `flutter build apk --debug` | 构建 Debug APK |
| `flutter build apk --release` | 构建 Release APK |
| `flutter clean` | 清理构建缓存 |
| `flutter analyze` | 代码分析 |

---

## 七、默认登录账号

- 用户名: `admin`
- 密码: `admin123`

可在 `lib/providers/auth_provider.dart` 中修改。