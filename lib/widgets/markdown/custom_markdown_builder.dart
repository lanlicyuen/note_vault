import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'notion_code_block.dart';

/// 自定义 Markdown 渲染器
/// 支持 Notion 风格的代码块展示
class CustomMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;
  final MarkdownTapLinkCallback? onTapLink;

  const CustomMarkdown({
    super.key,
    required this.data,
    this.styleSheet,
    this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseMarkdown(context),
    );
  }

  List<Widget> _parseMarkdown(BuildContext context) {
    final List<Widget> widgets = [];
    
    // 使用正则表达式匹配代码块 ```language\ncode\n```
    final codeBlockRegex = RegExp(r'```(\w*)\n([\s\S]*?)```');
    final matches = codeBlockRegex.allMatches(data);
    
    int lastIndex = 0;
    for (final match in matches) {
      // 添加代码块之前的文本
      if (match.start > lastIndex) {
        final beforeText = data.substring(lastIndex, match.start);
        if (beforeText.trim().isNotEmpty) {
          widgets.add(
            MarkdownBody(
              data: beforeText,
              styleSheet: styleSheet,
              onTapLink: onTapLink,
            ),
          );
        }
      }
      
      // 添加代码块
      final language = match.group(1);
      final code = match.group(2) ?? '';
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: NotionCodeBlock(
            code: code.trim(),
            language: language,
          ),
        ),
      );
      
      lastIndex = match.end;
    }
    
    // 添加最后一个代码块之后的文本
    if (lastIndex < data.length) {
      final afterText = data.substring(lastIndex);
      if (afterText.trim().isNotEmpty) {
        widgets.add(
          MarkdownBody(
            data: afterText,
            styleSheet: styleSheet,
            onTapLink: onTapLink,
          ),
        );
      }
    }
    
    // 如果没有代码块，直接使用 MarkdownBody
    if (widgets.isEmpty) {
      return [
        MarkdownBody(
          data: data,
          styleSheet: styleSheet,
          onTapLink: onTapLink,
        ),
      ];
    }
    
    return widgets;
  }
}
