import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/features/notes/providers/sort_provider.dart';
import 'package:flutter_notes/features/notes/providers/tags_provider.dart';

void main() {
  group('NoteSortOrder', () {
    test('all sort orders have Chinese labels', () {
      for (final order in NoteSortOrder.values) {
        expect(order.label, isNotEmpty);
      }
    });

    test('label getter returns the expected string', () {
      expect(NoteSortOrder.updatedAtDesc.label, '最近修改');
      expect(NoteSortOrder.createdAtDesc.label, '最新创建');
      expect(NoteSortOrder.createdAtAsc.label, '最早创建');
      expect(NoteSortOrder.titleAsc.label, '标题 A→Z');
      expect(NoteSortOrder.priorityDesc.label, '优先级高→低');
    });
  });

  group('NoteSortOrderNotifier', () {
    test('default order is updatedAtDesc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(noteSortOrderProvider), NoteSortOrder.updatedAtDesc);
    });

    test('setOrder changes the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(noteSortOrderProvider.notifier).setOrder(
            NoteSortOrder.titleAsc,
          );
      expect(container.read(noteSortOrderProvider), NoteSortOrder.titleAsc);

      container.read(noteSortOrderProvider.notifier).setOrder(
            NoteSortOrder.priorityDesc,
          );
      expect(container.read(noteSortOrderProvider), NoteSortOrder.priorityDesc);
    });
  });

  group('sortedNotesProvider ordering', () {
    NoteModel makeNote({
      required String id,
      required String title,
      required DateTime createdAt,
      required DateTime updatedAt,
      NotePriority priority = NotePriority.medium,
    }) {
      return NoteModel(
        id: id,
        title: title,
        content: '',
        priority: priority,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    test('updatedAtDesc puts the most recently updated note first', () {
      final container = ProviderContainer(overrides: [
        filteredNotesProvider.overrideWith((ref) => AsyncValue.data([
              makeNote(
                id: '1',
                title: 'A',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 5),
              ),
              makeNote(
                id: '2',
                title: 'B',
                createdAt: DateTime(2025, 1, 2),
                updatedAt: DateTime(2025, 1, 10),
              ),
            ])),
      ]);
      addTearDown(container.dispose);

      container.read(noteSortOrderProvider.notifier).setOrder(
            NoteSortOrder.updatedAtDesc,
          );

      final result = container.read(sortedNotesProvider).valueOrNull!;
      expect(result.first.id, '2');
      expect(result.last.id, '1');
    });

    test('titleAsc sorts by title case-insensitively', () {
      final container = ProviderContainer(overrides: [
        filteredNotesProvider.overrideWith((ref) => AsyncValue.data([
              makeNote(
                id: '1',
                title: 'banana',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
              ),
              makeNote(
                id: '2',
                title: 'Apple',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
              ),
            ])),
      ]);
      addTearDown(container.dispose);

      container.read(noteSortOrderProvider.notifier).setOrder(
            NoteSortOrder.titleAsc,
          );

      final result = container.read(sortedNotesProvider).valueOrNull!;
      expect(result.first.id, '2');
      expect(result.last.id, '1');
    });

    test('priorityDesc puts high-priority notes first', () {
      final container = ProviderContainer(overrides: [
        filteredNotesProvider.overrideWith((ref) => AsyncValue.data([
              makeNote(
                id: '1',
                title: 'low',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                priority: NotePriority.low,
              ),
              makeNote(
                id: '2',
                title: 'high',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                priority: NotePriority.high,
              ),
              makeNote(
                id: '3',
                title: 'medium',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                priority: NotePriority.medium,
              ),
            ])),
      ]);
      addTearDown(container.dispose);

      container.read(noteSortOrderProvider.notifier).setOrder(
            NoteSortOrder.priorityDesc,
          );

      final result = container.read(sortedNotesProvider).valueOrNull!;
      expect(result.map((n) => n.id).toList(), ['2', '3', '1']);
    });

    test('createdAtAsc orders by oldest first', () {
      final container = ProviderContainer(overrides: [
        filteredNotesProvider.overrideWith((ref) => AsyncValue.data([
              makeNote(
                id: '1',
                title: 'B',
                createdAt: DateTime(2025, 5, 1),
                updatedAt: DateTime(2025, 5, 1),
              ),
              makeNote(
                id: '2',
                title: 'A',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
              ),
            ])),
      ]);
      addTearDown(container.dispose);

      container.read(noteSortOrderProvider.notifier).setOrder(
            NoteSortOrder.createdAtAsc,
          );

      final result = container.read(sortedNotesProvider).valueOrNull!;
      expect(result.first.id, '2');
      expect(result.last.id, '1');
    });
  });
}
