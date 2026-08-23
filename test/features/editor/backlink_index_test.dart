import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/features/editor/services/backlink_index.dart';

NoteModel _note(String id, String title, String content) {
  return NoteModel(
    id: id,
    title: title,
    content: content,
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('BacklinkIndex', () {
    test('空笔记列表无反向链接', () {
      final index = BacklinkIndex(const <NoteModel>[]);
      expect(index.findBacklinks('Anything'), isEmpty);
      expect(index.hasBacklinks('Anything'), isFalse);
    });

    test('基本反向链接：单笔记引用单目标', () {
      final a = _note('a', 'Project A', 'see [[Project B]] for context');
      final b = _note('b', 'Project B', 'plain content');
      final index = BacklinkIndex([a, b]);

      final backlinks = index.findBacklinks('Project B');
      expect(backlinks, hasLength(1));
      expect(backlinks.first.sourceNoteId, 'a');
      expect(backlinks.first.sourceTitle, 'Project A');
      expect(backlinks.first.link.target, 'Project B');
    });

    test('多笔记同时引用同一目标', () {
      final a = _note('a', 'A', 'ref [[X]] here');
      final b = _note('b', 'B', 'also [[X]] here');
      final c = _note('c', 'C', 'no refs');
      final index = BacklinkIndex([a, b, c]);

      final backlinks = index.findBacklinks('X');
      expect(backlinks, hasLength(2));
      expect(
        backlinks.map((e) => e.sourceNoteId).toSet(),
        {'a', 'b'},
      );
    });

    test('同一笔记内多次引用同一目标都计入', () {
      final a = _note('a', 'A', 'first [[X]] second [[X]] third');
      final index = BacklinkIndex([a]);
      expect(index.findBacklinks('X'), hasLength(2));
    });

    test('反向链接大小写不敏感', () {
      final a = _note('a', 'A', 'see [[My Note]] here');
      final index = BacklinkIndex([a]);
      expect(index.findBacklinks('my note'), hasLength(1));
      expect(index.findBacklinks('MY NOTE'), hasLength(1));
      expect(index.findBacklinks('My Note'), hasLength(1));
    });

    test('自身引用（笔记 A 内含 [[A]]）仍计入', () {
      final a = _note('a', 'A', 'self ref [[A]] here');
      final index = BacklinkIndex([a]);
      expect(index.findBacklinks('A'), hasLength(1));
      expect(index.findBacklinks('A').first.sourceNoteId, 'a');
    });

    test('rebuild 后索引替换为新内容', () {
      final a = _note('a', 'A', 'ref [[X]]');
      final index = BacklinkIndex([a]);
      expect(index.findBacklinks('X'), hasLength(1));

      final a2 = _note('a', 'A', 'no refs');
      index.rebuild([a2]);
      expect(index.findBacklinks('X'), isEmpty);
    });

    test('空标题 / 不存在目标 不返回误报', () {
      final a = _note('a', 'A', '');
      final index = BacklinkIndex([a]);
      expect(index.findBacklinks(''), isEmpty);
      expect(index.findBacklinks('NotExists'), isEmpty);
    });

    test('带 alias 与 heading 的链接仍按 target 归类', () {
      final a = _note('a', 'A', 'see [[X#Section|alias]] here');
      final index = BacklinkIndex([a]);
      final backlinks = index.findBacklinks('X');
      expect(backlinks, hasLength(1));
      expect(backlinks.first.link.heading, 'Section');
      expect(backlinks.first.link.alias, 'alias');
    });

    test('noteCount 统计参与索引的笔记数', () {
      final a = _note('a', 'A', '');
      final b = _note('b', 'B', '');
      final c = _note('c', 'C', '');
      final index = BacklinkIndex([a, b, c]);
      expect(index.noteCount, 3);

      index.rebuild([a]);
      expect(index.noteCount, 1);
    });

    test('findBacklinks 返回不可变列表', () {
      final a = _note('a', 'A', 'ref [[X]]');
      final index = BacklinkIndex([a]);
      final list = index.findBacklinks('X');
      expect(() => list.add(list.first), throwsUnsupportedError);
    });
  });
}
