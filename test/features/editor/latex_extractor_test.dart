import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/features/editor/services/latex_extractor.dart';

void main() {
  group(r'LatexExtractor - 块级 $$..$$', () {
    test('单行块级公式', () {
      const text = r'$$\frac{a}{b}$$';
      final result = const LatexExtractor().extract(text);
      expect(result, hasLength(1));
      expect(result.first.isInline, isFalse);
      expect(result.first.content, r'\frac{a}{b}');
    });

    test('多行块级公式', () {
      const text = r'$$' '\n' r'\frac{a}{b}' '\n' r'= c' '\n' r'$$';
      final result = const LatexExtractor().extract(text);
      expect(result, hasLength(1));
      expect(result.first.isInline, isFalse);
      // 实现从 i+2 开始（即跳过开头的 $$），保留原内容
      expect(result.first.content, r'\frac{a}{b}' '\n' r'= c');
    });

    test('多段块级公式', () {
      const text = r'before $$a^2$$ middle $$b^2$$ after';
      final result = const LatexExtractor().extract(text);
      expect(result, hasLength(2));
      expect(result[0].content, 'a^2');
      expect(result[1].content, 'b^2');
    });
  });

  group('LatexExtractor - 行内 \$..\$', () {
    test('行内公式识别', () {
      const text = r'质量 $m = 1$ 速度';
      final result = const LatexExtractor().extract(text);
      expect(result, hasLength(1));
      expect(result.first.isInline, isTrue);
      expect(result.first.content, 'm = 1');
    });

    test('行内公式不跨行', () {
      const text = r'begin $a' '\nrest';
      final result = const LatexExtractor().extract(text);
      expect(result, isEmpty);
    });

    test('块级与行内混排', () {
      const text = r'line $a$ mid $$b$$ end $c$';
      final result = const LatexExtractor().extract(text);
      expect(result, hasLength(3));
      expect(result[0].isInline, isTrue);
      expect(result[0].content, 'a');
      expect(result[1].isInline, isFalse);
      expect(result[1].content, 'b');
      expect(result[2].isInline, isTrue);
      expect(result[2].content, 'c');
    });
  });

  group('LatexExtractor - 跳过误识别', () {
    test('货币 \$5.99 不被识别', () {
      const text = r'price: $5.99 only';
      final result = const LatexExtractor().extract(text);
      expect(result, isEmpty);
    });

    test('转义 \\\$ 跳过', () {
      const text = r'price: \$5 and $a$';
      final result = const LatexExtractor().extract(text);
      // \$ 转义后剩下 $a$
      expect(result, hasLength(1));
      expect(result.first.content, 'a');
    });

    test('空公式被忽略', () {
      const text = r'before $$ after';
      final result = const LatexExtractor().extract(text);
      expect(result, isEmpty);
    });
  });

  group('LatexExtractor - 偏移与基础边界', () {
    test('空文本返回空列表', () {
      expect(const LatexExtractor().extract(''), isEmpty);
    });

    test('offsets 正确指向原文', () {
      const text = r'xx $a$ yy';
      final result = const LatexExtractor().extract(text);
      expect(result.first.start, 3);
      expect(result.first.end, 6);
      expect(text.substring(result.first.start, result.first.end), r'$a$');
    });
  });
}
