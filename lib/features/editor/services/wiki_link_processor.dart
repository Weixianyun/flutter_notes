import '../../../data/models/wiki_link.dart';
import 'wiki_link_parser.dart';

/// 将 Markdown 文本中的 `[[X]]` 替换为指向 `#wiki:Target` 的 markdown 链接，
/// 供 [MarkdownPreview] 配合 [onTapLink] 路由到具体笔记。
///
/// 替换策略：
/// - 仅替换 `[[` 起始、`]]` 结束的子串
/// - 替换为 `[displayText](#wiki:target)`；若含 heading，链接中加 `?h=heading`
/// - 链接 URL 在预览组件中通过 `onTapLink` 拦截 `#wiki:` 路由
class WikiLinkProcessor {
  const WikiLinkProcessor({WikiLinkParser? parser})
      : _parser = parser ?? const WikiLinkParser();

  final WikiLinkParser _parser;

  /// 把原文转换为适合 markdown 渲染的版本
  String process(String text) {
    if (text.isEmpty) return text;
    final links = _parser.parse(text);
    if (links.isEmpty) return text;

    final sb = StringBuffer();
    var cursor = 0;
    for (final link in links) {
      if (link.start > cursor) {
        sb.write(text.substring(cursor, link.start));
      }
      final url = _toHref(link);
      sb.write('[');
      sb.write(_escapeMarkdownText(link.displayText));
      sb.write(']');
      sb.write('(');
      sb.write(url);
      sb.write(')');
      cursor = link.end;
    }
    if (cursor < text.length) {
      sb.write(text.substring(cursor));
    }
    return sb.toString();
  }

  /// 把 href 还原为目标笔记标题（去除 `#wiki:` 前缀和 query，并做 URL 解码）
  static String? extractTarget(String href) {
    if (!href.startsWith('#wiki:')) return null;
    final raw = href.substring(6);
    final hashIdx = raw.indexOf('?h=');
    final encoded = hashIdx >= 0 ? raw.substring(0, hashIdx) : raw;
    return Uri.decodeComponent(encoded);
  }

  /// 解析 `#wiki:Target?h=Heading` 中的 heading（URL 解码后）
  static String? extractHeading(String href) {
    if (!href.startsWith('#wiki:')) return null;
    final raw = href.substring(6);
    final idx = raw.indexOf('?h=');
    if (idx < 0) return null;
    return Uri.decodeComponent(raw.substring(idx + 3));
  }

  String _toHref(WikiLink link) {
    final buf = StringBuffer('#wiki:');
    buf.write(_encodeFragment(link.target));
    if (link.heading != null && link.heading!.isNotEmpty) {
      buf.write('?h=');
      buf.write(_encodeFragment(link.heading!));
    }
    return buf.toString();
  }

  String _encodeFragment(String s) => Uri.encodeComponent(s);

  /// 在 markdown 链接中，displayText 里的 `]` / `(` / `)` 会破坏语法，做最简转义
  String _escapeMarkdownText(String s) {
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }
}
