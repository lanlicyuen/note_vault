import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/colors.dart';
import '../../models/note.dart';
import '../../models/note_type.dart';
import '../../models/command_group.dart';
import '../../providers/notes_provider.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditScreen({
    super.key,
    this.noteId,
  });

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _valueController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagsController = TextEditingController();

  NoteType _selectedType = NoteType.note;
  CommandGroup? _commandGroup;
  bool _isLoading = false;
  bool _isPreview = false;
  Note? _existingNote;

  bool get isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    final note = await ref.read(noteProvider(widget.noteId!).future);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
        _titleController.text = note.title;
        _contentController.text = note.content;
        _valueController.text = note.value ?? '';
        _urlController.text = note.url ?? '';
        _tagsController.text = note.tags.join(', ');
        _selectedType = note.type;
        _commandGroup = note.commandGroup;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _valueController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final note = Note(
        id: widget.noteId ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        type: _selectedType,
        content: _contentController.text,
        value: _valueController.text.isNotEmpty ? _valueController.text : null,
        url: _urlController.text.isNotEmpty ? _urlController.text : null,
        tags: tags,
        isFavorite: _existingNote?.isFavorite ?? false,
        isArchived: _existingNote?.isArchived ?? false,
        commandGroup: _selectedType == NoteType.command ? _commandGroup : null,
        createdAt: _existingNote?.createdAt ?? now,
        updatedAt: now,
      );

      // 等待保存完成
      await ref.read(notesProvider.notifier).save(note);

      // 保存成功后返回
      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
      }
    } catch (e) {
      // 保存失败，显示错误提示
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(isEditing ? '编辑笔记' : '新建笔记'),
        actions: [
          if (_selectedType == NoteType.note)
            TextButton.icon(
              onPressed: () => setState(() => _isPreview = !_isPreview),
              icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
              label: Text(_isPreview ? '编辑' : '预览'),
            ),
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isLoading ? '保存中...' : '保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 类型选择
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // 标题
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '输入笔记标题',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 内容
              if (!_isPreview) ...[
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    hintText: '支持 Markdown 格式',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入内容';
                    }
                    return null;
                  },
                ),
              ] else ...[
                _buildMarkdownPreview(),
              ],
              const SizedBox(height: 16),

              // 类型特定字段
              if (_selectedType == NoteType.secret) _buildSecretFields(),
              if (_selectedType == NoteType.command) _buildCommandFields(),
              if (_selectedType == NoteType.link) _buildLinkFields(),

              // 标签
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: '标签',
                  hintText: '用逗号分隔，如: api, server, production',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '类型',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: NoteType.values.map((type) {
            final isSelected = _selectedType == type;
            return InkWell(
              onTap: () => setState(() => _selectedType = type),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? type.color.withOpacity(0.15) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? type.color : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 18, color: isSelected ? type.color : AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected ? type.color : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSecretFields() {
    return Column(
      children: [
        TextFormField(
          controller: _valueController,
          decoration: const InputDecoration(
            labelText: '密钥值',
            hintText: 'API Key / Token / 密码',
            prefixIcon: Icon(Icons.key_outlined),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCommandFields() {
    return Column(
      children: [
        TextFormField(
          controller: _valueController,
          decoration: const InputDecoration(
            labelText: '命令',
            hintText: '输入要执行的命令',
            prefixIcon: Icon(Icons.terminal_outlined),
          ),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 16),

        // 命令组选择
        Text(
          '命令组',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CommandGroup.values.map((group) {
            final isSelected = _commandGroup == group;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(group.icon, size: 16, color: isSelected ? group.color : AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(group.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _commandGroup = group),
              selectedColor: group.color.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? group.color : AppColors.textSecondary,
              ),
              side: BorderSide(color: isSelected ? group.color : AppColors.border),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLinkFields() {
    return Column(
      children: [
        TextFormField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: '链接地址',
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link_outlined),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMarkdownPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SelectableText(
        _contentController.text,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}