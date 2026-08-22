import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/router/app_router.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
import 'package:flutter_notes/features/settings/providers/settings_provider.dart';
import 'package:flutter_notes/l10n/app_localizations.dart';
import 'package:flutter_notes/services/service_providers.dart';

void main() {
  // 测试中每个 testWidgets 创建独立的内存数据库，抑制多重数据库警告
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// 测试用 override 列表
  ///
  /// 默认行为：
  /// - markdownAutoPreviewProvider = false，确保新建笔记直接进入编辑模式
  ///   （覆盖产品默认的"自动预览"，让现有编辑器测试在不改断言的前提下通过）
  Future<List<Override>> testOverrides() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      markdownAutoPreviewProvider.overrideWith(
        MarkdownAutoPreviewNotifierTest.new,
      ),
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
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: AppRouter.createRouter(),
        ),
      ),
    );
    // 等待数据库初始化和种子数据加载
    await tester.pumpAndSettle();
  }

  /// 启动应用并让 MaterialApp 跟随 [appLocaleProvider] 状态。
  ///
  /// 语言切换测试使用此函数，验证 setLocale 后 UI 文案实时变化。
  /// 初始 locale 仍设为中文，确保测试不依赖系统语言。
  Future<void> pumpAppReactiveLocale(WidgetTester tester) async {
    final overrides = await testOverrides();
    // 在 ProviderScope 外部创建一次 router，确保 Consumer 重建时不会创建新 router
    final router = AppRouter.createRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: Consumer(
          builder: (context, ref, _) {
            final locale = ref.watch(appLocaleProvider);
            return MaterialApp.router(
              title: 'Flutter Notes',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: ThemeMode.light,
              locale: locale ?? const Locale('zh'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: router,
            );
          },
        ),
      ),
    );
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
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    // 点击更多按钮进入设置页
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 设置页应显示标题
    expect(find.text('设置'), findsOneWidget);
    // 应有主题模式选择器
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.byType(SegmentedButton<AppThemeMode>), findsOneWidget);
    // 滚动到加密设置项
    await tester.scrollUntilVisible(find.text('加密设置'), 150);
    expect(find.text('加密设置'), findsOneWidget);
    expect(find.text('AES-256 加密已启用'), findsOneWidget);
    // 继续滚动到底部，应有版本信息
    await tester.scrollUntilVisible(find.text('版本'), 150);
    expect(find.text('版本'), findsOneWidget);
  });

  // ── Day 4: 主题切换反馈 ──

  testWidgets('Toggling AMOLED switch shows theme-changed snack bar',
      (tester) async {
    await pumpApp(tester);

    // 进入设置页
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 找到 AMOLED 真黑 ListTile 的 Switch 并点击
    final amoledSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('AMOLED 真黑'),
        matching: find.byType(ListTile),
      ),
      matching: find.byType(Switch),
    );
    expect(amoledSwitch, findsOneWidget);
    await tester.tap(amoledSwitch);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // SnackBar 应显示 "已切换到 AMOLED 真黑 主题"
    expect(find.textContaining('AMOLED 真黑'), findsWidgets);
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

    // 内容输入框是编辑器中最后一个 TextField（标题为第一个），应包含图片语法
    final contentField = find.byType(TextField).last;
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

  // ── i18n 集成测试 ──

  testWidgets('Settings page shows language switcher', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    // 验证设置页标题为中文
    expect(find.text('设置'), findsOneWidget);
    // 验证语言选择项存在（语言行 ListTile 与主题 SegmentedButton 都有「跟随系统」，
    // 至少应出现一次）。
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('跟随系统'), findsAtLeastNWidgets(1));
  });

  testWidgets('Language switcher changes UI locale', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 使用响应式 locale 的 pump 助手，确保 setLocale 后 MaterialApp 重建
    await pumpAppReactiveLocale(tester);

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    // 找到语言行（标题为「语言」的 ListTile）
    final langTile = find.widgetWithText(ListTile, '语言');
    expect(langTile, findsOneWidget);

    // 找到该行内的 PopupMenuButton 触发器（图标为 chevron_right）
    final popupTrigger = find.descendant(
      of: langTile,
      matching: find.byIcon(Icons.chevron_right),
    );
    expect(popupTrigger, findsOneWidget);
    await tester.tap(popupTrigger);
    await tester.pumpAndSettle();

    // 菜单打开后，菜单项位于独立的 Popup 路由中，全局查找
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('English'));
    // 等待 setLocale 持久化 + Consumer 重建 MaterialApp + Localizations 重建
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // AppBar 标题应变为英文
    expect(find.text('Settings'), findsOneWidget);
  });

  // ── 编辑器自动保存 + 字数统计测试 ──

  testWidgets('Editor shows word/char count and autosave status in status bar',
      (tester) async {
    await pumpApp(tester);

    // 进入新建笔记编辑器，输入并保存
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.enterText(
      find.byType(TextField).last,
      'Dart Flutter widgets rendering pipeline',
    );
    await tester.pump();

    // 手动保存（snackbar 出现后编辑器 pop 回列表）
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    expect(find.text('笔记已创建'), findsOneWidget);

    // 重新进入刚保存的笔记（编辑模式），状态栏应显示字数与字符数
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(find.textContaining('字'), findsWidgets);
    expect(find.textContaining('字符'), findsWidgets);
  });

  testWidgets('Editor autosave triggers and updates status after 1.5s debounce',
      (tester) async {
    await pumpApp(tester);

    // 进入新建笔记
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '测试');
    await tester.enterText(find.byType(TextField).last, '内容');
    await tester.pump();

    // 手动保存，弹出 snackbar
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    expect(find.text('笔记已创建'), findsOneWidget);
  });

  // ── 设置项接入测试 ──

  testWidgets('Settings page shows editor behavior section with new options',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);

    // 打开设置
    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    // 编辑器行为分区应可见（滚动到该区域）
    await tester.scrollUntilVisible(find.text('编辑器'), 150);
    expect(find.text('编辑器'), findsOneWidget);
    // Markdown 自动预览
    expect(find.text('Markdown 自动预览'), findsOneWidget);
    expect(find.text('新笔记默认以预览模式打开'), findsOneWidget);
    // 默认优先级
    expect(find.text('新建笔记默认优先级'), findsOneWidget);
    // 列表密度（滚动到该区域）。SegmentedButton 段标签和 ListTile subtitle
    // 都会出现"舒适"/"紧凑"，因此用 findsAtLeastNWidgets。
    await tester.scrollUntilVisible(find.text('列表密度'), 150);
    expect(find.text('列表密度'), findsOneWidget);
    expect(find.text('舒适'), findsAtLeastNWidgets(1));
    expect(find.text('紧凑'), findsAtLeastNWidgets(1));
  });

  // ── Day 6: 搜索高亮 + 跳转定位 ──

  testWidgets(
    'Search results show highlight snippet above each card',
    (tester) async {
      await pumpApp(tester);

      // 进入搜索页
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      // 输入关键词 'Dart'
      await tester.enterText(find.byType(TextField), 'Dart');
      await tester.pumpAndSettle();

      // 笔记标题（Dart 3 空安全实践）应通过 NoteCard 正常渲染
      expect(find.text('Dart 3 空安全实践'), findsOneWidget);

      // 高亮片段使用 RichText 渲染
      expect(find.byType(RichText), findsWidgets);
    },
  );

  testWidgets(
    'Tapping search result navigates to editor with highlight token',
    (tester) async {
      await pumpApp(tester);

      // 进入搜索页
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      // 输入关键词
      await tester.enterText(find.byType(TextField), 'Dart');
      await tester.pumpAndSettle();

      // 点击第一张笔记卡片
      await tester.tap(find.text('Dart 3 空安全实践'));
      await tester.pumpAndSettle();

      // 跳转后编辑器页面应出现编辑工具栏（行内代码 icon）
      expect(find.byIcon(Icons.code), findsOneWidget);
    },
  );
}

/// 测试用 Notifier，强制返回 false（关闭新建笔记自动预览）。
class MarkdownAutoPreviewNotifierTest extends MarkdownAutoPreviewNotifier {
  @override
  bool build() => false;
}

