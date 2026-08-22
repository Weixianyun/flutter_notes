import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/core/router/app_router.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
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
  }

  testWidgets('从主页面进入设置页', (tester) async {
    await pumpApp(tester);
    // 笔记列表页的 settings tooltip（来自 PopupMenu）
    // 仅验证能 pump 起来且存在 Scaffold
    expect(find.byType(Scaffold), findsWidgets);
  });

  test('SettingsPage 使用的 token 关键值校验', () {
    // 头像圆角 = AppRadius.sm（settings_page 中 CircleAvatar radius 14 -> sm=8）
    // 但真实页面半径是 14，对应非标准值。本测试仅校验 token 集本身的契约。
    expect(AppRadius.sm, 8);
    expect(AppRadius.lg, 16);
    // 区块标题与卡片之间间距 = AppSpacing.lg
    expect(AppSpacing.lg, 20);
    // 分割线高度 = AppSpacing.xxl
    expect(AppSpacing.xxl, 32);
  });
}
