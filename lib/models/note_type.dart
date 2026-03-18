import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// Note 类型枚举
enum NoteType {
  note('note', '笔记', Icons.note_outlined),
  secret('secret', '密钥', Icons.key_outlined),
  command('command', '命令', Icons.terminal_outlined),
  link('link', '链接', Icons.link_outlined);

  final String value;
  final String label;
  final IconData icon;

  const NoteType(this.value, this.label, this.icon);

  /// 获取类型对应的颜色
  Color get color {
    switch (this) {
      case NoteType.note:
        return AppColors.noteType;
      case NoteType.secret:
        return AppColors.secretType;
      case NoteType.command:
        return AppColors.commandType;
      case NoteType.link:
        return AppColors.linkType;
    }
  }

  /// 从字符串值获取枚举
  static NoteType fromValue(String value) {
    return NoteType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NoteType.note,
    );
  }
}