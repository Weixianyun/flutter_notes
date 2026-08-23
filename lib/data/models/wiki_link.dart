/// 单个 wiki-link 解析结果
///
/// 语法：`[[target]]` 或 `[[target|alias]]` 或 `[[target#heading]]` 或 `[[target#heading|alias]]`
///
/// - [target]：必填，对应笔记标题（大小写不敏感匹配）
/// - [heading]：可选，指向目标笔记内的某个 heading
/// - [alias]：可选，覆盖显示文本
/// - [start]/[end]：在原文中的字符偏移（包含 `[[` 和 `]]`）
class WikiLink {
  const WikiLink({
    required this.target,
    required this.start,
    required this.end,
    this.heading,
    this.alias,
  });

  /// 目标笔记标题
  final String target;

  /// 可选 heading
  final String? heading;

  /// 可选显示别名
  final String? alias;

  /// 在原文中的起始偏移（含 `[[`）
  final int start;

  /// 在原文中的结束偏移（不含 `]]` 之后的下一字符）
  final int end;

  /// 渲染时显示的文本
  String get displayText {
    if (alias != null && alias!.isNotEmpty) return alias!;
    final base = target;
    if (heading != null && heading!.isNotEmpty) {
      return '$base#$heading';
    }
    return base;
  }

  /// 完整目标位置字符串：`<target>` 或 `<target>#<heading>`
  String get destination => heading == null || heading!.isEmpty
      ? target
      : '$target#$heading';

  @override
  String toString() =>
      'WikiLink($displayText, $start..$end, target=$target, heading=$heading)';
}
