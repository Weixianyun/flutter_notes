import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/features/editor/services/inline_latex_processor.dart';

void main() {
  group('InlineLatexProcessor', () {
    const proc = InlineLatexProcessor();

    test('空文本原样返回', () {
      expect(proc.process(''), '');
    });

    test('无公式文本不变', () {
      const text = 'hello world\nno math here';
      expect(proc.process(text), text);
    });

    test('行内公式被包裹', () {
      const text = r'mass $m = 1$ here';
      final out = proc.process(text);
      expect(out, contains(InlineLatexProcessor.openInline));
      expect(out, contains(InlineLatexProcessor.closeInline));
      expect(out.contains(r'$m = 1$'), isFalse);
    });

    test('块级公式被包裹', () {
      const text = r'before $$a^2$$ after';
      final out = proc.process(text);
      expect(out, contains(InlineLatexProcessor.openBlock));
      expect(out, contains(InlineLatexProcessor.closeBlock));
      expect(out.contains(r'$$a^2$$'), isFalse);
    });

    test('块级与行内混排都被处理', () {
      const text = r'line $a$ mid $$b$$ end $c$';
      final out = proc.process(text);
      expect(out, contains(InlineLatexProcessor.openInline));
      expect(out, contains(InlineLatexProcessor.openBlock));
      // 不应再出现裸 $
      expect(RegExp(r'(?<!\\)\$').hasMatch(out), isFalse);
    });

    test('转义 \\\$ 不被处理', () {
      const text = r'price: \$5 and $a$';
      final out = proc.process(text);
      // \$ 保留，$a$ 被处理
      expect(out, contains(r'\$5'));
      expect(out.contains(r'$a$'), isFalse);
    });
  });
}
