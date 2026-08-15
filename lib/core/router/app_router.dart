import 'package:flutter/material.dart';

import '../../features/editor/pages/note_editor_page.dart';
import '../../features/graph/pages/graph_page.dart';
import '../../features/notes/pages/notes_list_page.dart';
import '../../features/notes/pages/trash_page.dart';
import '../../features/search/pages/search_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/sync/pages/github_login_page.dart';
import '../../features/sync/pages/sync_settings_page.dart';

/// 应用路由配置
///
/// 使用 Flutter 内置命名路由。后续 Week 3 引入 go_router 后
/// 可平滑迁移至声明式路由方案。
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

  /// 路由表生成
  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const NotesListPage(),
        editor: (context) => NoteEditorPage(
              noteId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        search: (_) => const SearchPage(),
        settings: (_) => const SettingsPage(),
        graph: (_) => const GraphPage(),
        githubLogin: (_) => const GitHubLoginPage(),
        syncSettings: (_) => const SyncSettingsPage(),
        trash: (_) => const TrashPage(),
      };

  /// 生成路由（支持转场动画）
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder == null) {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('页面不存在')),
          body: const Center(child: Text('404')),
        ),
      );
    }
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }
}
