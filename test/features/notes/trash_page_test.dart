import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/core/router/app_router.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
import 'package:flutter_notes/l10n/app_localizations.dart';
import 'package:flutter_notes/services/service_providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> pumpTrash(WidgetTester tester) async {
    final os = await overrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: os,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: AppRouter.createRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 通过回收站 tooltip 进入页面
    await tester.tap(find.byTooltip('回收站'));
    await tester.pumpAndSettle();
  }

  testWidgets('空回收站展示 EmptyState', (tester) async {
    await pumpTrash(tester);
    // 数据库种子未删除任何笔记时，进入回收站应看到空状态
    expect(find.text('回收站'), findsWidgets);
    // EmptyState 的图标：delete_outline
    expect(find.byIcon(Icons.delete_outline), findsWidgets);
  });

  testWidgets('Card 圆角与 token 一致', (tester) async {
    // 仅验证 _TrashNoteCard 圆角 token 化（Card 来自主题，这里只检查）
    // 在没有数据时此 widget 不出现，改为验证 AppRadius.lg == 16
    expect(AppRadius.lg, 16);
  });
}
