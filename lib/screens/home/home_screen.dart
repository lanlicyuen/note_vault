import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../models/note.dart';
import '../../models/note_type.dart';
import '../../providers/notes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filter_provider.dart';
import '../../widgets/banner/hero_banner.dart';
import '../../widgets/note/note_card.dart';
import '../../widgets/note/note_filter_panel.dart';
import '../../widgets/common/search_bar.dart' as custom;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isFilterExpanded = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部 Banner
              HeroBanner(
                onSettingsTap: () => context.push('/vault'),
              ),

              // 主内容区
              Expanded(
                child: isDesktop
                    ? _buildDesktopLayout()
                    : _buildMobileLayout(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/note/new'),
        child: const Icon(Icons.add),
      ).animate().fadeIn(delay: 500.ms).scale(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧筛选面板
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isFilterExpanded ? 280 : 0,
          child: _isFilterExpanded
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      right: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: NoteFilterPanel(
                    searchController: _searchController,
                    onSearchChanged: (query) {
                      ref.read(filterProvider.notifier).setSearchQuery(query);
                    },
                  ),
                )
              : null,
        ),

        // 右侧 Note 列表
        Expanded(
          child: _buildNoteList(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(16),
          child: custom.SearchBar(
            controller: _searchController,
            onChanged: (query) {
              ref.read(filterProvider.notifier).setSearchQuery(query);
            },
          ),
        ),

        // 类型筛选 Chips
        _buildTypeChips(),

        // Note 列表
        Expanded(
          child: _buildNoteList(),
        ),
      ],
    );
  }

  Widget _buildTypeChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTypeChip(null, '全部'),
          ...NoteType.values.map((type) => _buildTypeChip(type, type.label)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(NoteType? type, String label) {
    final filterState = ref.watch(filterProvider);
    final isSelected = filterState.selectedType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(filterProvider.notifier).selectType(type);
        },
        selectedColor: (type?.color ?? AppColors.primary).withOpacity(0.3),
        checkmarkColor: type?.color ?? AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? (type?.color ?? AppColors.primary) : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNoteList() {
    final filterState = ref.watch(filterProvider);
    final notesAsync = ref.watch(notesProvider);

    return notesAsync.when(
      data: (notes) {
        // 应用筛选
        var filteredNotes = _applyFilters(notes, filterState);

        if (filteredNotes.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(notesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoteCard(
                  note: note,
                  onTap: () => context.push('/note/${note.id}'),
                  onFavoriteToggle: () {
                    ref.read(notesProvider.notifier).toggleFavorite(note);
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: index * 50)),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }

  List<Note> _applyFilters(List<Note> notes, FilterState filter) {
    var result = notes;

    // 搜索筛选
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      result = result.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.content.toLowerCase().contains(query) ||
            n.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // 类型筛选
    if (filter.selectedType != null) {
      result = result.where((n) => n.type == filter.selectedType).toList();
    }

    // 标签筛选
    if (filter.selectedTag != null) {
      result = result.where((n) => n.tags.contains(filter.selectedTag)).toList();
    }

    // 收藏筛选
    if (filter.showFavorites) {
      result = result.where((n) => n.isFavorite).toList();
    }

    return result;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无笔记',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮创建新笔记',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}