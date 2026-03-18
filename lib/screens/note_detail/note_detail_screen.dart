import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/note.dart';
import '../../models/note_type.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/markdown/custom_markdown_builder.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(noteId));

    return noteAsync.when(
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('未找到')),
            body: const Center(child: Text('笔记不存在')),
          );
        }
        return _buildDetail(context, ref, note);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Note note) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('详情'),
        actions: [
          IconButton(
            icon: Icon(
              note.isFavorite ? Icons.star : Icons.star_border,
              color: note.isFavorite ? AppColors.warning : null,
            ),
            onPressed: () {
              ref.read(notesProvider.notifier).toggleFavorite(note);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/note/$noteId/edit'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, ref, note);
              } else if (value == 'archive') {
                ref.read(notesProvider.notifier).toggleArchived(note);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('归档'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text('删除', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // 元信息
            _buildMetaInfo(note),
            const SizedBox(height: 24),

            // Markdown 内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: CustomMarkdown(
                data: note.content,
              ),
            ),

            // Secret Value
            if (note.type == NoteType.secret && note.value != null) ...[
              const SizedBox(height: 24),
              _buildSecretValue(note),
            ],

            // Command Value
            if (note.type == NoteType.command && note.value != null) ...[
              const SizedBox(height: 24),
              _buildCommandValue(context, note),
            ],

            // Link
            if (note.type == NoteType.link && note.url != null) ...[
              const SizedBox(height: 24),
              _buildLinkValue(context, note),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaInfo(Note note) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        // 类型
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: note.type.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: note.type.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(note.type.icon, size: 16, color: note.type.color),
              const SizedBox(width: 6),
              Text(
                note.type.label,
                style: TextStyle(color: note.type.color, fontSize: 13),
              ),
            ],
          ),
        ),

        // 标签
        ...note.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '#$tag',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            )),

        // 时间
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            '更新于 ${DateFormat('yyyy-MM-dd HH:mm').format(note.updatedAt)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSecretValue(Note note) {
    return _SecretValueField(value: note.value!);
  }

  Widget _buildCommandValue(BuildContext context, Note note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '命令',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.commandType.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.commandType.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.terminal_outlined, size: 20, color: AppColors.commandType),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  note.value!,
                  style: TextStyle(
                    color: AppColors.commandType,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20),
                color: AppColors.commandType,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: note.value!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('命令已复制')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkValue(BuildContext context, Note note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '链接',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.linkType.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.linkType.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.link_outlined, size: 20, color: AppColors.linkType),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  note.url!,
                  style: TextStyle(
                    color: AppColors.linkType,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20),
                color: AppColors.linkType,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: note.url!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('链接已复制')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${note.title}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(notesProvider.notifier).delete(note.id);
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _SecretValueField extends StatefulWidget {
  final String value;

  const _SecretValueField({required this.value});

  @override
  State<_SecretValueField> createState() => _SecretValueFieldState();
}

class _SecretValueFieldState extends State<_SecretValueField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '密钥',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secretType.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secretType.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.key_outlined, size: 20, color: AppColors.secretType),
              const SizedBox(width: 12),
              Expanded(
                child: _isVisible
                    ? SelectableText(
                        widget.value,
                        style: TextStyle(
                          color: AppColors.secretType,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        '•' * 16,
                        style: TextStyle(
                          color: AppColors.secretType,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
              ),
              IconButton(
                icon: Icon(
                  _isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                color: AppColors.secretType,
                onPressed: () {
                  setState(() => _isVisible = !_isVisible);
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20),
                color: AppColors.secretType,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密钥已复制')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}