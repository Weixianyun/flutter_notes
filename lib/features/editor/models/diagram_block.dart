import 'diagram_language.dart';

/// 一个被识别为图表/数学代码块的内容
///
/// 由 Markdown 解析阶段或后处理阶段从 ` ```mermaid ` 风格代码块提取得到。
/// [raw] 是去除了围栏的原始内容；[info] 是围栏语言标记。
class DiagramBlock {
  const DiagramBlock({
    required this.language,
    required this.raw,
    this.info,
  });

  /// 解析出的语言
  final DiagramLanguage language;

  /// 围栏语言标记原始文本（用于回写或调试）
  final String? info;

  /// 围栏内代码
  final String raw;

  /// 首行（用于诊断）
  String get firstLine {
    if (raw.isEmpty) return '';
    final newline = raw.indexOf('\n');
    return newline < 0 ? raw : raw.substring(0, newline);
  }

  /// 估算行数（用于 UI 提示）
  int get lineCount {
    if (raw.isEmpty) return 0;
    return '\n'.allMatches(raw).length + 1;
  }

  @override
  String toString() =>
      'DiagramBlock(language: $language, lines: $lineCount, first: "$firstLine")';
}
