import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../models/note_type.dart';
import '../../providers/filter_provider.dart';
import '../../providers/notes_provider.dart';
import '../common/search_bar.dart' as custom;

class NoteFilterPanel extends ConsumerWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;

  const NoteFilterPanel({
    super.key,
    required this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final tagsAsync = ref.watch(allTagsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索栏
          custom.SearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 24),

          // 类型筛选
          _buildSectionTitle('类型'),
          const SizedBox(height: 12),
          _buildTypeFilters(ref, filterState),
          const SizedBox(height: 24),

          // 标签筛选
          _buildSectionTitle('标签'),
          const SizedBox(height: 12),
          tagsAsync.when(
            data: (tags) => _buildTagFilters(ref, filterState, tags),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('加载失败'),
          ),
          const SizedBox(height: 24),

          // 快捷筛选
          _buildSectionTitle('快捷筛选'),
          const SizedBox(height: 12),
          _buildQuickFilters(ref, filterState),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTypeFilters(WidgetRef ref, FilterState filterState) {
    return Column(
      children: NoteType.values.map((type) {
        final isSelected = filterState.selectedType == type;
        return _buildFilterItem(
          icon: type.icon,
          label: type.label,
          color: type.color,
          isSelected: isSelected,
          onTap: () {
            ref.read(filterProvider.notifier).selectType(type);
          },
        );
      }).toList(),
    );
  }

  Widget _buildFilterItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textMuted),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilters(WidgetRef ref, FilterState filterState, List<String> tags) {
    if (tags.isEmpty) {
      return const Text(
        '暂无标签',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isSelected = filterState.selectedTag == tag;
        return FilterChip(
          label: Text('#$tag'),
          selected: isSelected,
          onSelected: (_) {
            ref.read(filterProvider.notifier).selectTag(isSelected ? null : tag);
          },
          selectedColor: AppColors.primary.withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
          ),
          side: BorderSide(color: AppColors.border),
        );
      }).toList(),
    );
  }

  Widget _buildQuickFilters(WidgetRef ref, FilterState filterState) {
    return Column(
      children: [
        _buildFilterItem(
          icon: Icons.star_outline,
          label: '收藏',
          color: AppColors.warning,
          isSelected: filterState.showFavorites,
          onTap: () {
            ref.read(filterProvider.notifier).toggleFavorites();
          },
        ),
        const SizedBox(height: 8),
        _buildFilterItem(
          icon: Icons.archive_outlined,
          label: '已归档',
          color: AppColors.textSecondary,
          isSelected: filterState.showArchived,
          onTap: () {
            ref.read(filterProvider.notifier).toggleArchived();
          },
        ),
        if (filterState.hasFilters) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              ref.read(filterProvider.notifier).clearFilters();
              searchController.clear();
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('清除筛选'),
          ),
        ],
      ],
    );
  }
}