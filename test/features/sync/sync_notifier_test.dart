import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/features/notes/providers/notes_provider.dart';
import 'package:flutter_notes/features/sync/providers/sync_provider.dart';
import 'package:flutter_notes/services/crypto_service.dart';
import 'package:flutter_notes/services/github_service.dart';
import 'package:flutter_notes/services/service_providers.dart';
import 'package:flutter_notes/services/sync_service.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _NoopSyncService mockSvc;

  // 保留 container 引用以避免 lint 警告（dispose 内部完成）
  // ignore: unused_local_variable
  late ProviderContainer container;

  Future<ProviderContainer> makeContainer({
    bool failPush = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting();
    final crypto = EncryptionService(prefs);
    final encrypted = crypto.encrypt('test-token');
    await prefs.setString('github_encrypted_token', encrypted);
    await prefs.setString('sync_repo_owner', 'octo');
    await prefs.setString('sync_repo_name', 'notes');

    mockSvc = _NoopSyncService(
      _FakeGitHub(),
      'token',
      failPush: failPush,
    );

    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        syncServiceProvider.overrideWithValue(mockSvc),
      ],
    );
    container = c;
    return c;
  }

  tearDown(() async {
    await db.close();
  });

  group('SyncNotifier 状态转换', () {
    late ProviderContainer c;
    setUp(() async {
      c = await makeContainer();
    });
    tearDown(() => c.dispose());

    test('clearConflicts 清空 conflicts 与 pendingResolutions', () {
      final notifier = c.read(syncProvider.notifier);
      final conflict = SyncConflictItem(
        local: NoteModel(id: 'a', title: 'A', content: ''),
        remote: NoteModel(id: 'a', title: 'A', content: 'r'),
      );
      notifier.state = notifier.state.copyWith(
        conflicts: [conflict],
        pendingResolutions: const {'a': ConflictResolution.localWins},
      );
      notifier.clearConflicts();
      expect(notifier.state.conflicts, isEmpty);
      expect(notifier.state.pendingResolutions, isEmpty);
    });

    test('setResolution 在 skip 时移除记录', () {
      final notifier = c.read(syncProvider.notifier);
      notifier.setResolution('a', ConflictResolution.localWins);
      expect(
        notifier.state.pendingResolutions['a'],
        ConflictResolution.localWins,
      );
      notifier.setResolution('a', ConflictResolution.skip);
      expect(notifier.state.pendingResolutions.containsKey('a'), isFalse);
    });

    test('setResolution 重复设置会覆盖前值', () {
      final notifier = c.read(syncProvider.notifier);
      notifier.setResolution('a', ConflictResolution.localWins);
      notifier.setResolution('a', ConflictResolution.remoteWins);
      expect(
        notifier.state.pendingResolutions['a'],
        ConflictResolution.remoteWins,
      );
    });
  });

  group('SyncNotifier.applyResolutions', () {
    Future<void> seedNote(ProviderContainer c) async {
      await db.into(db.notes).insert(NotesCompanion(
            id: const Value('a'),
            title: const Value('本地原标题'),
            content: const Value('本地原内容'),
            priority: const Value('medium'),
            status: const Value('draft'),
            tags: const Value('[]'),
            createdAt: Value(DateTime(2026, 1, 1)),
            updatedAt: Value(DateTime(2026, 1, 1, 10)),
          ));
    }

    test('没有 pendingResolutions 时直接返回', () async {
      final c = await makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(syncProvider.notifier);
      final result = await notifier.applyResolutions();
      expect(result.localWins, 0);
      expect(result.remoteWins, 0);
      expect(result.skipped, 0);
      expect(result.errors, isEmpty);
    });

    test('localWins 写本地 + 推 GitHub', () async {
      final c = await makeContainer();
      addTearDown(c.dispose);
      await seedNote(c);
      final notifier = c.read(syncProvider.notifier);
      final conflict = SyncConflictItem(
        local: NoteModel(
          id: 'a',
          title: '本地新标题',
          content: '本地新内容',
          updatedAt: DateTime(2026, 1, 2, 10),
        ),
        remote: NoteModel(
          id: 'a',
          title: '远端标题',
          content: '远端内容',
          updatedAt: DateTime(2026, 1, 2, 11),
        ),
      );
      notifier.state = notifier.state.copyWith(
        conflicts: [conflict],
        pendingResolutions: const {'a': ConflictResolution.localWins},
      );
      final result = await notifier.applyResolutions();
      expect(result.localWins, 1);
      expect(result.remoteWins, 0);
      expect(mockSvc.pushedCount, 1);
      final repo = c.read(noteRepositoryProvider);
      final stored = await repo.getNoteById('a');
      expect(stored?.title, '本地新标题');
    });

    test('remoteWins 直接覆盖本地', () async {
      final c = await makeContainer();
      addTearDown(c.dispose);
      await seedNote(c);
      final notifier = c.read(syncProvider.notifier);
      final conflict = SyncConflictItem(
        local: NoteModel(
          id: 'a',
          title: '本地标题',
          content: '本地内容',
          updatedAt: DateTime(2026, 1, 2, 10),
        ),
        remote: NoteModel(
          id: 'a',
          title: '远端标题',
          content: '远端内容',
          updatedAt: DateTime(2026, 1, 2, 11),
        ),
      );
      notifier.state = notifier.state.copyWith(
        conflicts: [conflict],
        pendingResolutions: const {'a': ConflictResolution.remoteWins},
      );
      final result = await notifier.applyResolutions();
      expect(result.localWins, 0);
      expect(result.remoteWins, 1);
      expect(mockSvc.pushedCount, 0);
      final repo = c.read(noteRepositoryProvider);
      final stored = await repo.getNoteById('a');
      expect(stored?.title, '远端标题');
    });

    test('push 失败时计入 errors 且本地仍写回', () async {
      final c = await makeContainer(failPush: true);
      addTearDown(c.dispose);
      await seedNote(c);
      final notifier = c.read(syncProvider.notifier);
      final conflict = SyncConflictItem(
        local: NoteModel(
          id: 'a',
          title: '本地标题',
          content: '本地内容',
          updatedAt: DateTime(2026, 1, 2),
        ),
        remote: NoteModel(
          id: 'a',
          title: '远端标题',
          content: '远端内容',
          updatedAt: DateTime(2026, 1, 2, 11),
        ),
      );
      notifier.state = notifier.state.copyWith(
        conflicts: [conflict],
        pendingResolutions: const {'a': ConflictResolution.localWins},
      );
      final result = await notifier.applyResolutions();
      expect(result.localWins, 0);
      expect(result.errors, isNotEmpty);
      final repo = c.read(noteRepositoryProvider);
      final stored = await repo.getNoteById('a');
      expect(stored?.title, '本地标题');
    });
  });
}

class _FakeGitHub implements GitHubService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _NoopSyncService extends SyncService {
  _NoopSyncService(super.github, super.token, {this.failPush = false});

  final bool failPush;
  int pushedCount = 0;

  @override
  Future<void> pushNote({
    required String owner,
    required String repo,
    required NoteModel note,
  }) async {
    if (failPush) {
      throw Exception('simulated push failure');
    }
    pushedCount++;
  }
}
