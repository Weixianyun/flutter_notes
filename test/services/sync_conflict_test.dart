import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/services/sync_service.dart';

void main() {
  group('SyncConflictItem', () {
    test('noteId 取自 local 笔记 ID', () {
      final local = NoteModel(id: 'a', title: 'A', content: '');
      final remote = NoteModel(id: 'a', title: 'A', content: '远端');
      final item = SyncConflictItem(local: local, remote: remote);
      expect(item.noteId, 'a');
    });

    test('title 优先使用 local 的标题;为空时回退到 (无标题)', () {
      final local1 = NoteModel(id: 'a', title: '本地', content: '');
      final remote1 = NoteModel(id: 'a', title: '本地', content: '');
      final local2 = NoteModel(id: 'a', title: '', content: '');
      final remote2 = NoteModel(id: 'a', title: '远端', content: '');
      expect(SyncConflictItem(local: local1, remote: remote1).title, '本地');
      expect(SyncConflictItem(local: local2, remote: remote2).title, '(无标题)');
    });

    test('localIsNewer 当 local.updatedAt 晚于 remote', () {
      final now = DateTime.now();
      final local = NoteModel(
        id: 'a',
        title: 'A',
        content: '',
        updatedAt: now.add(const Duration(minutes: 1)),
      );
      final remote = NoteModel(id: 'a', title: 'A', content: '', updatedAt: now);
      expect(SyncConflictItem(local: local, remote: remote).localIsNewer, true);
    });
  });

  group('SyncService.detectConflicts', () {
    final base = DateTime(2026, 8, 23, 12);

    NoteModel makeLocal(String id, {DateTime? updatedAt, String content = ''}) {
      return NoteModel(
        id: id,
        title: 'T-$id',
        content: content,
        updatedAt: updatedAt ?? base,
      );
    }

    NoteModel makeRemote(String id, {DateTime? updatedAt, String content = ''}) {
      return makeLocal(id, updatedAt: updatedAt, content: content);
    }

    test('lastSyncedAt 为 null 时所有同 ID 都被视为冲突', () {
      final local = [makeLocal('a')];
      final remote = [makeRemote('a')];
      final conflicts = SyncService.detectConflicts(
        localNotes: local,
        remoteNotes: remote,
        lastSyncedAt: null,
      );
      expect(conflicts, hasLength(1));
      expect(conflicts.first.noteId, 'a');
    });

    test('只本地变更 - 不算冲突', () {
      final local = [makeLocal('a', updatedAt: base.add(const Duration(hours: 1)))];
      final remote = [makeRemote('a', updatedAt: base)];
      final conflicts = SyncService.detectConflicts(
        localNotes: local,
        remoteNotes: remote,
        lastSyncedAt: base,
      );
      expect(conflicts, isEmpty);
    });

    test('只远程变更 - 不算冲突', () {
      final local = [makeLocal('a', updatedAt: base)];
      final remote = [makeRemote('a', updatedAt: base.add(const Duration(hours: 1)))];
      final conflicts = SyncService.detectConflicts(
        localNotes: local,
        remoteNotes: remote,
        lastSyncedAt: base,
      );
      expect(conflicts, isEmpty);
    });

    test('双方都变更 - 算冲突', () {
      final local = [makeLocal('a', updatedAt: base.add(const Duration(hours: 1)))];
      final remote = [makeRemote('a', updatedAt: base.add(const Duration(hours: 2)))];
      final conflicts = SyncService.detectConflicts(
        localNotes: local,
        remoteNotes: remote,
        lastSyncedAt: base,
      );
      expect(conflicts, hasLength(1));
      expect(conflicts.first.noteId, 'a');
    });

    test('本地新增（远程无同 ID）不算冲突', () {
      final local = [makeLocal('a'), makeLocal('b')];
      final remote = [makeRemote('a')];
      final conflicts = SyncService.detectConflicts(
        localNotes: local,
        remoteNotes: remote,
        lastSyncedAt: base,
      );
      expect(conflicts, isEmpty);
    });

    test('混合: 仅 a 是冲突, b 是本地新增', () {
      final local = [
        makeLocal('a', updatedAt: base.add(const Duration(hours: 1))),
        makeLocal('b', updatedAt: base.add(const Duration(hours: 1))),
      ];
      final remote = [makeRemote('a', updatedAt: base.add(const Duration(hours: 2)))];
      final conflicts = SyncService.detectConflicts(
        localNotes: local,
        remoteNotes: remote,
        lastSyncedAt: base,
      );
      expect(conflicts.map((c) => c.noteId), ['a']);
    });
  });
}

