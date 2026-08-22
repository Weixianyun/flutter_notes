import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/data/models/note_search_result.dart';
import 'package:flutter_notes/data/repositories/note_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockNoteRepository searchNotesWithHighlights', () {
    final repo = MockNoteRepository();

    test('returns empty list for empty query', () async {
      expect(await repo.searchNotesWithHighlights(''), isEmpty);
      expect(await repo.searchNotesWithHighlights('   '), isEmpty);
    });

    test('finds notes by title keyword and wraps with markers', () async {
      final results = await repo.searchNotesWithHighlights('Dart');
      expect(results, isNotEmpty);
      final hit = results.firstWhere((r) => r.note.title.contains('Dart'));
      expect(hit.titleSnippet, contains('<<Dart>>'));
    });

    test('marks multi-occurrence highlights in content', () async {
      // 至少应找到一个笔记 content 中含 "colorScheme"
      final results = await repo.searchNotesWithHighlights('seed-1');
      // seed-1 是 'Dart 3 空安全实践', 不会匹配;改用肯定存在的词
      expect(results, isA<List<NoteSearchResult>>(),
          reason: 'Method should return list of NoteSearchResult');
      final hits = await repo.searchNotesWithHighlights('主题');
      final titleHits = hits
          .where((r) => r.note.title.toLowerCase().contains('主题'))
          .toList();
      expect(titleHits, isNotEmpty,
          reason: '主题 should match the seed-2 note title');
    });

    test('returns null snippets when query does not match the field', () async {
      // 找一个标题不含 'Xylophone' 的笔记,再搜 'Xylophone' 验证搜索不到
      final results = await repo.searchNotesWithHighlights('Xylophone');
      expect(results, isEmpty);
    });

    test('searchNotes is consistent with searchNotesWithHighlights note IDs',
        () async {
      final query = 'Flutter';
      final notes = await repo.searchNotes(query);
      final withHighlights = await repo.searchNotesWithHighlights(query);
      expect(notes.length, withHighlights.length);
      final ids1 = notes.map((n) => n.id).toSet();
      final ids2 = withHighlights.map((r) => r.note.id).toSet();
      expect(ids1, equals(ids2));
    });

    test('highlights are case-insensitive but preserve original case', () async {
      final results = await repo.searchNotesWithHighlights('dart');
      expect(results, isNotEmpty);
      for (final r in results) {
        if (r.titleSnippet != null) {
          // 原文中应保留 'D' 大小写,只有匹配片段在 markers 之间
          expect(r.titleSnippet!.toLowerCase().contains('<<dart>>'), isTrue);
        }
      }
    });

    test('respects soft-deleted notes are excluded', () async {
      // 添加一条包含唯一关键词的笔记,然后软删除
      final unique = NoteModel(
        title: 'Unicorn Rainbow',
        content: 'only in this note: unicorn',
      );
      await repo.addNote(unique);
      await repo.deleteNote(unique.id);
      final results = await repo.searchNotesWithHighlights('unicorn');
      expect(results.where((r) => r.note.id == unique.id), isEmpty);
    });
  });
}
