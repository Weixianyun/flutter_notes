/// 搜索高亮片段（Highlighted Segment）
///
/// 用于 [RichText] 渲染的一对「文本」+「是否高亮」。
class HighlightSegment {
  const HighlightSegment(this.text, {required this.isHighlight});

  final String text;
  final bool isHighlight;

  @override
  String toString() =>
      'HighlightSegment(text: $text, isHighlight: $isHighlight)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightSegment &&
          other.text == text &&
          other.isHighlight == isHighlight;

  @override
  int get hashCode => Object.hash(text, isHighlight);
}

/// 解析 FTS5 高亮片段
///
/// 默认 FTS5 标记：`<<` 起始、`>>` 结束。例如
/// `Dart <<空安全>> 实践` → 拆为
/// `[HighlightSegment('Dart '), HighlightSegment('空安全', isHighlight: true), HighlightSegment(' 实践')]`。
///
/// 设计要点：
/// - 没有 `<<` 时整段视为非高亮
/// - `<<` 但没有 `>>` 时,剩余全部视为高亮（兜底避免吞字）
/// - 可自定义标记，兼容未来调整
List<HighlightSegment> parseHighlight(
  String? input, {
  String startMark = '<<',
  String endMark = '>>',
}) {
  if (input == null || input.isEmpty) return const [];
  final segments = <HighlightSegment>[];
  final buf = StringBuffer();
  var inHighlight = false;
  var i = 0;
  while (i < input.length) {
    if (!inHighlight && input.startsWith(startMark, i)) {
      if (buf.isNotEmpty) {
        segments.add(HighlightSegment(buf.toString(), isHighlight: false));
        buf.clear();
      }
      inHighlight = true;
      i += startMark.length;
      continue;
    }
    if (inHighlight && input.startsWith(endMark, i)) {
      segments.add(HighlightSegment(buf.toString(), isHighlight: true));
      buf.clear();
      inHighlight = false;
      i += endMark.length;
      continue;
    }
    buf.write(input[i]);
    i++;
  }
  // 兜底：残留 buf 仍要写出，避免吞字
  if (buf.isNotEmpty) {
    segments.add(HighlightSegment(buf.toString(), isHighlight: inHighlight));
  }
  return segments;
}
