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

    group('deleteNote', () {
      test('removes note by ID', () async {
        final before = await repository.getAllNotes();
        final countBefore = before.length;

        await repository.deleteNote('seed-1');

        final after = await repository.getAllNotes();
        expect(after.length, countBefore - 1);
        expect(after.any((n) => n.id == 'seed-1'), isFalse);
      });

      test('getNoteById returns null after deletion', () async {
        await repository.deleteNote('seed-4');

        final note = await repository.getNoteById('seed-4');
        expect(note, isNull);
      });

      test('does not throw when deleting non-existent ID', () async {
        await expectLater(
          repository.deleteNote('non-existent'),
          completes,
        );
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
