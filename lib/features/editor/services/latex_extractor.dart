import 'package:flutter/foundation.dart';

/// 一段 LaTeX 数学公式
///
/// 通过 [LatexExtractor] 从文本中抽取，标记为行内（[isInline]）或块级。
@immutable
class LatexSegment {
  const LatexSegment({
    required this.content,
    required this.isInline,
    required this.start,
    required this.end,
  });

  /// 公式内容（不含 `$` 围栏）
  final String content;

  /// `true` 表示行内公式（`$..$`），`false` 表示块级公式（`$$..$$`）
  final bool isInline;

  /// 在原文中的起始偏移（含 `$`）
  final int start;

  /// 在原文中的结束偏移（不含末尾 `$` 之后的下一字符）
  final int end;

  /// 渲染层显示的纯文本（不含围栏）
  String get display => content;

  @override
  String toString() =>
      'LatexSegment(isInline: $isInline, content: "$content")';
}

/// LaTeX 公式提取器
///
/// 规则：
/// - 行内：`$..$` （不能跨行，不能紧跟 `:` `=` ` ` 等，避免误识别货币）
/// - 块级：`$$..$$` （可跨行）
/// - 跳过 `\$` 转义
class LatexExtractor {
  const LatexExtractor();

  /// 从文本中提取所有 LaTeX 段
  List<LatexSegment> extract(String text) {
    if (text.isEmpty) return const <LatexSegment>[];
    final result = <LatexSegment>[];

    var i = 0;
    while (i < text.length) {
      final ch = text[i];

      // 跳过转义
      if (ch == r'\' && i + 1 < text.length) {
        i += 2;
        continue;
      }

      // 块级：$$
      if (ch == r'$' && i + 1 < text.length && text[i + 1] == r'$') {
        final start = i;
        var j = i + 2;
        var foundEnd = -1;
        while (j < text.length - 1) {
          if (text[j] == r'$' && text[j + 1] == r'$') {
            foundEnd = j;
            break;
          }
          j++;
        }
        if (foundEnd > 0) {
          final raw = text.substring(i + 2, foundEnd);
          // 修剪外侧换行/空格（与 GitHub/Markdown 块级公式风格一致）
          final content = _trimBlockContent(raw);
          if (content.isNotEmpty) {
            result.add(LatexSegment(
              content: content,
              isInline: false,
              start: start,
              end: foundEnd + 2,
            ));
          }
          i = foundEnd + 2;
        } else {
          i++;
        }
        continue;
      }

      // 行内：$..$
      if (ch == r'$' && _isInlineStart(text, i)) {
        final start = i;
        var j = i + 1;
        var foundEnd = -1;
        while (j < text.length) {
          final c = text[j];
          if (c == '\n') break; // 行内不跨行
          if (c == r'\' && j + 1 < text.length) {
            j += 2;
            continue;
          }
          if (c == r'$') {
            foundEnd = j;
            break;
          }
          j++;
        }
        if (foundEnd > start) {
          final content = text.substring(i + 1, foundEnd);
          if (content.isNotEmpty) {
            result.add(LatexSegment(
              content: content,
              isInline: true,
              start: start,
              end: foundEnd + 1,
            ));
          }
          i = foundEnd + 1;
        } else {
          i++;
        }
        continue;
      }

      i++;
    }

    return result;
  }

  /// 修剪块级公式外侧连续的换行与空格
  static String _trimBlockContent(String raw) {
    var start = 0;
    var end = raw.length;
    while (start < end && (raw[start] == '\n' || raw[start] == ' ')) {
      start++;
    }
    while (end > start && (raw[end - 1] == '\n' || raw[end - 1] == ' ')) {
      end--;
    }
    return raw.substring(start, end);
  }

  /// 启发式判断 `$` 是否作为行内公式的起始
  ///
  /// 排除：
  /// - 紧跟在字母/数字/下划线/反斜杠后的 `$`（可能是标识符延续或转义后的 `$`）
  /// - 紧跟在另一个 `$` 后的 `$`（已被块级公式吞掉；保护性判断）
  /// - 紧跟在 `:` `=` 后的 `$`（容易被误识别为货币）
  bool _isInlineStart(String text, int idx) {
    if (idx == 0) return true;
    final prev = text[idx - 1];
    // 字母/数字/下划线/反斜杠/$ 都视为不应作为行内公式起始
    if (RegExp(r'[A-Za-z0-9_$\\]').hasMatch(prev)) return false;
    return true;
  }
}
