import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../models/command_group.dart';
import 'note_repository.dart';

/// 本地 Note 仓库实现
/// 阶段 1: 使用 SharedPreferences 存储
/// 未来可切换到 ApiNoteRepository 连接 PostgreSQL
class LocalNoteRepository implements NoteRepository {
  static const String _storageKey = 'notes_data';
  
  List<Note> _notes = [];
  bool _initialized = false;

  /// 初始化，加载存储的数据
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        _notes = jsonList.map((json) => Note.fromJson(json)).toList();
      } catch (e) {
        // 如果解析失败，使用 Mock 数据
        _notes = _getMockNotes();
        await _saveToStorage();
      }
    } else {
      // 首次使用，加载 Mock 数据
      _notes = _getMockNotes();
      await _saveToStorage();
    }
    
    _initialized = true;
  }

  /// 保存到本地存储
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  /// Mock 数据 - 用于开发和测试
  List<Note> _getMockNotes() {
    final now = DateTime.now();
    return [
      Note(
        id: '1',
        title: 'API Key - OpenAI',
        type: NoteType.secret,
        content: 'OpenAI API 密钥，用于 GPT-4 和 DALL-E 调用',
        value: 'sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
        tags: ['api', 'openai', 'ai'],
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      Note(
        id: '2',
        title: '服务器启动命令',
        type: NoteType.command,
        content: '启动生产环境服务器',
        value: 'docker-compose -f docker-compose.prod.yml up -d --build',
        tags: ['docker', 'server', 'production'],
        commandGroup: CommandGroup.start,
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
      Note(
        id: '3',
        title: 'PostgreSQL 连接信息',
        type: NoteType.secret,
        content: '生产环境数据库连接配置',
        value: 'postgresql://user:password@db.example.com:5432/production',
        tags: ['database', 'postgresql', 'production'],
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      Note(
        id: '4',
        title: 'Nginx 重启命令',
        type: NoteType.command,
        content: '重启 Nginx 反向代理',
        value: 'sudo systemctl restart nginx',
        tags: ['nginx', 'server'],
        commandGroup: CommandGroup.restart,
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      Note(
        id: '5',
        title: 'Flutter 开发备忘',
        type: NoteType.note,
        content: '''# Flutter 常用命令

## 创建项目
```bash
flutter create my_app
```

## 运行项目
```bash
flutter run
```

## 构建 Web
```bash
flutter build web
```

## 构建 APK
```bash
flutter build apk --debug
```
''',
        tags: ['flutter', 'dart', 'dev'],
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Note(
        id: '6',
        title: 'GitHub 仓库地址',
        type: NoteType.link,
        content: '主要项目仓库',
        url: 'https://github.com/username/my-project',
        tags: ['github', 'repository'],
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Note(
        id: '7',
        title: '数据库备份命令',
        type: NoteType.command,
        content: 'PostgreSQL 数据库备份',
        value: 'pg_dump -U postgres -d production > backup_\$(date +%Y%m%d).sql',
        tags: ['database', 'backup', 'postgresql'],
        commandGroup: CommandGroup.backup,
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Note(
        id: '8',
        title: 'AWS Access Key',
        type: NoteType.secret,
        content: 'AWS IAM 用户访问密钥',
        value: 'AKIAIOSFODNN7EXAMPLE',
        tags: ['aws', 'cloud', 'credentials'],
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  Future<List<Note>> getAll() async {
    await _ensureInitialized();
    return _notes.where((n) => !n.isArchived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Note?> getById(String id) async {
    await _ensureInitialized();
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> save(Note note) async {
    await _ensureInitialized();
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    await _saveToStorage();
  }

  @override
  Future<void> delete(String id) async {
    await _ensureInitialized();
    _notes.removeWhere((n) => n.id == id);
    await _saveToStorage();
  }

  @override
  Future<List<Note>> search(String query) async {
    await _ensureInitialized();
    final lowerQuery = query.toLowerCase();
    return _notes.where((n) {
      return !n.isArchived &&
          (n.title.toLowerCase().contains(lowerQuery) ||
              n.content.toLowerCase().contains(lowerQuery) ||
              n.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)));
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<Note>> getByType(NoteType type) async {
    await _ensureInitialized();
    return _notes.where((n) => !n.isArchived && n.type == type).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<Note>> getByTag(String tag) async {
    await _ensureInitialized();
    return _notes
        .where((n) => !n.isArchived && n.tags.contains(tag))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<Note>> getFavorites() async {
    await _ensureInitialized();
    return _notes.where((n) => !n.isArchived && n.isFavorite).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<String>> getAllTags() async {
    await _ensureInitialized();
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  @override
  Future<void> saveAll(List<Note> notes) async {
    await _ensureInitialized();
    for (final note in notes) {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = note;
      } else {
        _notes.add(note);
      }
    }
    await _saveToStorage();
  }

  @override
  Future<void> clearAll() async {
    await _ensureInitialized();
    _notes.clear();
    await _saveToStorage();
  }

  @override
  Future<void> resetToDefaults() async {
    _initialized = false;
    await _ensureInitialized();
    await _saveToStorage();
  }
}