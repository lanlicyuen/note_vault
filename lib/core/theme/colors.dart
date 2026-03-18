import 'package:flutter/material.dart';

/// 科技感深色主题配色方案
class AppColors {
  AppColors._();

  // 主色调
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // 背景色
  static const Color background = Color(0xFF0F0F23); // 深色背景
  static const Color surface = Color(0xFF1A1A2E); // 卡片背景
  static const Color surfaceVariant = Color(0xFF16213E); // 次级背景

  // 边框/分割
  static const Color border = Color(0xFF2D2D44);
  static const Color divider = Color(0xFF252540);

  // 文字
  static const Color textPrimary = Color(0xFFE4E4E7);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // 强调色
  static const Color accent = Color(0xFF22D3EE); // Cyan
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red

  // Note 类型颜色
  static const Color noteType = Color(0xFF6366F1); // 笔记 - Indigo
  static const Color secretType = Color(0xFFEC4899); // 密钥 - Pink
  static const Color commandType = Color(0xFF22D3EE); // 命令 - Cyan
  static const Color linkType = Color(0xFF10B981); // 链接 - Green

  // 命令组颜色
  static const Color commandStart = Color(0xFF10B981); // 启动 - Green
  static const Color commandStop = Color(0xFFEF4444); // 停止 - Red
  static const Color commandRestart = Color(0xFFF59E0B); // 重启 - Amber
  static const Color commandDelete = Color(0xFFDC2626); // 删除 - Dark Red
  static const Color commandDeploy = Color(0xFF8B5CF6); // 部署 - Purple
  static const Color commandBackup = Color(0xFF06B6D4); // 备份 - Cyan

  // 渐变
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 发光效果颜色
  static const Color glowPrimary = Color(0x406366F1);
  static const Color glowAccent = Color(0x4022D3EE);
}