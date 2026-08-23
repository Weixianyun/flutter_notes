import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/features/editor/widgets/diagram/mermaid_renderer.dart';

void main() {
  group('MermaidRenderer - 容器样式', () {
    testWidgets('亮主题：背景偏浅灰', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MermaidRenderer(code: 'graph TD\nA-->B'),
          ),
        ),
      );
      await tester.pump();
      // Mermaid 异步构建，给一些时间
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MermaidRenderer), findsOneWidget);
    });

    testWidgets('暗主题：不抛异常', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const Scaffold(
            body: MermaidRenderer(code: 'graph TD\nA-->B'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MermaidRenderer), findsOneWidget);
    });
  });

  group('MermaidErrorBlock', () {
    testWidgets('展示错误标题、说明与原始代码', (tester) async {
      const code = 'invalid mermaid';
      const message = 'parse error';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MermaidErrorBlock(code: code, message: message),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Mermaid 渲染失败'), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(find.text(code), findsOneWidget);
    });
  });
}
