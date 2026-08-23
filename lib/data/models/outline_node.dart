/// 单个大纲节点
///
/// 对应 Markdown 中的一个 heading 行。
/// 内部通过 [parent] 维护父子关系，构造完成后 [children] 自动按
/// 文档顺序排列。`depth` 表示根级（0）/ 一级子节点（1）/ 等。
class OutlineNode {
  OutlineNode({
    required this.level,
    required this.title,
    required this.startOffset,
    required this.endOffset,
    required this.depth,
  });

  /// Heading 级别 (1-6)
  final int level;

  /// 标题文本
  final String title;

  /// 在原文中起始偏移（包含 `#`）
  final int startOffset;

  /// 在原文中结束偏移（指向标题行末之后）
  final int endOffset;

  /// 嵌套深度（根级为 0）
  final int depth;

  /// 父节点（仅在构造过程中使用）
  OutlineNode? _parent;

  /// 子节点列表（按文档顺序）
  final List<OutlineNode> children = <OutlineNode>[];

  /// 扁平化所有后代（包含自身），按文档顺序
  Iterable<OutlineNode> flatten() sync* {
    yield this;
    for (final child in children) {
      yield* child.flatten();
    }
  }

  /// 总后代数（不含自身）
  int get totalDescendants => children.fold<int>(
        0,
        (sum, c) => sum + 1 + c.totalDescendants,
      );

  void adopt(OutlineNode child) {
    child._parent = this;
    children.add(child);
  }
}
