import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/services/sync_service.dart';

void main() {
  group('SyncService.computeContentSha', () {
    test('相同内容 → 相同 sha', () {
      final a = NoteModel(
        id: '1',
        title: 'A',
        content: 'hello',
        priority: NotePriority.medium,
        status: NoteStatus.draft,
        tags: const ['x', 'y'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1, 10),
      );
      final b = NoteModel(
        id: '1',
        title: 'A',
        content: 'hello',
        priority: NotePriority.medium,
        status: NoteStatus.draft,
        tags: const ['x', 'y'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1, 11),
      );
      expect(SyncService.computeContentSha(a), SyncService.computeContentSha(b));
    });

    test('内容不同 → sha 不同', () {
      final a = NoteModel(id: '1', title: 'A', content: 'hello');
      final b = NoteModel(id: '1', title: 'A', content: 'world');
      expect(SyncService.computeContentSha(a), isNot(SyncService.computeContentSha(b)));
    });

    test('标签顺序不同 → sha 不同', () {
      final a = NoteModel(id: '1', title: 'A', content: '', tags: const ['x', 'y']);
      final b = NoteModel(id: '1', title: 'A', content: '', tags: const ['y', 'x']);
      expect(SyncService.computeContentSha(a), isNot(SyncService.computeContentSha(b)));
    });

    test('优先级 / 状态变化 → sha 不同', () {
      final a = NoteModel(
        id: '1',
        title: 'A',
        content: '',
        priority: NotePriority.low,
        status: NoteStatus.draft,
      );
      final b = a.copyWith(priority: NotePriority.high);
      expect(SyncService.computeContentSha(a), isNot(SyncService.computeContentSha(b)));
      final c = a.copyWith(status: NoteStatus.published);
      expect(SyncService.computeContentSha(a), isNot(SyncService.computeContentSha(c)));
    });

    test('sha 是 40 字符 hex', () {
      final a = NoteModel(id: '1', title: 'A', content: 'hello');
      final sha = SyncService.computeContentSha(a);
      expect(sha.length, 40);
      expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(sha), isTrue);
    });

    test('computeRemoteSha 对相同输入输出相同 sha', () {
      const md = '---\nid: 1\ntitle: A\n---\n\n# A\n';
      expect(SyncService.computeRemoteSha(md), SyncService.computeRemoteSha(md));
      expect(SyncService.computeRemoteSha(md), isNot(SyncService.computeRemoteSha('$md ')));
    });
  });

  group('detectConflicts with lastSyncedRemoteSha', () {
    final base = DateTime(2026, 8, 23, 12);

    NoteModel makeNote(
      String id, {
      DateTime? updatedAt,
      String content = 'base-content',
      String title = 'T',
    }) {
      return NoteModel(
        id: id,
        title: title,
        content: content,
        updatedAt: updatedAt ?? base,
      );
    }

    test('远端 sha 未变 → 不算冲突', () {
      final local = makeNote('a', updatedAt: base.add(const Duration(hours: 1)));
      final remote = makeNote('a', updatedAt: base.add(const Duration(hours: 2)));
      final sha = SyncService.computeContentSha(remote);
      final result = SyncService.detectConflicts(
        localNotes: [local],
        remoteNotes: [remote],
        lastSyncedAt: base,
        lastSyncedRemoteSha: {'a': sha},
      );
      expect(result, isEmpty);
    });

    test('远端 sha 改变 → 算冲突', () {
      final local = makeNote('a', updatedAt: base.add(const Duration(hours: 1)));
      final remote = makeNote(
        'a',
        updatedAt: base.add(const Duration(hours: 2)),
        content: 'changed-content',
      );
      final prevSha = SyncService.computeContentSha(makeNote('a'));
      final result = SyncService.detectConflicts(
        localNotes: [local],
        remoteNotes: [remote],
        lastSyncedAt: base,
        lastSyncedRemoteSha: {'a': prevSha},
      );
      expect(result, hasLength(1));
      expect(result.first.noteId, 'a');
    });

    test('缺少该 ID 的 sha 记录 → 仍按时间戳判定冲突', () {
      final local = makeNote('a', updatedAt: base.add(const Duration(hours: 1)));
      final remote = makeNote('a', updatedAt: base.add(const Duration(hours: 2)));
      final result = SyncService.detectConflicts(
        localNotes: [local],
        remoteNotes: [remote],
        lastSyncedAt: base,
        lastSyncedRemoteSha: const {},
      );
      expect(result, hasLength(1));
    });

    test('不传 lastSyncedRemoteSha 时按原逻辑判定冲突', () {
      final local = makeNote('a', updatedAt: base.add(const Duration(hours: 1)));
      final remote = makeNote('a', updatedAt: base.add(const Duration(hours: 2)));
      final result = SyncService.detectConflicts(
        localNotes: [local],
        remoteNotes: [remote],
        lastSyncedAt: base,
      );
      expect(result, hasLength(1));
    });

    test('混合：仅 ID=a 远端未变，ID=b 远端已变', () {
      final localA = makeNote('a', updatedAt: base.add(const Duration(hours: 1)));
      final localB = makeNote('b', updatedAt: base.add(const Duration(hours: 1)));
      final remoteA = makeNote('a', updatedAt: base.add(const Duration(hours: 2)));
      final remoteB = makeNote(
        'b',
        updatedAt: base.add(const Duration(hours: 2)),
        content: 'changed',
      );
      final shaA = SyncService.computeContentSha(remoteA);
      final shaB = SyncService.computeContentSha(makeNote('b')); // 旧 sha
      final result = SyncService.detectConflicts(
        localNotes: [localA, localB],
        remoteNotes: [remoteA, remoteB],
        lastSyncedAt: base,
        lastSyncedRemoteSha: {'a': shaA, 'b': shaB},
      );
      expect(result, hasLength(1));
      expect(result.first.noteId, 'b');
    });
  });

  group('SyncConflictItem 增强', () {
    final base = DateTime(2026, 8, 23, 12);

    test('localSha / remoteSha / onlyTimestampChanged', () {
      final local = NoteModel(
        id: 'a',
        title: 'A',
        content: 'same',
        updatedAt: base.add(const Duration(hours: 1)),
      );
      final remote = NoteModel(
        id: 'a',
        title: 'A',
        content: 'same',
        updatedAt: base.add(const Duration(hours: 2)),
      );
      final item = SyncConflictItem(local: local, remote: remote);
      expect(item.localSha, item.remoteSha);
      expect(item.onlyTimestampChanged, isTrue);
    });

    test('onlyTimestampChanged 在内容不同时为 false', () {
      final local = NoteModel(
        id: 'a',
        title: 'A',
        content: 'local',
        updatedAt: base.add(const Duration(hours: 1)),
      );
      final remote = NoteModel(
        id: 'a',
        title: 'A',
        content: 'remote',
        updatedAt: base.add(const Duration(hours: 2)),
      );
      final item = SyncConflictItem(local: local, remote: remote);
      expect(item.onlyTimestampChanged, isFalse);
    });

    test('localLeadDuration 本地领先时返回正差', () {
      final local = NoteModel(
        id: 'a',
        title: 'A',
        content: '',
        updatedAt: base.add(const Duration(minutes: 30)),
      );
      final remote = NoteModel(
        id: 'a',
        title: 'A',
        content: '',
        updatedAt: base,
      );
      final item = SyncConflictItem(local: local, remote: remote);
      expect(item.localLeadDuration(null), Duration.zero);
      expect(
        item.localLeadDuration(const Duration(minutes: 5)),
        const Duration(minutes: 30),
      );
    });

    test('localLeadDuration 远端领先时仍返回差值', () {
      final local = NoteModel(
        id: 'a',
        title: 'A',
        content: '',
        updatedAt: base,
      );
      final remote = NoteModel(
        id: 'a',
        title: 'A',
        content: '',
        updatedAt: base.add(const Duration(minutes: 15)),
      );
      final item = SyncConflictItem(local: local, remote: remote);
      expect(
        item.localLeadDuration(const Duration(minutes: 5)),
        const Duration(minutes: 15),
      );
    });
  });
}
