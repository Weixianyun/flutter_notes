import '../../../data/models/outline_node.dart';

/// 大纲提取服务
///
/// 从 Markdown 文本中解析 `^#{1,6}\s+.+$` 行，构建嵌套的 [OutlineNode] 树。
///
/// 解析规则：
/// - 仅匹配以 `#` 开头的行（前导空白允许）
/// - 最多 6 级（`######` 视为 level=6）
/// - `#` 之后必须接空格才算合法 heading
/// - 行内 `#` 之后的内容（去除尾部可选的 `#+`、尾随空白）作为 title
/// - Setext 风格（下划线 `===` / `---`）暂不支持
class OutlineService {
  const OutlineService();

  /// 从文本中提取大纲；返回根级节点列表（按文档顺序）
  List<OutlineNode> extract(String text) {
    if (text.isEmpty) return const <OutlineNode>[];

    final flat = <_FlatNode>[];
    final lines = text.split('\n');
    var offset = 0;
    for (final line in lines) {
      final lineStart = offset;
      final lineEnd = offset + line.length;
      final parsed = _parseHeading(line);
      if (parsed != null) {
        flat.add(_FlatNode(
          level: parsed.$1,
          title: parsed.$2,
          start: lineStart,
          end: lineEnd,
        ));
      }
      offset = lineEnd + 1; // +1 是换行符
    }

    return _buildTree(flat);
  }

  /// 统计 heading 总数（含嵌套）
  int count(String text) =>
      extract(text).fold<int>(0, (s, n) => s + 1 + n.totalDescendants);

  /// 扁平化（按文档顺序）
  List<OutlineNode> flatten(String text) =>
      extract(text).expand((n) => n.flatten()).toList();

  (int, String)? _parseHeading(String line) {
    final leading = line.length - line.trimLeft().length;
    final trimmed = line.substring(leading);
    if (trimmed.isEmpty || trimmed[0] != '#') return null;
    var level = 0;
    while (level < trimmed.length && trimmed[level] == '#' && level < 6) {
      level++;
    }
    if (level == 0 || level > 6) return null;
    if (level >= trimmed.length) return null;
    if (trimmed[level] != ' ') return null; // # 后必须有空格

    var content = trimmed.substring(level).trimLeft();
    // 去掉尾部 `#+` 与空白（兼容 `# Title #`）
    content = content.replaceFirst(RegExp(r'#+\s*$'), '').trimRight();
    if (content.isEmpty) return null;
    return (level, content);
  }

  List<OutlineNode> _buildTree(List<_FlatNode> flat) {
    final roots = <OutlineNode>[];
    final stack = <OutlineNode>[];

    for (final node in flat) {
      // 弹栈直到栈顶 level < 当前 level
      while (stack.isNotEmpty && stack.last.level >= node.level) {
        stack.removeLast();
      }
      final outline = OutlineNode(
        level: node.level,
        title: node.title,
        startOffset: node.start,
        endOffset: node.end,
        depth: stack.length,
      );
      if (stack.isEmpty) {
        roots.add(outline);
      } else {
        stack.last.adopt(outline);
      }
      stack.add(outline);
    }

    return roots;
  }
}

class _FlatNode {
  _FlatNode({
    required this.level,
    required this.title,
    required this.start,
    required this.end,
  });

  final int level;
  final String title;
  final int start;
  final int end;
}
