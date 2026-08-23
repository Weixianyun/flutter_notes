import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/editor/pages/note_editor_page.dart';
import '../../features/graph/pages/graph_page.dart';
import '../../features/notes/pages/notes_list_page.dart';
import '../../features/notes/pages/tag_management_page.dart';
import '../../features/notes/pages/trash_page.dart';
import '../../features/search/pages/search_page.dart';
import '../../features/settings/pages/developer_options_page.dart';
import '../../features/settings/pages/performance_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/sync/pages/conflict_resolution_page.dart';
import '../../features/sync/pages/github_login_page.dart';
import '../../features/sync/pages/sync_settings_page.dart';
import '../design/app_page_transitions.dart';

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
  static const String developerOptions = '/developer-options';

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
            pageBuilder: (context, state) {
              final extra = state.extra;
              Widget child;
              if (extra is EditorArgs) {
                child = NoteEditorPage(
                  noteId: extra.noteId,
                  highlight: extra.highlight,
                );
              } else {
                // 兼容旧的 String? 形式（笔记列表 / 图谱直接跳转）
                child = NoteEditorPage(noteId: extra as String?);
              }
              return AppPageTransitions.sharedAxisPage(
                key: state.pageKey,
                child: child,
              );
            },
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
            path: '/conflict-resolution',
            builder: (context, state) => const ConflictResolutionPage(),
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
          GoRoute(
            path: developerOptions,
            builder: (context, state) => const DeveloperOptionsPage(),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('页面不存在')),
          body: Center(
              child: Text('404: ${state.error?.message ?? "Unknown route"}')),
        ),
      );
}

/// 跳转到编辑器时使用的参数包
///
/// - [noteId]: 笔记 ID，新建场景为 null
/// - [highlight]: 进入后要选中的关键词（来自搜索结果，可选）
class EditorArgs {
  const EditorArgs({this.noteId, this.highlight});
  final String? noteId;
  final String? highlight;
}
