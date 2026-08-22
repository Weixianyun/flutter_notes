import 'note_model.dart';

/// 笔记搜索结果（带高亮片段）
///
/// 在 [NoteModel] 基础上扩展两个可选的「高亮片段」字段：
/// - [titleSnippet]: FTS5 `highlight()` 输出的标题片段，包含 `<<` `>>` 标记
/// - [contentSnippet]: FTS5 `snippet()` 输出的内容片段，长度受 FTS5 限制
///
/// 高亮标记规则（默认）：
/// - 标题：`<<关键词>>`
/// - 内容：`<<关键词>>`，前后带 `...` 省略符
class NoteSearchResult {
  const NoteSearchResult({
    required this.note,
    this.titleSnippet,
    this.contentSnippet,
  });

  /// 命中的笔记
  final NoteModel note;

  /// 标题高亮片段（包含 `<<` `>>` 标记，未命中关键词时为 null）
  final String? titleSnippet;

  /// 内容高亮片段（包含 `<<` `>>` 标记，未命中关键词时为 null）
  final String? contentSnippet;

  /// 是否存在任何高亮片段
  bool get hasHighlight =>
      (titleSnippet?.contains('<<') ?? false) ||
      (contentSnippet?.contains('<<') ?? false);

  /// 转 JSON（用于测试断言或日志）
  Map<String, dynamic> toJson() => {
        'note': note.toJson(),
        if (titleSnippet != null) 'titleSnippet': titleSnippet,
        if (contentSnippet != null) 'contentSnippet': contentSnippet,
      };
}
