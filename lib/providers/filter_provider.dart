import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_type.dart';

/// 筛选状态
class FilterState {
  final String searchQuery;
  final NoteType? selectedType;
  final String? selectedTag;
  final bool showFavorites;
  final bool showArchived;

  const FilterState({
    this.searchQuery = '',
    this.selectedType,
    this.selectedTag,
    this.showFavorites = false,
    this.showArchived = false,
  });

  FilterState copyWith({
    String? searchQuery,
    NoteType? selectedType,
    String? selectedTag,
    bool? showFavorites,
    bool? showArchived,
    bool clearType = false,
    bool clearTag = false,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
      showFavorites: showFavorites ?? this.showFavorites,
      showArchived: showArchived ?? this.showArchived,
    );
  }

  /// 是否有任何筛选条件
  bool get hasFilters {
    return searchQuery.isNotEmpty ||
        selectedType != null ||
        selectedTag != null ||
        showFavorites ||
        showArchived;
  }

  /// 清除所有筛选
  FilterState clear() {
    return const FilterState();
  }
}

/// 筛选 Provider
final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  /// 设置搜索查询
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 选择类型
  void selectType(NoteType? type) {
    if (type == state.selectedType) {
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(selectedType: type);
    }
  }

  /// 选择标签
  void selectTag(String? tag) {
    if (tag == state.selectedTag) {
      state = state.copyWith(clearTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
  }

  /// 切换收藏筛选
  void toggleFavorites() {
    state = state.copyWith(showFavorites: !state.showFavorites);
  }

  /// 切换归档筛选
  void toggleArchived() {
    state = state.copyWith(showArchived: !state.showArchived);
  }

  /// 清除所有筛选
  void clearFilters() {
    state = state.clear();
  }
}