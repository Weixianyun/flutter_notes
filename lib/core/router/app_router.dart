import 'package:flutter/material.dart';

import '../../features/editor/pages/note_editor_page.dart';
import '../../features/notes/pages/notes_list_page.dart';

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

  /// 路由表生成
  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const NotesListPage(),
        editor: (context) => NoteEditorPage(
              noteId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        // 以下路由为占位，后续 Week 逐步实现
        search: (_) => const _PlaceholderPage(title: '搜索'),
        settings: (_) => const _PlaceholderPage(title: '设置'),
      };

  /// 生成路由（支持转场动画）
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder == null) {
      return MaterialPageRoute(
        builder: (_) => const _PlaceholderPage(title: '未知页面'),
      );
    }
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }
}

/// 占位页面（后续替换为真实页面）
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — 即将实现',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
