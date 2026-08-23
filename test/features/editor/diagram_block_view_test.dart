import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/features/editor/models/diagram_block.dart';
import 'package:flutter_notes/features/editor/models/diagram_language.dart';
import 'package:flutter_notes/features/editor/widgets/diagram/diagram_block_view.dart';
import 'package:flutter_notes/features/editor/widgets/diagram/latex_renderer.dart';
import 'package:flutter_notes/features/editor/widgets/diagram/mermaid_renderer.dart';
import 'package:flutter_notes/features/editor/widgets/diagram/plantuml_renderer.dart';

void main() {
  group('DiagramBlockView 调度', () {
    testWidgets('mermaid + 非空 raw 渲染 MermaidRenderer', (tester) async {
      const block = DiagramBlock(
        language: DiagramLanguage.mermaid,
        raw: 'graph TD\nA-->B',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiagramBlockView(block: block)),
        ),
      );
      await tester.pump();

      // Mermaid 渲染可能慢/异步，pump 几次让 widget 树稳定
      await tester.pump(const Duration(milliseconds: 100));
      // MermaidRenderer 的容器应被创建
      expect(find.byType(MermaidRenderer), findsOneWidget);
    });

    testWidgets('mermaid + 空 raw 渲染空提示', (tester) async {
      const block = DiagramBlock(
        language: DiagramLanguage.mermaid,
        raw: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiagramBlockView(block: block)),
        ),
      );
      await tester.pump();

      expect(find.text('空 Mermaid 代码块'), findsOneWidget);
      expect(find.byType(MermaidRenderer), findsNothing);
    });

    testWidgets('latex 块渲染 LatexRenderer', (tester) async {
      const block = DiagramBlock(
        language: DiagramLanguage.latex,
        raw: r'\frac{a}{b}',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiagramBlockView(block: block)),
        ),
      );
      await tester.pump();

      expect(find.byType(LatexRenderer), findsOneWidget);
    });

    testWidgets('math 块渲染 LatexRenderer', (tester) async {
      const block = DiagramBlock(
        language: DiagramLanguage.math,
        raw: r'E = mc^2',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiagramBlockView(block: block)),
        ),
      );
      await tester.pump();

      expect(find.byType(LatexRenderer), findsOneWidget);
    });

    testWidgets('空 latex 块显示空提示', (tester) async {
      const block = DiagramBlock(
        language: DiagramLanguage.latex,
        raw: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiagramBlockView(block: block)),
        ),
      );
      await tester.pump();

      expect(find.text('空 Math 代码块'), findsOneWidget);
      expect(find.byType(LatexRenderer), findsNothing);
    });

    testWidgets('plantuml 块渲染 PlantumlRenderer', (tester) async {
      const block = DiagramBlock(
        language: DiagramLanguage.plantuml,
        raw: 'Alice -> Bob : hello',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiagramBlockView(block: block)),
        ),
      );
      await tester.pump();

      expect(find.byType(PlantumlRenderer), findsOneWidget);
    });

    testWidgets('other 语言返回 SizedBox.shrink', (tester) async {
      const block = DiagramBlock(
        language: DiagramLanguage.other,
        raw: 'print(1)',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiagramBlockView(block: block)),
        ),
      );
      await tester.pump();

      // 不能找到 MermaidRenderer，也不能找到提示文本
      expect(find.byType(MermaidRenderer), findsNothing);
      expect(find.textContaining('空'), findsNothing);
    });
  });
}
