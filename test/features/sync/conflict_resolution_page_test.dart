import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/features/sync/pages/conflict_resolution_page.dart';
import 'package:flutter_notes/features/sync/providers/sync_provider.dart';
import 'package:flutter_notes/l10n/app_localizations.dart';
import 'package:flutter_notes/services/service_providers.dart';
import 'package:flutter_notes/services/sync_service.dart';

NoteModel _makeNote(
  String id, {
  required DateTime updatedAt,
  String title = 'T',
  String content = '',
}) {
  return NoteModel(
    id: id,
    title: title,
    content: content,
    updatedAt: updatedAt,
  );
}

Future<List<Override>> _baseOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
}

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  group('ConflictResolutionPage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('空冲突状态展示空态视图', (tester) async {
      final overrides = await _baseOverrides();
      await tester.pumpWidget(_wrap(
        const ConflictResolutionPage(),
        overrides,
      ));
      await tester.pumpAndSettle();
      expect(find.text('当前没有需要解决的冲突'), findsOneWidget);
      expect(find.text('返回'), findsOneWidget);
    });

    testWidgets('展示冲突标题与本地/远端/跳过三个选项',
        (tester) async {
      final base = DateTime(2026, 8, 23, 10);
      final local = _makeNote('a', updatedAt: base, content: '本地正文');
      final remote = _makeNote('a', updatedAt: base.add(const Duration(hours: 1)), content: '远端正文');
      final conflict = SyncConflictItem(local: local, remote: remote);

      final overrides = await _baseOverrides();
      late _FakeSyncNotifier notifier;
      await tester.pumpWidget(_wrap(
        const ConflictResolutionPage(),
        [
          ...overrides,
          syncProvider.overrideWith((ref) {
            notifier = _FakeSyncNotifier(ref, conflicts: [conflict]);
            return notifier;
          }),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('冲突解决 (1)'), findsOneWidget);
      expect(find.text('本地版本'), findsOneWidget);
      expect(find.text('远端版本'), findsOneWidget);
      expect(find.text('跳过（暂不处理）'), findsOneWidget);
      expect(find.text('本地正文'), findsOneWidget);
      expect(find.text('远端正文'), findsOneWidget);
    });

    testWidgets('点击本地版本选项后 pendingResolutions 记录 localWins',
        (tester) async {
      final base = DateTime(2026, 8, 23, 10);
      final local = _makeNote('a', updatedAt: base, content: 'L');
      final remote = _makeNote('a', updatedAt: base.add(const Duration(hours: 1)), content: 'R');
      final conflict = SyncConflictItem(local: local, remote: remote);

      final overrides = await _baseOverrides();
      late _FakeSyncNotifier notifier;
      await tester.pumpWidget(_wrap(
        const ConflictResolutionPage(),
        [
          ...overrides,
          syncProvider.overrideWith((ref) {
            notifier = _FakeSyncNotifier(ref, conflicts: [conflict]);
            return notifier;
          }),
        ],
      ));
      await tester.pumpAndSettle();

      // 点击"本地版本"卡
      await tester.tap(find.text('本地版本'));
      await tester.pump();

      expect(notifier.lastSetNoteId, 'a');
      expect(notifier.lastSetResolution, ConflictResolution.localWins);
    });

    testWidgets('点击"全部跳过"清空所有 pendingResolutions', (tester) async {
      final base = DateTime(2026, 8, 23, 10);
      final c1 = SyncConflictItem(
        local: _makeNote('a', updatedAt: base),
        remote: _makeNote('a', updatedAt: base.add(const Duration(hours: 1))),
      );
      final c2 = SyncConflictItem(
        local: _makeNote('b', updatedAt: base),
        remote: _makeNote('b', updatedAt: base.add(const Duration(hours: 1))),
      );

      final overrides = await _baseOverrides();
      late _FakeSyncNotifier notifier;
      await tester.pumpWidget(_wrap(
        const ConflictResolutionPage(),
        [
          ...overrides,
          syncProvider.overrideWith((ref) {
            notifier = _FakeSyncNotifier(
              ref,
              conflicts: [c1, c2],
              seeded: const {'a': ConflictResolution.localWins},
            );
            return notifier;
          }),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('全部跳过'));
      await tester.pump();

      // 跳过会逐个 remove
      expect(notifier.skipCallCount, greaterThanOrEqualTo(2));
    });
  });
}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(
    super.ref, {
    required this.conflicts,
    Map<String, ConflictResolution>? seeded,
  }) {
    state = state.copyWith(
      conflicts: conflicts,
      pendingResolutions:
          Map<String, ConflictResolution>.from(seeded ?? const {}),
    );
  }

  final List<SyncConflictItem> conflicts;
  String? lastSetNoteId;
  ConflictResolution? lastSetResolution;
  int skipCallCount = 0;

  @override
  void setResolution(String noteId, ConflictResolution resolution) {
    lastSetNoteId = noteId;
    lastSetResolution = resolution;
    if (resolution == ConflictResolution.skip) {
      skipCallCount++;
      final next = Map<String, ConflictResolution>.from(state.pendingResolutions);
      next.remove(noteId);
      state = state.copyWith(pendingResolutions: next);
    } else {
      final next = Map<String, ConflictResolution>.from(state.pendingResolutions);
      next[noteId] = resolution;
      state = state.copyWith(pendingResolutions: next);
    }
  }

  @override
  void clearConflicts() {
    state = state.copyWith(
      conflicts: const <SyncConflictItem>[],
      pendingResolutions: const <String, ConflictResolution>{},
    );
  }
}
