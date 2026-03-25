import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/note_detail/note_detail_screen.dart';
import '../screens/note_edit/note_edit_screen.dart';
import '../screens/vault/vault_manager_screen.dart';

/// 路由配置 Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isLoginRoute = state.matchedLocation == '/login';
      
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      
      if (isAuthenticated && isLoginRoute) {
        return '/';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/note/new',
        name: 'note-new',
        builder: (context, state) => const NoteEditScreen(noteId: null),
      ),
      GoRoute(
        path: '/note/:id',
        name: 'note-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoteDetailScreen(noteId: id);
        },
      ),
      GoRoute(
        path: '/note/:id/edit',
        name: 'note-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoteEditScreen(noteId: id);
        },
      ),
      GoRoute(
        path: '/vault',
        name: 'vault',
        builder: (context, state) => const VaultManagerScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('页面未找到: ${state.error}'),
      ),
    ),
  );
});