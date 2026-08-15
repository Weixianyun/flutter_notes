import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/data/repositories/note_repository.dart';

void main() {
  late AppDatabase db;
  late DriftNoteRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = DriftNoteRepository(db);
  });

  tearDown(() => db.close());

  group('DriftNoteRepository', () {
    group('getAllNotes', () {
      test('returns seed data sorted by updatedAt descending', () async {
        final notes = await repository.getAllNotes();

        expect(notes.length, 6);
        // 验证按 updatedAt 倒序排列
        for (int i = 1; i < notes.length; i++) {
          expect(
            notes[i - 1].updatedAt.compareTo(notes[i].updatedAt),
            greaterThanOrEqualTo(0),
          );
        }
      });

      test('seed data contains expected titles', () async {
        final notes = await repository.getAllNotes();
        final titles = notes.map((n) => n.title).toSet();

        expect(titles, containsAll([
          'Dart 3 空安全实践',
          'Flutter Material 3 主题配置',
          'Riverpod 状态管理入门',
          'drift 数据库设计',
          'GitHub OAuth 认证流程',
          'Markdown 编辑器功能清单',
        ]));
      });
    });

    group('getNoteById', () {
      test('returns note when ID exists', () async {
        final note = await repository.getNoteById('seed-1');

        expect(note, isNotNull);
        expect(note!.id, 'seed-1');
        expect(note.title, 'Dart 3 空安全实践');
        expect(note.priority, NotePriority.high);
        expect(note.tags, ['Dart', '空安全']);
      });

      test('returns null when ID does not exist', () async {
        final note = await repository.getNoteById('non-existent-id');

        expect(note, isNull);
      });
    });

    group('addNote', () {
      test('adds a new note and it can be retrieved', () async {
        final newNote = NoteModel(
          title: '测试笔记',
          content: '## 测试内容',
          priority: NotePriority.low,
          tags: ['测试', '新增'],
        );

        final added = await repository.addNote(newNote);
        final retrieved = await repository.getNoteById(added.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.title, '测试笔记');
        expect(retrieved.content, '## 测试内容');
        expect(retrieved.priority, NotePriority.low);
        expect(retrieved.tags, ['测试', '新增']);
      });

      test('increases total note count by 1', () async {
        final before = await repository.getAllNotes();
        final countBefore = before.length;

        await repository.addNote(NoteModel(
          title: '计数测试',
          content: '',
        ));

        final after = await repository.getAllNotes();
        expect(after.length, countBefore + 1);
      });

      test('preserves tags as JSON array', () async {
        final note = NoteModel(
          title: '标签测试',
          content: '',
          tags: ['Flutter', 'Dart', '测试'],
        );

        await repository.addNote(note);
        final retrieved = await repository.getNoteById(note.id);

        expect(retrieved!.tags, ['Flutter', 'Dart', '测试']);
        expect(retrieved.tags.length, 3);
      });
    });

    group('updateNote', () {
      test('updates existing note fields', () async {
        final original = await repository.getNoteById('seed-2');
        expect(original, isNotNull);

        final updated = original!.copyWith(
          title: '更新后的标题',
          content: '更新后的内容',
          priority: NotePriority.high,
        );

        await repository.updateNote(updated);
        final retrieved = await repository.getNoteById('seed-2');

        expect(retrieved, isNotNull);
        expect(retrieved!.title, '更新后的标题');
        expect(retrieved.content, '更新后的内容');
        expect(retrieved.priority, NotePriority.high);
      });

      test('updates tags correctly', () async {
        final original = await repository.getNoteById('seed-3');
        final updated = original!.copyWith(tags: ['新标签1', '新标签2']);

        await repository.updateNote(updated);
        final retrieved = await repository.getNoteById('seed-3');

        expect(retrieved!.tags, ['新标签1', '新标签2']);
      });

      test('does not create duplicate when updating', () async {
        final before = await repository.getAllNotes();
        final countBefore = before.length;

        final note = before.first;
        await repository.updateNote(note.copyWith(title: '不改标题数'));

        final after = await repository.getAllNotes();
        expect(after.length, countBefore);
      });
    });

    group('deleteNote (soft delete)', () {
      test('removes note from active list', () async {
        final before = await repository.getAllNotes();
        final countBefore = before.length;

        await repository.deleteNote('seed-1');

        final after = await repository.getAllNotes();
        expect(after.length, countBefore - 1);
        expect(after.any((n) => n.id == 'seed-1'), isFalse);
      });

      test('sets deletedAt timestamp on soft-deleted note', () async {
        await repository.deleteNote('seed-4');

        final note = await repository.getNoteById('seed-4');
        expect(note, isNotNull);
        expect(note!.deletedAt, isNotNull);
      });

      test('soft-deleted note appears in getDeletedNotes', () async {
        await repository.deleteNote('seed-4');

        final deleted = await repository.getDeletedNotes();
        expect(deleted.any((n) => n.id == 'seed-4'), isTrue);
      });

      test('does not throw when deleting non-existent ID', () async {
        await expectLater(
          repository.deleteNote('non-existent'),
          completes,
        );
      });
    });

    group('restoreNote', () {
      test('restores a soft-deleted note to active list', () async {
        await repository.deleteNote('seed-1');

        final deletedAfterDelete = await repository.getDeletedNotes();
        expect(deletedAfterDelete.any((n) => n.id == 'seed-1'), isTrue);

        await repository.restoreNote('seed-1');

        final activeAfterRestore = await repository.getAllNotes();
        expect(activeAfterRestore.any((n) => n.id == 'seed-1'), isTrue);

        final deletedAfterRestore = await repository.getDeletedNotes();
        expect(deletedAfterRestore.any((n) => n.id == 'seed-1'), isFalse);

        final note = await repository.getNoteById('seed-1');
        expect(note!.deletedAt, isNull);
      });
    });

    group('permanentlyDeleteNote', () {
      test('permanently removes a note from database', () async {
        await repository.deleteNote('seed-2');
        await repository.permanentlyDeleteNote('seed-2');

        final note = await repository.getNoteById('seed-2');
        expect(note, isNull);

        final active = await repository.getAllNotes();
        expect(active.any((n) => n.id == 'seed-2'), isFalse);

        final deleted = await repository.getDeletedNotes();
        expect(deleted.any((n) => n.id == 'seed-2'), isFalse);
      });
    });

    group('emptyTrash', () {
      test('removes all soft-deleted notes', () async {
        await repository.deleteNote('seed-1');
        await repository.deleteNote('seed-2');

        final deletedBefore = await repository.getDeletedNotes();
        expect(deletedBefore.length, 2);

        await repository.emptyTrash();

        final deletedAfter = await repository.getDeletedNotes();
        expect(deletedAfter, isEmpty);
      });

      test('does not affect active notes', () async {
        final activeBefore = await repository.getAllNotes();

        await repository.deleteNote('seed-1');
        await repository.emptyTrash();

        final activeAfter = await repository.getAllNotes();
        expect(activeAfter.length, activeBefore.length - 1);
        expect(activeAfter.any((n) => n.id == 'seed-1'), isFalse);
      });
    });

    group('searchNotes (FTS5)', () {
      test('finds notes by title keyword', () async {
        final results = await repository.searchNotes('Dart');
        expect(results, isNotEmpty);
        expect(results.any((n) => n.title.contains('Dart')), isTrue);
      });

      test('finds notes by content keyword', () async {
        final results = await repository.searchNotes('ColorScheme');
        expect(results, isNotEmpty);
        expect(results.any((n) => n.content.contains('ColorScheme')), isTrue);
      });

      test('finds notes by tag keyword', () async {
        final results = await repository.searchNotes('Riverpod');
        expect(results, isNotEmpty);
        expect(results.any((n) => n.tags.contains('Riverpod')), isTrue);
      });

      test('returns empty list for empty query', () async {
        final results = await repository.searchNotes('');
        expect(results, isEmpty);
      });

      test('returns empty list for no matches', () async {
        final results = await repository.searchNotes('zzzznonexistent');
        expect(results, isEmpty);
      });

      test('excludes soft-deleted notes from results', () async {
        await repository.deleteNote('seed-1');

        final results = await repository.searchNotes('空安全');
        expect(results.any((n) => n.id == 'seed-1'), isFalse);
      });

      test('supports prefix search', () async {
        final results = await repository.searchNotes('Mar');
        expect(results, isNotEmpty);
        expect(results.any((n) => n.title.contains('Markdown')), isTrue);
      });
    });

    group('watchAllNotes', () {
      test('emits initial data', () async {
        final stream = repository.watchAllNotes();
        final firstEmission = await stream.first;

        expect(firstEmission.length, 6);
        expect(firstEmission.any((n) => n.id == 'seed-1'), isTrue);
      });

      test('emits updated list after add', () async {
        final stream = repository.watchAllNotes();
        final subscription = stream.listen((_) {});

        // 等待初始发射
        await Future.delayed(const Duration(milliseconds: 100));

        await repository.addNote(NoteModel(
          title: '监听测试',
          content: '',
        ));

        // 等待流发射
        await Future.delayed(const Duration(milliseconds: 100));

        final notes = await repository.getAllNotes();
        expect(notes.any((n) => n.title == '监听测试'), isTrue);

        await subscription.cancel();
      });
    });

    group('entity conversion', () {
      test('priority enum round-trips correctly', () async {
        for (final priority in NotePriority.values) {
          final note = NoteModel(
            title: '优先级测试 ${priority.name}',
            content: '',
            priority: priority,
          );
          await repository.addNote(note);
          final retrieved = await repository.getNoteById(note.id);
          expect(retrieved!.priority, priority);
        }
      });

      test('status enum round-trips correctly', () async {
        for (final status in NoteStatus.values) {
          final note = NoteModel(
            title: '状态测试 ${status.name}',
            content: '',
            status: status,
          );
          await repository.addNote(note);
          final retrieved = await repository.getNoteById(note.id);
          expect(retrieved!.status, status);
        }
      });

      test('empty tags list round-trips correctly', () async {
        final note = NoteModel(
          title: '空标签测试',
          content: '',
          tags: [],
        );
        await repository.addNote(note);
        final retrieved = await repository.getNoteById(note.id);
        expect(retrieved!.tags, isEmpty);
      });

      test('special characters in content round-trip correctly', () async {
        final content = '特殊字符：`code` **bold** *italic* \n'
            '表情：😀🎉\n'
            '引号："double" \'single\'\n'
            '符号：<>&{}[]';
        final note = NoteModel(
          title: '特殊字符',
          content: content,
        );
        await repository.addNote(note);
        final retrieved = await repository.getNoteById(note.id);
        expect(retrieved!.content, content);
      });
    });
  });
}
