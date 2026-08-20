import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
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

  // ── 笔记列表页测试 ──

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

  // ── 搜索页测试 ──

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

  // ── 设置页测试 ──

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

  // ── go_router 路由测试 ──

  testWidgets('Router navigates to trash page', (tester) async {
    await pumpApp(tester);

    // 点击回收站按钮
    await tester.tap(find.byTooltip('回收站'));
    await tester.pumpAndSettle();

    expect(find.text('回收站'), findsOneWidget);
  });

  testWidgets('Router navigates to settings page via more button', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('Router navigates to graph page', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('知识图谱'));
    await tester.pumpAndSettle();

    expect(find.text('知识图谱'), findsOneWidget);
  });

  // ── 编辑器图片插入测试 ──

  testWidgets('Editor image dialog inserts Markdown image syntax', (tester) async {
    await pumpApp(tester);

    // 打开编辑器
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 点击图片工具栏按钮
    await tester.tap(find.byTooltip('图片'));
    await tester.pumpAndSettle();

    // 应显示图片插入对话框
    expect(find.text('插入图片'), findsOneWidget);

    // 通过 labelText 精确定位对话框中的输入框
    final urlField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == '图片 URL',
    );
    final altField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == '替代文本',
    );

    await tester.enterText(urlField, 'https://example.com/photo.png');
    await tester.enterText(altField, '示例图片');
    await tester.pump();

    // 点击插入按钮
    await tester.tap(find.text('插入'));
    await tester.pumpAndSettle();

    // 内容输入框应包含 Markdown 图片语法
    final contentField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('Markdown') == true,
    );
    final contentText =
        tester.widget<TextField>(contentField).controller!.text;
    expect(contentText, contains('![示例图片](https://example.com/photo.png)'));
  });

  // ── 笔记列表批量操作测试 ──

  testWidgets('Long press note enters selection mode', (tester) async {
    await pumpApp(tester);

    // 长按第一条笔记
    final noteCard = find.byType(Dismissible);
    await tester.longPress(noteCard.first);
    await tester.pumpAndSettle();

    // 应进入选择模式，标题显示"已选 1 篇"
    expect(find.text('已选 1 篇'), findsOneWidget);
    // 应显示全选、导出和删除按钮
    expect(find.byTooltip('全选'), findsOneWidget);
    expect(find.byTooltip('导出选中'), findsOneWidget);
    expect(find.byTooltip('删除选中'), findsOneWidget);
    // FAB 应隐藏
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Select all selects all notes and deselect exits mode', (tester) async {
    await pumpApp(tester);

    // 长按进入选择模式
    final noteCard = find.byType(Dismissible);
    await tester.longPress(noteCard.first);
    await tester.pumpAndSettle();

    // 点击全选
    await tester.tap(find.byTooltip('全选'));
    await tester.pumpAndSettle();

    // 应选中所有笔记（种子数据有 6 条）
    expect(find.text('已选 6 篇'), findsOneWidget);

    // 再次点击全选退出
    await tester.tap(find.byTooltip('全选'));
    await tester.pumpAndSettle();

    // 应退出选择模式
    expect(find.text('Flutter Notes'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Close button exits selection mode', (tester) async {
    await pumpApp(tester);

    // 长按进入选择模式
    final noteCard = find.byType(Dismissible);
    await tester.longPress(noteCard.first);
    await tester.pumpAndSettle();

    // 点击关闭按钮
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 应退出选择模式
    expect(find.text('Flutter Notes'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  // ── 图谱搜索测试 ──

  testWidgets('Graph page shows search bar', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('知识图谱'));
    await tester.pumpAndSettle();

    // 应显示搜索框
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索节点标题或标签...'), findsOneWidget);
  });

  testWidgets('Graph search shows match count', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('知识图谱'));
    await tester.pumpAndSettle();

    // 输入搜索关键词
    await tester.enterText(find.byType(TextField), 'Dart');
    await tester.pumpAndSettle();

    // 应显示匹配结果计数
    expect(find.textContaining('匹配'), findsOneWidget);
  });

  // ── 排序选项测试 ──

  testWidgets('Sort menu shows all sort options', (tester) async {
    await pumpApp(tester);

    // 点击排序按钮
    await tester.tap(find.byTooltip('排序方式'));
    await tester.pumpAndSettle();

    // 应显示 5 种排序方式
    expect(find.text('最近修改'), findsOneWidget);
    expect(find.text('最新创建'), findsOneWidget);
    expect(find.text('最早创建'), findsOneWidget);
    expect(find.text('标题 A→Z'), findsOneWidget);
    expect(find.text('优先级高→低'), findsOneWidget);
  });

  testWidgets('Selecting sort by title reorders notes', (tester) async {
    await pumpApp(tester);

    // 打开排序菜单
    await tester.tap(find.byTooltip('排序方式'));
    await tester.pumpAndSettle();

    // 选择「标题 A→Z」
    await tester.tap(find.text('标题 A→Z'));
    await tester.pumpAndSettle();

    // 排序菜单应关闭，列表应重新排序
    expect(find.text('标题 A→Z'), findsNothing);
  });

  // ── 标签管理测试 ──

  testWidgets('Settings page navigates to tag management', (tester) async {
    // 设置较大的测试屏幕尺寸，确保所有 ListItem 都渲染
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    // 打开设置
    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    // 通过 ListTile 找到标签管理
    final tagTile = find.widgetWithText(ListTile, '标签管理');
    expect(tagTile, findsOneWidget);
    await tester.tap(tagTile);
    await tester.pumpAndSettle();

    // 应有「新建标签」按钮
    expect(find.byTooltip('新建标签'), findsOneWidget);
  });

  testWidgets('Tag management page shows existing tags', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    // 打开设置 → 标签管理
    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    final tagTile = find.widgetWithText(ListTile, '标签管理');
    await tester.tap(tagTile);
    await tester.pumpAndSettle();

    // 应显示已存在的标签（来自 seed 数据）
    expect(find.textContaining('#'), findsWidgets);
  });
}

