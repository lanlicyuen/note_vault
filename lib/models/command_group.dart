import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// 命令组枚举
enum CommandGroup {
  start('start', '启动', Icons.play_arrow_outlined),
  stop('stop', '停止', Icons.stop_outlined),
  restart('restart', '重启', Icons.refresh_outlined),
  delete('delete', '删除', Icons.delete_outline),
  deploy('deploy', '部署', Icons.rocket_launch_outlined),
  backup('backup', '备份', Icons.backup_outlined);

  final String value;
  final String label;
  final IconData icon;

  const CommandGroup(this.value, this.label, this.icon);

  /// 获取命令组对应的颜色
  Color get color {
    switch (this) {
      case CommandGroup.start:
        return AppColors.commandStart;
      case CommandGroup.stop:
        return AppColors.commandStop;
      case CommandGroup.restart:
        return AppColors.commandRestart;
      case CommandGroup.delete:
        return AppColors.commandDelete;
      case CommandGroup.deploy:
        return AppColors.commandDeploy;
      case CommandGroup.backup:
        return AppColors.commandBackup;
    }
  }

  /// 从字符串值获取枚举
  static CommandGroup? fromValue(String? value) {
    if (value == null) return null;
    return CommandGroup.values.firstWhere(
      (group) => group.value == value,
      orElse: () => CommandGroup.start,
    );
  }
}