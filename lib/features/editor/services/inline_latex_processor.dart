import 'latex_extractor.dart';

/// 行内 LaTeX 公式的 Markdown 预处理
///
/// 把文本中的 `$..$` / `$$..$$` 替换为自定义 markdown 标签，
/// `MarkdownPreview` 中的 `builders` 可以拦截后调用 [LatexRenderer]。
///
/// 替换语法：
/// - 行内 → `⟨latex-inline⟩{content}⟨/latex-inline⟩`
/// - 块级 → `⟨latex-block⟩\n{content}\n⟨/latex-block⟩`
class InlineLatexProcessor {
  const InlineLatexProcessor({LatexExtractor? extractor})
      : _extractor = extractor ?? const LatexExtractor();

  static const openInline = '\u0001LATEX_INLINE_OPEN\u0001';
  static const closeInline = '\u0001LATEX_INLINE_CLOSE\u0001';
  static const openBlock = '\u0001LATEX_BLOCK_OPEN\u0001';
  static const closeBlock = '\u0001LATEX_BLOCK_CLOSE\u0001';

  final LatexExtractor _extractor;

  /// 预处理 Markdown 文本：将 LaTeX 公式替换为占位标记
  String process(String text) {
    if (text.isEmpty) return text;
    final segments = _extractor.extract(text);
    if (segments.isEmpty) return text;

    final buf = StringBuffer();
    var cursor = 0;
    for (final seg in segments) {
      if (seg.start > cursor) {
        buf.write(text.substring(cursor, seg.start));
      }
      if (seg.isInline) {
        buf
          ..write(openInline)
          ..write(seg.content)
          ..write(closeInline);
      } else {
        buf
          ..write(openBlock)
          ..write('\n')
          ..write(seg.content)
          ..write('\n')
          ..write(closeBlock);
      }
      cursor = seg.end;
    }
    if (cursor < text.length) {
      buf.write(text.substring(cursor));
    }
    return buf.toString();
  }
}
