import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:flutter_notes/features/editor/models/diagram_language.dart';
import 'package:flutter_notes/features/editor/widgets/diagram/diagram_block_view.dart';
import 'package:flutter_notes/features/editor/widgets/markdown_preview.dart';

void main() {
  group('CodeBlockBuilder - 图表语言路由', () {
    CodeBlockBuilder builder() => CodeBlockBuilder(
          codeBg: const Color(0xFFF6F8FA),
          codeFg: const Color(0xFF1E1E2E),
          labelColor: const Color(0xFF6E7781),
          isDark: false,
          borderRadius: BorderRadius.circular(8),
        );

    testWidgets('mermaid 代码块返回 DiagramBlockView', (tester) async {
      final code = md.Element.text('code', 'A-->B');
      code.attributes['class'] = 'language-mermaid';
      final element = md.Element('pre', [code]);
      final widget = builder().visitElementAfter(element, null);
      expect(widget, isA<DiagramBlockView>());
    });

    testWidgets('latex/math/plantuml 也返回 DiagramBlockView', (tester) async {
      for (final lang in const ['latex', 'math', 'katex', 'plantuml', 'mmd', 'puml']) {
        final code = md.Element.text('code', 'x');
        code.attributes['class'] = 'language-$lang';
        final element = md.Element('pre', [code]);
        final widget = builder().visitElementAfter(element, null);
        expect(widget, isA<DiagramBlockView>(),
            reason: 'language=$lang should be routed as DiagramBlockView');
        expect(DiagramLanguage.fromCodeFence(lang).isDiagram, isTrue,
            reason: 'language=$lang should be a diagram language');
      }
    });

    testWidgets('普通语言返回 _CodeBlockWidget', (tester) async {
      final code = md.Element.text('code', 'print(1)');
      code.attributes['class'] = 'language-python';
      final element = md.Element('pre', [code]);
      final widget = builder().visitElementAfter(element, null);
      expect(widget, isNotNull);
      // 普通代码块不应是 DiagramBlockView
      expect(widget, isNot(isA<DiagramBlockView>()));
    });
  });
}
