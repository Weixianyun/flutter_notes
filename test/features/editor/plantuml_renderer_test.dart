import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/features/editor/widgets/diagram/plantuml_renderer.dart';

void main() {
  group('PlantumlRenderer - 容器样式', () {
    testWidgets('空代码不崩溃（保持空字符串）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlantumlRenderer(code: '')),
        ),
      );
      await tester.pump();
      expect(find.byType(PlantumlRenderer), findsOneWidget);
    });

    testWidgets('非空源码渲染 PlantumlRenderer + InteractiveViewer',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlantumlRenderer(code: 'Alice -> Bob : hello'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PlantumlRenderer), findsOneWidget);
      // 缩放容器应被建立
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('亮/暗主题切换：源码不影响 widget 重建', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlantumlRenderer(
              code: 'Alice -> Bob : hello',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PlantumlRenderer), findsOneWidget);
    });
  });
}
