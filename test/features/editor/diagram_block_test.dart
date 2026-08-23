import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/features/editor/models/diagram_block.dart';
import 'package:flutter_notes/features/editor/models/diagram_language.dart';

void main() {
  group('DiagramBlock', () {
    test('基本字段', () {
      const block = DiagramBlock(
        language: DiagramLanguage.mermaid,
        raw: 'graph TD\nA-->B',
        info: 'mermaid',
      );
      expect(block.language, DiagramLanguage.mermaid);
      expect(block.raw, 'graph TD\nA-->B');
      expect(block.info, 'mermaid');
    });

    test('firstLine 提取首行（不含换行）', () {
      const block = DiagramBlock(
        language: DiagramLanguage.latex,
        raw: '\\frac{a}{b}\nx = 1',
      );
      expect(block.firstLine, r'\frac{a}{b}');
    });

    test('lineCount 按换行数 + 1 计算', () {
      const single = DiagramBlock(
        language: DiagramLanguage.mermaid,
        raw: 'A-->B',
      );
      const multi = DiagramBlock(
        language: DiagramLanguage.mermaid,
        raw: 'A-->B\nC-->D\nE-->F',
      );
      const empty = DiagramBlock(
        language: DiagramLanguage.mermaid,
        raw: '',
      );
      expect(single.lineCount, 1);
      expect(multi.lineCount, 3);
      expect(empty.lineCount, 0);
    });

    test('toString 输出包含语言与首行', () {
      const block = DiagramBlock(
        language: DiagramLanguage.plantuml,
        raw: 'Alice -> Bob',
        info: 'puml',
      );
      final s = block.toString();
      expect(s, contains('plantuml'));
      expect(s, contains('Alice -> Bob'));
    });
  });
}
