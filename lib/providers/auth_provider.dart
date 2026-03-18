import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 认证状态
class AuthState {
  final bool isAuthenticated;
  final String? username;

  const AuthState({
    this.isAuthenticated = false,
    this.username,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? username,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
    );
  }
}

/// 认证 Notifier
class AuthNotifier extends AsyncNotifier<AuthState> {
  static const String _authKey = 'is_authenticated';
  static const String _usernameKey = 'username';
  
  // 简单的本地认证 - 阶段 1 使用
  // 默认账号密码，可后续扩展
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin123';

  @override
  Future<AuthState> build() async {
    // 检查本地存储的认证状态
    final prefs = await SharedPreferences.getInstance();
    bool isAuthenticated = prefs.getBool(_authKey) ?? false;
    String? username = prefs.getString(_usernameKey);

    // 开发环境：首次启动时自动登录
    if (!isAuthenticated) {
      await prefs.setBool(_authKey, true);
      await prefs.setString(_usernameKey, defaultUsername);
      isAuthenticated = true;
      username = defaultUsername;
    }

    return AuthState(
      isAuthenticated: isAuthenticated,
      username: username,
    );
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    state = const AsyncLoading();
    
    // 简单验证 - 阶段 1
    if (username == defaultUsername && password == defaultPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authKey, true);
      await prefs.setString(_usernameKey, username);
      
      state = AsyncData(AuthState(
        isAuthenticated: true,
        username: username,
      ));
      return true;
    }
    
    state = AsyncData(const AuthState());
    return false;
  }

  /// 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_usernameKey);
    
    state = const AsyncData(AuthState());
  }

  /// 检查是否已登录
  bool get isAuthenticated => state.value?.isAuthenticated ?? false;
}

/// 认证 Provider
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});