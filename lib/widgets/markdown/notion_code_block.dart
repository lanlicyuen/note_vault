import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/colors.dart';

/// Notion 风格的代码块组件
class NotionCodeBlock extends StatelessWidget {
  final String code;
  final String? language;

  const NotionCodeBlock({
    super.key,
    required this.code,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 代码块头部（语言标签 + 复制按钮）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
              border: const Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 语言标签
                if (language != null && language!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        _getLanguageIcon(language!),
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        language!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Code',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                // 复制按钮
                _CopyButton(code: code),
              ],
            ),
          ),
          // 代码内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              code,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLanguageIcon(String language) {
    final lang = language.toLowerCase();
    if (lang.contains('bash') || lang.contains('shell')) {
      return Icons.terminal;
    } else if (lang.contains('dart')) {
      return Icons.code;
    } else if (lang.contains('python')) {
      return Icons.code;
    } else if (lang.contains('js') || lang.contains('javascript')) {
      return Icons.javascript;
    } else if (lang.contains('html')) {
      return Icons.html;
    } else if (lang.contains('css')) {
      return Icons.css;
    } else if (lang.contains('json')) {
      return Icons.data_object;
    } else if (lang.contains('sql')) {
      return Icons.storage;
    } else {
      return Icons.code;
    }
  }
}

/// 复制按钮组件
class _CopyButton extends StatefulWidget {
  final String code;

  const _CopyButton({required this.code});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    
    if (mounted) {
      setState(() => _copied = true);
      
      // 2秒后恢复按钮状态
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _copied = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _copied 
              ? AppColors.success.withOpacity(0.15)
              : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _copied 
                ? AppColors.success.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_circle : Icons.copy,
              size: 14,
              color: _copied ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? '已复制' : '复制',
              style: TextStyle(
                color: _copied ? AppColors.success : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}