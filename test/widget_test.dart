import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/app.dart';

void main() {
  testWidgets('Notes list renders with title and FAB', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Notes'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    // Mock 数据应渲染笔记卡片
    expect(find.byType(Dismissible), findsWidgets);
  });

  testWidgets('Tapping FAB opens editor page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 编辑器页面应显示标题
    expect(find.text('新建笔记'), findsOneWidget);
    // 应有标题输入框和内容输入框
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Editor preview toggle switches to Markdown view', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterNotesApp()));
    await tester.pumpAndSettle();

    // 打开编辑器
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 输入内容
    await tester.enterText(find.byType(TextField).first, '测试标题');
    await tester.enterText(find.byType(TextField).last, '## Hello World');
    await tester.pump();

    // 点击预览按钮
    await tester.tap(find.byIcon(Icons.preview));
    await tester.pumpAndSettle();

    // 预览模式应显示标题文本和 Markdown 渲染内容
    expect(find.text('测试标题'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
  });
}
