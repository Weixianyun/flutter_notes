import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/features/sync/providers/sync_provider.dart';
import 'package:flutter_notes/services/sync_service.dart';

void main() {
  group('SyncState', () {
    test('默认值是 idle / 无冲突', () {
      const state = SyncState();
      expect(state.status, SyncStatus.idle);
      expect(state.conflicts, isEmpty);
      expect(state.pendingResolutions, isEmpty);
      expect(state.hasConflicts, isFalse);
      expect(state.unresolvedCount, 0);
      expect(state.allResolved, isFalse);
    });

    test('hasConflicts 在有冲突时为 true', () {
      final c = SyncConflictItem(
        local: NoteModel(id: 'a', title: 'A', content: ''),
        remote: NoteModel(id: 'a', title: 'A', content: 'r'),
      );
      final state = SyncState(conflicts: [c]);
      expect(state.hasConflicts, isTrue);
      expect(state.unresolvedCount, 1);
      expect(state.allResolved, isFalse);
    });

    test('unresolvedCount 排除已解决的冲突', () {
      final c1 = SyncConflictItem(
        local: NoteModel(id: 'a', title: 'A', content: ''),
        remote: NoteModel(id: 'a', title: 'A', content: 'r'),
      );
      final c2 = SyncConflictItem(
        local: NoteModel(id: 'b', title: 'B', content: ''),
        remote: NoteModel(id: 'b', title: 'B', content: 'r'),
      );
      final state = SyncState(
        conflicts: [c1, c2],
        pendingResolutions: const {'a': ConflictResolution.localWins},
      );
      expect(state.unresolvedCount, 1);
      expect(state.allResolved, isFalse);
    });

    test('allResolved 仅在所有冲突都已选择时为 true', () {
      final c1 = SyncConflictItem(
        local: NoteModel(id: 'a', title: 'A', content: ''),
        remote: NoteModel(id: 'a', title: 'A', content: 'r'),
      );
      final state = SyncState(
        conflicts: [c1],
        pendingResolutions: const {'a': ConflictResolution.remoteWins},
      );
      expect(state.allResolved, isTrue);
    });

    test('copyWith 正确合并字段', () {
      final c = SyncConflictItem(
        local: NoteModel(id: 'a', title: 'A', content: ''),
        remote: NoteModel(id: 'a', title: 'A', content: 'r'),
      );
      const original = SyncState(message: 'm1');
      final next = original.copyWith(
        status: SyncStatus.success,
        conflicts: [c],
        pendingResolutions: const {'a': ConflictResolution.skip},
      );
      expect(next.status, SyncStatus.success);
      expect(next.message, 'm1');
      expect(next.conflicts, hasLength(1));
      expect(next.pendingResolutions['a'], ConflictResolution.skip);
    });
  });
}
