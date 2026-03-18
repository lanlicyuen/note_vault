import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/note.dart';
import '../models/note_type.dart';
import '../repositories/note_repository.dart';
import '../repositories/local_note_repository.dart';

/// Note Repository Provider
/// 阶段 1: 使用 LocalNoteRepository
/// 阶段 2: 切换到 ApiNoteRepository 时，只需修改这里
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return LocalNoteRepository();
});

/// 所有 Note 列表
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(() {
  return NotesNotifier();
});

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final repository = ref.read(noteRepositoryProvider);
    return repository.getAll();
  }

  /// 刷新列表
  Future<void> refresh() async {
    state = const AsyncLoading();
    final repository = ref.read(noteRepositoryProvider);
    state = AsyncData(await repository.getAll());
  }

  /// 保存 Note
  Future<void> save(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.save(note);
    
    // 直接更新状态，避免不必要的全量刷新
    final currentNotes = state.value ?? [];
    final index = currentNotes.indexWhere((n) => n.id == note.id);
    
    if (index >= 0) {
      // 更新现有 note
      final updatedNotes = [...currentNotes];
      updatedNotes[index] = note;
      updatedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncData(updatedNotes);
    } else {
      // 新增 note
      final updatedNotes = [note, ...currentNotes];
      updatedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncData(updatedNotes);
    }
  }

  /// 删除 Note
  Future<void> delete(String id) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.delete(id);
    
    // 直接更新状态，避免不必要的全量刷新
    final currentNotes = state.value ?? [];
    final updatedNotes = currentNotes.where((n) => n.id != id).toList();
    state = AsyncData(updatedNotes);
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
    await repository.save(updatedNote);
    
    // 直接更新状态，避免不必要的全量刷新
    final currentNotes = state.value ?? [];
    final index = currentNotes.indexWhere((n) => n.id == note.id);
    
    if (index >= 0) {
      final updatedNotes = [...currentNotes];
      updatedNotes[index] = updatedNote;
      state = AsyncData(updatedNotes);
    }
  }

  /// 切换归档状态
  Future<void> toggleArchived(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    final updatedNote = note.copyWith(isArchived: !note.isArchived);
    await repository.save(updatedNote);
    
    // 直接更新状态，避免不必要的全量刷新
    final currentNotes = state.value ?? [];
    
    if (updatedNote.isArchived) {
      // 归档后从列表中移除
      final updatedNotes = currentNotes.where((n) => n.id != note.id).toList();
      state = AsyncData(updatedNotes);
    } else {
      // 取消归档后添加到列表
      final index = currentNotes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        final updatedNotes = [...currentNotes];
        updatedNotes[index] = updatedNote;
        updatedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        state = AsyncData(updatedNotes);
      }
    }
  }

  /// 清空所有笔记
  Future<void> clearAll() async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.clearAll();
    await refresh();
  }

  /// 恢复默认演示数据
  Future<void> resetToDefaults() async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.resetToDefaults();
    await refresh();
  }

  /// 导出笔记为 JSON 字符串
  String exportJson() {
    final notes = state.value ?? [];
    return jsonEncode(notes.map((n) => n.toJson()).toList());
  }

  /// 从 JSON 字符串导入笔记
  Future<void> importJson(String jsonStr) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final notes = jsonList.map((json) => Note.fromJson(json)).toList();

      final repository = ref.read(noteRepositoryProvider);
      await repository.saveAll(notes);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

/// 单个 Note Provider
final noteProvider = FutureProvider.family<Note?, String>((ref, id) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getById(id);
});

/// 搜索结果 Provider
final searchResultsProvider = FutureProvider.family<List<Note>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.read(notesProvider).value ?? [];
  }
  final repository = ref.read(noteRepositoryProvider);
  return repository.search(query);
});

/// 按类型筛选 Provider
final notesByTypeProvider = FutureProvider.family<List<Note>, NoteType>((ref, type) async {
  final repository = ref.read(noteRepositoryProvider);
  return repository.getByType(type);
});

/// 按标签筛选 Provider
final notesByTagProvider = FutureProvider.family<List<Note>, String>((ref, tag) async {
  final repository = ref.read(noteRepositoryProvider);
  return repository.getByTag(tag);
});

/// 收藏的 Note Provider
final favoriteNotesProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.read(noteRepositoryProvider);
  return repository.getFavorites();
});

/// 所有标签 Provider
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(noteRepositoryProvider);
  return repository.getAllTags();
});