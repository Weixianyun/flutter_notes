import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/router/app_router.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
import 'package:flutter_notes/services/service_providers.dart';

void main() {
  // 测试中每个 testWidgets 创建独立的内存数据库，抑制多重数据库警告
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// 测试用 override 列表
  Future<List<Override>> testOverrides() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ];
  }

  Future<void> pumpApp(WidgetTester tester) async {
    final overrides = await testOverrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          title: 'Flutter Notes',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          routerConfig: AppRouter.createRouter(),
        ),
      ),
    );
    // 等待数据库初始化和种子数据加载
    await tester.pumpAndSettle();
  }

  testWidgets('Notes list renders with title, FAB and tag filter', (tester) async {
    await pumpApp(tester);

    expect(find.text('Flutter Notes'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    // 数据库种子数据应渲染笔记卡片
    expect(find.byType(Dismissible), findsWidgets);
    // 标签过滤栏应出现（种子数据含标签）
    expect(find.byType(FilterChip), findsWidgets);
  });

  testWidgets('Tapping FAB opens editor page', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('新建笔记'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Editor preview toggle switches to Markdown view', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '测试标题');
    await tester.enterText(find.byType(TextField).last, '## Hello World');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.preview));
    await tester.pumpAndSettle();

    expect(find.text('测试标题'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
  });

  testWidgets('Search page shows search bar and empty state', (tester) async {
    await pumpApp(tester);

    // 点击搜索按钮进入搜索页
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();

    // 搜索页应显示搜索框
    expect(find.byType(TextField), findsOneWidget);
    // 应显示搜索空状态提示
    expect(find.text('搜索笔记'), findsOneWidget);
  });

  testWidgets('Search filters notes by query', (tester) async {
    await pumpApp(tester);

    // 进入搜索页
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();

    // 输入搜索关键词
    await tester.enterText(find.byType(TextField), 'Dart');
    await tester.pumpAndSettle();

    // 应显示匹配的笔记卡片（"Dart 3 空安全实践"标题含"Dart"）
    expect(find.text('Dart 3 空安全实践'), findsOneWidget);
  });

  testWidgets('Settings page shows theme mode selector', (tester) async {
    await pumpApp(tester);

    // 点击更多按钮进入设置页
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 设置页应显示标题
    expect(find.text('设置'), findsOneWidget);
    // 应有主题模式选择器
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    // 应显示加密设置
    expect(find.text('加密设置'), findsOneWidget);
    expect(find.text('AES-256 加密已启用'), findsOneWidget);
    // 滚动到底部，应有版本信息
    await tester.scrollUntilVisible(
      find.text('版本'),
      100,
    );
    expect(find.text('版本'), findsOneWidget);
  });
}
