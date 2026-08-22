import 'package:flutter_notes/features/search/utils/highlight_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHighlight', () {
    test('returns empty list for null input', () {
      expect(parseHighlight(null), isEmpty);
    });

    test('returns empty list for empty string', () {
      expect(parseHighlight(''), isEmpty);
    });

    test('treats plain text as a single non-highlighted segment', () {
      final segments = parseHighlight('Hello world');
      expect(segments, [
        const HighlightSegment('Hello world', isHighlight: false),
      ]);
    });

    test('wraps a single highlight marker pair', () {
      final segments = parseHighlight('Hello <<world>>!');
      expect(segments, [
        const HighlightSegment('Hello ', isHighlight: false),
        const HighlightSegment('world', isHighlight: true),
        const HighlightSegment('!', isHighlight: false),
      ]);
    });

    test('handles multiple highlight marker pairs', () {
      final segments = parseHighlight('<<Dart>> 与 <<Flutter>> 学习');
      expect(segments, [
        const HighlightSegment('Dart', isHighlight: true),
        const HighlightSegment(' 与 ', isHighlight: false),
        const HighlightSegment('Flutter', isHighlight: true),
        const HighlightSegment(' 学习', isHighlight: false),
      ]);
    });

    test('falls back to highlight when end mark is missing', () {
      final segments = parseHighlight('Dart <<空安全');
      expect(segments, [
        const HighlightSegment('Dart ', isHighlight: false),
        const HighlightSegment('空安全', isHighlight: true),
      ]);
    });

    test('preserves start mark when no end mark appears', () {
      // 这里 start mark 出现但后续没有 end mark,应整体高亮
      final segments = parseHighlight('Hello <<world');
      expect(segments, [
        const HighlightSegment('Hello ', isHighlight: false),
        const HighlightSegment('world', isHighlight: true),
      ]);
    });

    test('handles empty highlight body', () {
      final segments = parseHighlight('a<<>>b');
      expect(segments, [
        const HighlightSegment('a', isHighlight: false),
        const HighlightSegment('', isHighlight: true),
        const HighlightSegment('b', isHighlight: false),
      ]);
    });

    test('supports custom markers', () {
      final segments = parseHighlight(
        'a **b** c',
        startMark: '**',
        endMark: '**',
      );
      expect(segments, [
        const HighlightSegment('a ', isHighlight: false),
        const HighlightSegment('b', isHighlight: true),
        const HighlightSegment(' c', isHighlight: false),
      ]);
    });
  });
}
