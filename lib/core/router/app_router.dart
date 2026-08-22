import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/editor/pages/note_editor_page.dart';
import '../../features/graph/pages/graph_page.dart';
import '../../features/notes/pages/notes_list_page.dart';
import '../../features/notes/pages/tag_management_page.dart';
import '../../features/notes/pages/trash_page.dart';
import '../../features/search/pages/search_page.dart';
import '../../features/settings/pages/performance_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/sync/pages/github_login_page.dart';
import '../../features/sync/pages/sync_settings_page.dart';

/// 应用路由配置
///
/// 使用 go_router 声明式路由，支持深链接和嵌套路由。
/// 路由路径常量通过 [AppRouter] 静态属性暴露。
class AppRouter {
  AppRouter._();

  /// 路由路径常量
  static const String home = '/';
  static const String editor = '/editor';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String graph = '/graph';
  static const String githubLogin = '/github-login';
  static const String syncSettings = '/sync-settings';
  static const String trash = '/trash';
  static const String tagManagement = '/tags';
  static const String performance = '/performance';

  /// 构建 GoRouter 配置
  static GoRouter get router => _router;

  static final GoRouter _router = createRouter();

  /// 创建独立的 GoRouter 实例
  ///
  /// 测试中调用此方法可避免单例路由状态在测试间互相影响。
  static GoRouter createRouter() => GoRouter(
        initialLocation: home,
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const NotesListPage(),
          ),
          GoRoute(
            path: editor,
            builder: (context, state) => NoteEditorPage(
              noteId: state.extra as String?,
            ),
          ),
          GoRoute(
            path: search,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: graph,
            builder: (context, state) => const GraphPage(),
          ),
          GoRoute(
            path: githubLogin,
            builder: (context, state) => const GitHubLoginPage(),
          ),
          GoRoute(
            path: syncSettings,
            builder: (context, state) => const SyncSettingsPage(),
          ),
          GoRoute(
            path: trash,
            builder: (context, state) => const TrashPage(),
          ),
          GoRoute(
            path: tagManagement,
            builder: (context, state) => const TagsManagementPage(),
          ),
          GoRoute(
            path: performance,
            builder: (context, state) => const PerformancePage(),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('页面不存在')),
          body: Center(
              child: Text('404: ${state.error?.message ?? "Unknown route"}')),
        ),
      );
}
