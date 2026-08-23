import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/features/editor/models/diagram_language.dart';

void main() {
  group('DiagramLanguage.fromCodeFence', () {
    test('null / 空字符串 → other', () {
      expect(DiagramLanguage.fromCodeFence(null), DiagramLanguage.other);
      expect(DiagramLanguage.fromCodeFence(''), DiagramLanguage.other);
      expect(DiagramLanguage.fromCodeFence('   '), DiagramLanguage.other);
    });

    test('mermaid 各种大小写与别名', () {
      expect(DiagramLanguage.fromCodeFence('mermaid'), DiagramLanguage.mermaid);
      expect(DiagramLanguage.fromCodeFence('Mermaid'), DiagramLanguage.mermaid);
      expect(DiagramLanguage.fromCodeFence('MERMAID'), DiagramLanguage.mermaid);
      expect(DiagramLanguage.fromCodeFence('  mmd  '), DiagramLanguage.mermaid);
    });

    test('latex / tex / math / katex 归类', () {
      expect(DiagramLanguage.fromCodeFence('latex'), DiagramLanguage.latex);
      expect(DiagramLanguage.fromCodeFence('tex'), DiagramLanguage.latex);
      expect(DiagramLanguage.fromCodeFence('math'), DiagramLanguage.math);
      expect(DiagramLanguage.fromCodeFence('katex'), DiagramLanguage.katex);
    });

    test('plantuml / puml / uml 归类', () {
      expect(DiagramLanguage.fromCodeFence('plantuml'), DiagramLanguage.plantuml);
      expect(DiagramLanguage.fromCodeFence('puml'), DiagramLanguage.plantuml);
      expect(DiagramLanguage.fromCodeFence('UML'), DiagramLanguage.plantuml);
    });

    test('未知语言降级为 other', () {
      expect(DiagramLanguage.fromCodeFence('python'), DiagramLanguage.other);
      expect(DiagramLanguage.fromCodeFence('javascript'), DiagramLanguage.other);
    });
  });

  group('DiagramLanguage 派生属性', () {
    test('isDiagram 正确标记图表/数学语言', () {
      expect(DiagramLanguage.mermaid.isDiagram, isTrue);
      expect(DiagramLanguage.latex.isDiagram, isTrue);
      expect(DiagramLanguage.math.isDiagram, isTrue);
      expect(DiagramLanguage.katex.isDiagram, isTrue);
      expect(DiagramLanguage.plantuml.isDiagram, isTrue);
      expect(DiagramLanguage.other.isDiagram, isFalse);
    });

    test('displayLabel 与人类可读语言名对应', () {
      expect(DiagramLanguage.mermaid.displayLabel, 'Mermaid');
      expect(DiagramLanguage.latex.displayLabel, 'Math');
      expect(DiagramLanguage.math.displayLabel, 'Math');
      expect(DiagramLanguage.plantuml.displayLabel, 'PlantUML');
      expect(DiagramLanguage.other.displayLabel, 'Code');
    });
  });
}
