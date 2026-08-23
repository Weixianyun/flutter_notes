import '../../../data/models/note_model.dart';
import '../../../data/models/wiki_link.dart';
import 'wiki_link_parser.dart';

/// 反向链接条目
///
/// 表示某条笔记（B）通过 `[[Target]]` 引用了目标笔记（A）。
class BacklinkEntry {
  const BacklinkEntry({
    required this.sourceNoteId,
    required this.sourceTitle,
    required this.link,
  });

  /// 引用方笔记的 ID
  final String sourceNoteId;

  /// 引用方笔记的标题
  final String sourceTitle;

  /// 命中本次查询的 wiki-link
  final WikiLink link;
}

/// 反向链接索引
///
/// 在一组笔记中：
/// - 提取每条笔记正文中的 `[[target]]` 链接
/// - 按 target 聚合反向链接
/// - 提供 `findBacklinks(targetTitle)` 查询所有引用了指定标题的笔记
///
/// 索引是纯数据，可在内存中即时构建（笔记量级百/千级足够）；
/// 大规模场景可后续替换为持久化。
class BacklinkIndex {
  BacklinkIndex(Iterable<NoteModel> notes, {WikiLinkParser? parser})
      : _parser = parser ?? const WikiLinkParser() {
    rebuild(notes);
  }

  final WikiLinkParser _parser;

  /// 规范化 key（lowercase） -> 反向链接列表
  final Map<String, List<BacklinkEntry>> _byTarget = <String, List<BacklinkEntry>>{};

  /// 全部参与索引的笔记 ID 集合
  final Set<String> _seenIds = <String>{};

  /// 查询所有引用了 `targetTitle` 的反向链接
  ///
  /// 大小写不敏感（target 解析阶段已经规范化）。
  List<BacklinkEntry> findBacklinks(String targetTitle) {
    final key = targetTitle.trim().toLowerCase();
    if (key.isEmpty) return const <BacklinkEntry>[];
    final list = _byTarget[key];
    if (list == null) return const <BacklinkEntry>[];
    return List<BacklinkEntry>.unmodifiable(list);
  }

  /// 是否存在任何反向链接
  bool hasBacklinks(String targetTitle) => findBacklinks(targetTitle).isNotEmpty;

  /// 重建索引
  void rebuild(Iterable<NoteModel> notes) {
    _byTarget.clear();
    _seenIds.clear();
    for (final note in notes) {
      _seenIds.add(note.id);
      final links = _parser.parse(note.content);
      for (final link in links) {
        final key = link.target.trim().toLowerCase();
        if (key.isEmpty) continue;
        _byTarget.putIfAbsent(key, () => <BacklinkEntry>[]).add(
              BacklinkEntry(
                sourceNoteId: note.id,
                sourceTitle: note.title.isEmpty ? '(无标题)' : note.title,
                link: link,
              ),
            );
      }
    }
  }

  /// 全部参与索引的笔记数量
  int get noteCount => _seenIds.length;
}
