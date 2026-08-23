import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/features/editor/providers/backlink_index_provider.dart';
import 'package:flutter_notes/features/editor/services/backlink_index.dart';
import 'package:flutter_notes/features/notes/providers/notes_provider.dart';

NoteModel _note(String id, String title, String content) {
  return NoteModel(
    id: id,
    title: title,
    content: content,
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<T> _pumpEvents<T>(Future<T> Function() body) async {
  // 让 Riverpod 内部的 microtask 跑完（notesProvider 异步 build 完成后重建 backlinkIndexProvider）
  await Future<void>.delayed(Duration.zero);
  return body();
}

void main() {
  group('backlinkIndexProvider', () {
    test('notes 为空时索引也是空的', () async {
      final container = ProviderContainer(
        overrides: [
          notesProvider.overrideWith(_StaticNotesNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final index = await _pumpEvents(
        () async => container.read(backlinkIndexReadyProvider.future),
      );
      expect(index, isA<BacklinkIndex>());
      expect(index.noteCount, 0);
      expect(index.findBacklinks('Anything'), isEmpty);
    });

    test('笔记列表能正确反查', () async {
      final notes = [
        _note('a', 'Note A', 'ref [[X]] here'),
        _note('b', 'Note B', 'plain'),
        _note('c', 'Note C', 'also [[X]]'),
      ];
      final container = ProviderContainer(
        overrides: [
          notesProvider.overrideWith(
            () => _StaticNotesNotifier(notes),
          ),
        ],
      );
      addTearDown(container.dispose);

      final index = await _pumpEvents(
        () async => container.read(backlinkIndexReadyProvider.future),
      );
      expect(index.noteCount, 3);
      final backlinks = index.findBacklinks('X');
      expect(backlinks, hasLength(2));
      expect(
        backlinks.map((e) => e.sourceNoteId).toSet(),
        {'a', 'c'},
      );
    });
  });
}

class _StaticNotesNotifier extends NotesNotifier {
  _StaticNotesNotifier([this._seed = const <NoteModel>[]]);
  final List<NoteModel> _seed;

  @override
  Future<List<NoteModel>> build() async => _seed;
}
