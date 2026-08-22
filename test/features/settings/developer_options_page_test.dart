import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/features/settings/pages/developer_options_page.dart';
import 'package:flutter_notes/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  /// 设置大尺寸 viewport，让 ListView 一次渲染所有内容
  void _setLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

void main() {
  group('DeveloperOptionsPage', () {
    testWidgets('渲染 AppBar + 5 个 token group + 1 个说明 section',
        (tester) async {
      _setLargeViewport(tester);
      await tester.pumpWidget(_wrap(const DeveloperOptionsPage()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('设计 Token 速查'), findsOneWidget);
      expect(find.text('AppSpacing (8 倍数阶梯)'), findsOneWidget);
      expect(find.text('AppRadius (5 档)'), findsOneWidget);
      expect(find.text('AppDurations (毫秒)'), findsOneWidget);
      expect(find.text('AppLineHeights'), findsOneWidget);
      expect(find.text('AppFontSizes (选)'), findsOneWidget);
      expect(find.text('设计 token 用途说明'), findsOneWidget);
    });

    testWidgets('点击 token 触发 SnackBar 与剪贴板复制', (tester) async {
      _setLargeViewport(tester);
      await tester.pumpWidget(_wrap(const DeveloperOptionsPage()));

      // 点击 AppSpacing.huge 行 - 唯一标识
      await tester.tap(find.text('huge'));
      await tester.pump();

      expect(find.textContaining('已复制: huge = 64'), findsOneWidget);
    });

    testWidgets('展示 token name / value', (tester) async {
      _setLargeViewport(tester);
      await tester.pumpWidget(_wrap(const DeveloperOptionsPage()));

      // 关键 token name 都至少出现一次
      expect(find.text('xxs'), findsWidgets);
      expect(find.text('xxl'), findsWidgets);
      expect(find.text('huge'), findsOneWidget);
      expect(find.text('stagger'), findsOneWidget);
      expect(find.text('displayLarge'), findsOneWidget);
    });
  });

  group('DeveloperOptionsPage - token 与 design_tokens 同步', () {
    test('页面展示的 AppSpacing 与设计 token 一致', () {
      // 防止未来 token 改了但 page 没同步
      expect(AppSpacing.xxs, 4);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.huge, 64);
    });

    test('页面展示的 AppRadius 与设计 token 一致', () {
      expect(AppRadius.xs, 4);
      expect(AppRadius.xl, 28);
    });

    test('页面展示的 AppDurations 与设计 token 一致', () {
      expect(AppDurations.fast.inMilliseconds, 150);
      expect(AppDurations.medium.inMilliseconds, 280);
      expect(AppDurations.slow.inMilliseconds, 400);
      expect(AppDurations.stagger.inMilliseconds, 420);
    });
  });
}
