import '../models/note.dart';
import '../models/note_type.dart';

/// Note 仓库抽象接口
/// UI 层只依赖此接口，不依赖具体实现
abstract class NoteRepository {
  /// 获取所有 Note
  Future<List<Note>> getAll();

  /// 根据 ID 获取 Note
  Future<Note?> getById(String id);

  /// 保存 Note (新建或更新)
  Future<void> save(Note note);

  /// 删除 Note
  Future<void> delete(String id);

  /// 搜索 Note
  Future<List<Note>> search(String query);

  /// 按类型获取 Note
  Future<List<Note>> getByType(NoteType type);

  /// 按标签获取 Note
  Future<List<Note>> getByTag(String tag);

  /// 获取收藏的 Note
  Future<List<Note>> getFavorites();

  /// 获取所有标签
  Future<List<String>> getAllTags();

  /// 批量保存
  Future<void> saveAll(List<Note> notes);

  /// 清空所有笔记
  Future<void> clearAll();

  /// 恢复默认演示数据
  Future<void> resetToDefaults();
}