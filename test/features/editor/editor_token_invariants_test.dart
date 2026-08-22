import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/data/database/app_database.dart';
import 'package:flutter_notes/data/database/database_provider.dart';
import 'package:flutter_notes/l10n/app_localizations.dart';
import 'package:flutter_notes/services/service_providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('编辑器页面引用的 token 关键值契约', () {
    // AppBar 标题字号 = AppFontSizes.titleLarge
    expect(AppFontSizes.titleLarge, 22);
    // 输入框内边距 = AppSpacing.md
    expect(AppSpacing.md, 16);
    // 工具栏按钮尺寸 = 32（spacedBy AppSpacing.xs）
    expect(AppSpacing.xs, 8);
    // 卡片圆角 = AppRadius.md
    expect(AppRadius.md, 12);
  });

  testWidgets('Editor 占位 Scaffold 可构建', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting()),
          sharedPreferencesProvider.overrideWithValue(prefs),
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
          home: const Scaffold(body: Center(child: Text('editor-stub'))),
        ),
      ),
    );
    expect(find.text('editor-stub'), findsOneWidget);
  });
}
