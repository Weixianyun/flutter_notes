import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
import 'package:flutter_notes/features/notes/providers/tags_provider.dart';
import 'package:flutter_notes/features/notes/widgets/tag_filter_bar.dart';
import 'package:flutter_notes/l10n/app_localizations.dart';
import 'package:flutter_notes/services/service_providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<List<Override>> overrides() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return [
      appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ];
  }

  testWidgets('TagFilterBar 注入 tag 数据后渲染 chip', (tester) async {
    final os = await overrides();
    final tagsAsync = const AsyncValue.data(<TagInfo>[
      TagInfo(name: 'Flutter', count: 3, color: Colors.blue),
      TagInfo(name: 'Dart', count: 2, color: Colors.teal),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...os,
          allTagsProvider.overrideWith((ref) => tagsAsync),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: TagFilterBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 全部 + 2 个 tag
    expect(find.byType(FilterChip), findsNWidgets(3));
    expect(find.textContaining('Flutter'), findsOneWidget);
    expect(find.textContaining('Dart'), findsOneWidget);
  });

  test('TagFilterBar 使用的 token 关键值', () {
    // chip 圆点大小 = AppRadius.xs * 2
    expect(AppRadius.xs, 4);
    // 水平内边距 = AppSpacing.sm，垂直 = AppSpacing.xxs
    expect(AppSpacing.sm, 12);
    expect(AppSpacing.xxs, 4);
    // 高度 = AppSpacing.xxxl
    expect(AppSpacing.xxxl, 48);
  });
}
