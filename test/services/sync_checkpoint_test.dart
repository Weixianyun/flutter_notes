import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/data/models/sync_checkpoint.dart';
import 'package:flutter_notes/services/checkpoint_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SyncCheckpoint 模型', () {
    test('toJsonString / fromJsonString 往返一致', () {
      final now = DateTime.now();
      final cp = SyncCheckpoint(
        id: 'ck-1',
        direction: SyncDirection.both,
        stage: SyncStage.pushing,
        owner: 'octocat',
        repo: 'flutter-notes',
        lastSyncedAt: now.subtract(const Duration(hours: 1)),
        pendingPushIds: const ['n1', 'n2'],
        pendingPullPaths: const ['notes/a.md', 'notes/b.md'],
        pulledRemoteNotes: const {
          'n1': {'id': 'n1', 'title': 'first'},
        },
        completedPushIds: const {'n0'},
        completedPullPaths: const {'notes/z.md'},
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now,
      );

      final round = SyncCheckpoint.fromJsonString(cp.toJsonString());
      expect(round.id, 'ck-1');
      expect(round.direction, SyncDirection.both);
      expect(round.stage, SyncStage.pushing);
      expect(round.owner, 'octocat');
      expect(round.repo, 'flutter-notes');
      expect(round.pendingPushIds, ['n1', 'n2']);
      expect(round.pendingPullPaths, ['notes/a.md', 'notes/b.md']);
      expect(round.completedPushIds, {'n0'});
      expect(round.completedPullPaths, {'notes/z.md'});
      expect(round.pulledRemoteNotes['n1']!['title'], 'first');
    });

    test('progress 在空 checkpoint 时为 1.0', () {
      final cp = SyncCheckpoint(
        id: 'x',
        direction: SyncDirection.pull,
        stage: SyncStage.idle,
        owner: '',
        repo: '',
        lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(0),
        pendingPushIds: const [],
        pendingPullPaths: const [],
        pulledRemoteNotes: const {},
        completedPushIds: const {},
        completedPullPaths: const {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(cp.progress, 1.0);
      expect(cp.hasPendingWork, isFalse);
    });

    test('progress 随 completed 增加而增加', () {
      final base = DateTime.now();
      final cp = SyncCheckpoint(
        id: 'x',
        direction: SyncDirection.both,
        stage: SyncStage.pushing,
        owner: 'o',
        repo: 'r',
        lastSyncedAt: base,
        pendingPushIds: const ['a', 'b'],
        pendingPullPaths: const ['x.md'],
        pulledRemoteNotes: const {},
        completedPushIds: const {'c'},
        completedPullPaths: const {},
        createdAt: base,
        updatedAt: base,
      );
      // 2 push pending + 1 pull pending + 1 push completed = 4 total
      // 1 completed / 4 = 0.25
      expect(cp.progress, closeTo(0.25, 1e-9));
      expect(cp.hasPendingWork, isTrue);
    });

    test('copyWith 保留 id 和 createdAt', () {
      final base = DateTime(2026, 1, 1, 10);
      final cp = SyncCheckpoint(
        id: 'fixed-id',
        direction: SyncDirection.push,
        stage: SyncStage.idle,
        owner: 'o',
        repo: 'r',
        lastSyncedAt: base,
        pendingPushIds: const ['a'],
        pendingPullPaths: const [],
        pulledRemoteNotes: const {},
        completedPushIds: const {},
        completedPullPaths: const {},
        createdAt: base,
        updatedAt: base,
      );
      final next = cp.copyWith(stage: SyncStage.pushing);
      expect(next.id, 'fixed-id');
      expect(next.createdAt, base);
      expect(next.stage, SyncStage.pushing);
    });

    test('fromJsonString 容忍缺失字段（用默认值）', () {
      final cp = SyncCheckpoint.fromJsonString(
        '{"id":"x","direction":"push","stage":"idle","owner":"o","repo":"r","lastSyncedAt":"2026-01-01T00:00:00.000Z","createdAt":"2026-01-01T00:00:00.000Z","updatedAt":"2026-01-01T00:00:00.000Z"}',
      );
      expect(cp.id, 'x');
      expect(cp.direction, SyncDirection.push);
      expect(cp.pendingPushIds, isEmpty);
      expect(cp.pendingPullPaths, isEmpty);
      expect(cp.completedPushIds, isEmpty);
    });
  });

  group('Checkpoint 操作（不依赖 GitHubService）', () {
    test('createCheckpoint 风格的初始结构', () {
      final now = DateTime(2026, 1, 1, 12);
      final cp = SyncCheckpoint(
        id: 'ck-1',
        direction: SyncDirection.both,
        stage: SyncStage.idle,
        owner: 'octo',
        repo: 'notes',
        lastSyncedAt: now,
        pendingPushIds: ['a', 'b'],
        pendingPullPaths: ['notes/x.md'],
        pulledRemoteNotes: const {},
        completedPushIds: const {},
        completedPullPaths: const {},
        createdAt: now,
        updatedAt: now,
      );
      expect(cp.owner, 'octo');
      expect(cp.repo, 'notes');
      expect(cp.lastSyncedAt, now);
      expect(cp.pendingPushIds, ['a', 'b']);
      expect(cp.pendingPullPaths, ['notes/x.md']);
      expect(cp.stage, SyncStage.idle);
    });

    test('markPushCompleted 模式：pending 减少，completed 增加', () {
      final base = DateTime(2026, 1, 1);
      final cp = SyncCheckpoint(
        id: 'ck',
        direction: SyncDirection.push,
        stage: SyncStage.pushing,
        owner: 'o',
        repo: 'r',
        lastSyncedAt: base,
        pendingPushIds: const ['a', 'b', 'c'],
        pendingPullPaths: const [],
        pulledRemoteNotes: const {},
        completedPushIds: const {},
        completedPullPaths: const {},
        createdAt: base,
        updatedAt: base,
      );
      final next = cp.copyWith(
        pendingPushIds: cp.pendingPushIds.where((id) => id != 'a').toList(),
        completedPushIds: {...cp.completedPushIds, 'a'},
        updatedAt: DateTime.now(),
      );
      expect(next.pendingPushIds, ['b', 'c']);
      expect(next.completedPushIds, {'a'});
    });

    test('markPullCompleted 模式：pulledRemoteNotes 累积', () {
      final base = DateTime(2026, 1, 1);
      final cp = SyncCheckpoint(
        id: 'ck',
        direction: SyncDirection.pull,
        stage: SyncStage.pullingContent,
        owner: 'o',
        repo: 'r',
        lastSyncedAt: base,
        pendingPushIds: const [],
        pendingPullPaths: const ['notes/a.md', 'notes/b.md'],
        pulledRemoteNotes: const {},
        completedPushIds: const {},
        completedPullPaths: const {},
        createdAt: base,
        updatedAt: base,
      );
      final pulled = Map<String, Map<String, dynamic>>.from(cp.pulledRemoteNotes);
      pulled['n1'] = {'id': 'n1', 'title': 'A', 'remotePath': 'notes/a.md'};
      final next = cp.copyWith(
        pendingPullPaths: cp.pendingPullPaths.where((p) => p != 'notes/a.md').toList(),
        completedPullPaths: {...cp.completedPullPaths, 'notes/a.md'},
        pulledRemoteNotes: pulled,
        updatedAt: DateTime.now(),
      );
      expect(next.pendingPullPaths, ['notes/b.md']);
      expect(next.completedPullPaths, {'notes/a.md'});
      expect(next.pulledRemoteNotes['n1']!['remotePath'], 'notes/a.md');
    });
  });

  group('SharedPrefsCheckpointStore', () {
    late SharedPreferences prefs;
    late SharedPrefsCheckpointStore store;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = SharedPrefsCheckpointStore(prefs);
    });

    test('初始 load 返回 null', () {
      expect(store.load(), isNull);
    });

    test('save 后 load 往返', () async {
      final base = DateTime(2026, 1, 1);
      final cp = SyncCheckpoint(
        id: 'ck-1',
        direction: SyncDirection.push,
        stage: SyncStage.idle,
        owner: 'o',
        repo: 'r',
        lastSyncedAt: base,
        pendingPushIds: const ['a'],
        pendingPullPaths: const [],
        pulledRemoteNotes: const {},
        completedPushIds: const {},
        completedPullPaths: const {},
        createdAt: base,
        updatedAt: base,
      );
      await store.save(cp);
      final loaded = store.load();
      expect(loaded, isNotNull);
      expect(loaded!.id, 'ck-1');
      expect(loaded.owner, 'o');
      expect(loaded.lastSyncedAt, base);
      expect(loaded.pendingPushIds, ['a']);
    });

    test('clear 后 load 返回 null', () async {
      final base = DateTime(2026, 1, 1);
      final cp = SyncCheckpoint(
        id: 'ck',
        direction: SyncDirection.push,
        stage: SyncStage.idle,
        owner: 'o',
        repo: 'r',
        lastSyncedAt: base,
        pendingPushIds: const [],
        pendingPullPaths: const [],
        pulledRemoteNotes: const {},
        completedPushIds: const {},
        completedPullPaths: const {},
        createdAt: base,
        updatedAt: base,
      );
      await store.save(cp);
      await store.clear();
      expect(store.load(), isNull);
    });

    test('损坏的 JSON 解析失败时返回 null', () async {
      await prefs.setString('sync_checkpoint_v1', 'not-json{');
      expect(store.load(), isNull);
    });
  });
}
