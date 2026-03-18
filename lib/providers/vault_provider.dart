import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 保险库安全设置状态
class VaultSettings {
  final bool hideSecretsDefault;
  final bool confirmBeforeCopy;

  const VaultSettings({
    this.hideSecretsDefault = true,
    this.confirmBeforeCopy = true,
  });

  VaultSettings copyWith({
    bool? hideSecretsDefault,
    bool? confirmBeforeCopy,
  }) {
    return VaultSettings(
      hideSecretsDefault: hideSecretsDefault ?? this.hideSecretsDefault,
      confirmBeforeCopy: confirmBeforeCopy ?? this.confirmBeforeCopy,
    );
  }
}

/// 保险库设置 Notifier
class VaultSettingsNotifier extends AsyncNotifier<VaultSettings> {
  static const String _hideSecretsKey = 'hide_secrets_default';
  static const String _confirmBeforeCopyKey = 'confirm_before_copy';

  @override
  Future<VaultSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final hideSecrets = prefs.getBool(_hideSecretsKey) ?? true;
    final confirmCopy = prefs.getBool(_confirmBeforeCopyKey) ?? true;

    return VaultSettings(
      hideSecretsDefault: hideSecrets,
      confirmBeforeCopy: confirmCopy,
    );
  }

  /// 切换"默认隐藏密钥"设置
  Future<void> toggleHideSecrets() async {
    final current = state.value ?? const VaultSettings();
    final newValue = !current.hideSecretsDefault;

    state = AsyncData(current.copyWith(hideSecretsDefault: newValue));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideSecretsKey, newValue);
  }

  /// 切换"复制前二次确认"设置
  Future<void> toggleConfirmCopy() async {
    final current = state.value ?? const VaultSettings();
    final newValue = !current.confirmBeforeCopy;

    state = AsyncData(current.copyWith(confirmBeforeCopy: newValue));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_confirmBeforeCopyKey, newValue);
  }
}

/// 保险库设置 Provider
final vaultProvider = AsyncNotifierProvider<VaultSettingsNotifier, VaultSettings>(() {
  return VaultSettingsNotifier();
});
