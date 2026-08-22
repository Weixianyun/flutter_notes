import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_notes/core/design/app_page_transitions.dart';
import 'package:flutter_notes/core/design/design_tokens.dart';

void main() {
  group('AppPageTransitions - PageRouteBuilder', () {
    testWidgets('fadeUp 默认时长 = AppDurations.medium', (tester) async {
      final route = AppPageTransitions.fadeUp(
        const Scaffold(body: Text('A')),
      );
      expect(route.transitionDuration, AppDurations.medium);
      expect(route.reverseTransitionDuration, AppDurations.medium);

      // 实际渲染也必须不抛错
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(ctx, route),
              child: const Text('push'),
            ),
          ),
        );
      })));
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('zoom 缩放淡入可正常 push', (tester) async {
      final route = AppPageTransitions.zoom(
        const Scaffold(body: Text('zoom-page')),
      );
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(ctx, route),
              child: const Text('push'),
            ),
          ),
        );
      })));
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('zoom-page'), findsOneWidget);
    });

    testWidgets('sharedAxis 共享轴可正常 push', (tester) async {
      final route = AppPageTransitions.sharedAxis(
        const Scaffold(body: Text('axis-page')),
      );
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(ctx, route),
              child: const Text('push'),
            ),
          ),
        );
      })));
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('axis-page'), findsOneWidget);
    });

    testWidgets('可注入自定义 duration', (tester) async {
      final custom = const Duration(milliseconds: 100);
      final route = AppPageTransitions.fadeUp(
        const Scaffold(body: Text('C')),
        duration: custom,
      );
      expect(route.transitionDuration, custom);
      expect(route.reverseTransitionDuration, custom);
    });
  });

  group('AppPageTransitions.sharedAxisPage - go_router 集成', () {
    testWidgets('通过 GoRouter push 该 Page 渲染子页面', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/detail',
            pageBuilder: (_, state) => AppPageTransitions.sharedAxisPage(
              key: state.pageKey,
              child: const Scaffold(body: Text('detail')),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('home'), findsOneWidget);

      router.push('/detail');
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    });
  });

  group('AppPageTransitions - 转场时长与设计 token 一致', () {
    test('默认转场时长引用 AppDurations.medium', () {
      expect(AppDurations.medium, const Duration(milliseconds: 280));
    });
  });
}
