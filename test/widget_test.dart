import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/app.dart';

void main() {
  testWidgets('Notes list renders with title, FAB and tag filter', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Notes'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    // Mock 数据应渲染笔记卡片
    expect(find.byType(Dismissible), findsWidgets);
    // 标签过滤栏应出现（Mock 数据含标签）
    expect(find.byType(FilterChip), findsWidgets);
  });

  testWidgets('Tapping FAB opens editor page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('新建笔记'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Editor preview toggle switches to Markdown view', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

    // 点击搜索按钮进入搜索页
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();

    // 搜索页应显示搜索框
    expect(find.byType(TextField), findsOneWidget);
    // 应显示搜索空状态提示
    expect(find.text('搜索笔记'), findsOneWidget);
  });

  testWidgets('Search filters notes by query', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

    // 点击更多按钮进入设置页
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 设置页应显示标题
    expect(find.text('设置'), findsOneWidget);
    // 应有主题模式选择器
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    // 滚动到底部，应有版本信息
    await tester.scrollUntilVisible(
      find.text('版本'),
      100,
    );
    expect(find.text('版本'), findsOneWidget);
  });
}
