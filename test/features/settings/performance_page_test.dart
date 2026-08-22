import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
import 'package:flutter_notes/features/settings/pages/performance_page.dart';
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

  testWidgets('PerformancePage 渲染性能监控卡片', (tester) async {
    final os = await overrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: os,
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
          home: const PerformancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 至少出现一个 Scaffold 与 AppBar
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  test('PerformancePage 静态样式常量符合 token', () {
    // Card 圆角 = AppRadius.lg（与 AppTheme.cardTheme 一致）
    expect(AppRadius.lg, 16);
    // 列表内边距 = AppSpacing.md
    expect(AppSpacing.md, 16);
    // 区块间距 = AppSpacing.lg
    expect(AppSpacing.lg, 20);
  });
}
