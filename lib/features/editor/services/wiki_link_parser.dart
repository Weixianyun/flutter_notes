import '../../../data/models/wiki_link.dart';

/// Wiki-link 解析器
///
/// 支持的语法：
/// - `[[Target Note]]`：基本链接
/// - `[[Target Note|Alias]]`：带别名
/// - `[[Target Note#Heading]]`：指向目标笔记的某个 heading
/// - `[[Target Note#Heading|Alias]]`：heading + alias
///
/// 解析规则：
/// - 嵌套 `[[` / `]]` 不允许（遇到第二个 `[[` 视为终止当前链接）
/// - 链接内允许空白与 Markdown 标点，但不允许换行
/// - 同一目标出现多次都会返回
class WikiLinkParser {
  const WikiLinkParser();

  /// 从 Markdown 文本中提取所有 wiki-link
  List<WikiLink> parse(String text) {
    if (text.isEmpty) return const <WikiLink>[];

    final result = <WikiLink>[];
    var i = 0;
    while (i < text.length - 1) {
      if (text[i] == '[' && text[i + 1] == '[') {
        final start = i;
        // 找到匹配的 `]]`；中间再遇到 `[[` 视为提前结束
        var j = i + 2;
        var foundEnd = -1;
        while (j < text.length - 1) {
          if (text[j] == '\n') break; // 链接不允许跨行
          if (text[j] == '[' && text[j + 1] == '[') break;
          if (text[j] == ']' && text[j + 1] == ']') {
            foundEnd = j;
            break;
          }
          j++;
        }
        if (foundEnd > 0) {
          final inner = text.substring(i + 2, foundEnd);
          final link = _parseInner(inner, start, foundEnd + 2);
          if (link != null) {
            result.add(link);
          }
          i = foundEnd + 2;
        } else {
          // 没有匹配到 `]]`，前进一格继续扫描
          i = i + 1;
        }
      } else {
        i++;
      }
    }
    return result;
  }

  /// 仅提取所有 link 的 target（标题）字符串，去重并保留原大小写
  List<String> extractTargets(String text) {
    final seen = <String>{};
    final targets = <String>[];
    for (final link in parse(text)) {
      final key = link.target.toLowerCase();
      if (seen.add(key)) {
        targets.add(link.target);
      }
    }
    return targets;
  }

  WikiLink? _parseInner(String inner, int start, int end) {
    // inner 不含 `[[` `]]`
    if (inner.isEmpty) return null;

    // 先按 `|` 切出 alias
    String? alias;
    var body = inner;
    final aliasIdx = _findUnescapedPipe(body);
    if (aliasIdx >= 0) {
      alias = body.substring(aliasIdx + 1).trim();
      if (alias.isEmpty) alias = null;
      body = body.substring(0, aliasIdx);
    }

    // 再按 `#` 切出 heading
    String? heading;
    final hashIdx = body.indexOf('#');
    if (hashIdx >= 0) {
      heading = body.substring(hashIdx + 1).trim();
      if (heading.isEmpty) heading = null;
      body = body.substring(0, hashIdx);
    }

    final target = body.trim();
    if (target.isEmpty) return null;

    return WikiLink(
      target: target,
      heading: heading,
      alias: alias,
      start: start,
      end: end,
    );
  }

  /// 找到未转义的 `|`；目前不支持转义
  int _findUnescapedPipe(String s) {
    for (var i = 0; i < s.length; i++) {
      if (s[i] == '|') return i;
    }
    return -1;
  }
}
