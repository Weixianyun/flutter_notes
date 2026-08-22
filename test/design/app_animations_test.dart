import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/core/design/app_animations.dart';

void main() {
  group('SwitchingView - 三态切换', () {
    testWidgets('isLoading=true 时显示 loading 子树', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SwitchingView(
            isLoading: true,
            isEmpty: false,
            content: Text('CONTENT'),
            loading: Text('LOADING'),
            empty: Text('EMPTY'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('LOADING'), findsOneWidget);
      expect(find.text('CONTENT'), findsNothing);
      expect(find.text('EMPTY'), findsNothing);
    });

    testWidgets('isEmpty=true 时显示 empty 子树', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SwitchingView(
            isLoading: false,
            isEmpty: true,
            content: Text('CONTENT'),
            loading: Text('LOADING'),
            empty: Text('EMPTY'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('EMPTY'), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);
      expect(find.text('CONTENT'), findsNothing);
    });

    testWidgets('普通状态显示 content 子树', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SwitchingView(
            isLoading: false,
            isEmpty: false,
            content: Text('CONTENT'),
            loading: Text('LOADING'),
            empty: Text('EMPTY'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CONTENT'), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);
      expect(find.text('EMPTY'), findsNothing);
    });

    testWidgets('loading 优先级高于 empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SwitchingView(
            isLoading: true,
            isEmpty: true,
            content: Text('CONTENT'),
            loading: Text('LOADING'),
            empty: Text('EMPTY'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('LOADING'), findsOneWidget);
      expect(find.text('EMPTY'), findsNothing);
    });

    testWidgets('从 loading 切换到 content 触发 AnimatedSwitcher',
        (tester) async {
      // ignore: prefer_const_constructors
      Widget build({required bool loading}) {
        return MaterialApp(
          home: SwitchingView(
            isLoading: loading,
            isEmpty: false,
            content: const Text('CONTENT'),
            loading: const Text('LOADING'),
            empty: const Text('EMPTY'),
          ),
        );
      }

      await tester.pumpWidget(build(loading: true));
      await tester.pump();
      expect(find.text('LOADING'), findsOneWidget);

      await tester.pumpWidget(build(loading: false));
      await tester.pumpAndSettle();
      expect(find.text('CONTENT'), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);
    });
  });

  group('AppAnimations.listItem - 列表项错位进入', () {
    testWidgets('返回可挂载的 Widget（不抛错）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                AppAnimations.listItem(
                  index: 0,
                  child: const Text('item-0'),
                ),
                AppAnimations.listItem(
                  index: 1,
                  child: const Text('item-1'),
                ),
                AppAnimations.listItem(
                  index: 5,
                  child: const Text('item-5'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-1'), findsOneWidget);
      expect(find.text('item-5'), findsOneWidget);
    });

    testWidgets('index=0 立即可见（无延迟）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.listItem(
              index: 0,
              child: const Text('first'),
            ),
          ),
        ),
      );
      // 首项 0ms 延迟，pump 一次即可看到
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('first'), findsOneWidget);
    });
  });

  group('AppAnimations.iconSwap - 图标切换', () {
    testWidgets('渲染当前图标', (tester) async {
      // ignore: prefer_const_constructors
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.iconSwap(icon: Icons.star),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('切换图标触发 AnimatedSwitcher', (tester) async {
      Widget build(IconData icon) => MaterialApp(
            home: Scaffold(
              body: AppAnimations.iconSwap(icon: icon),
            ),
          );

      await tester.pumpWidget(build(Icons.star));
      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.pumpWidget(build(Icons.favorite));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  group('AppAnimations.pressable - 按下缩放反馈', () {
    testWidgets('无 onTap 时不响应手势且正常显示', (tester) async {
      await tester.pumpWidget(
        // ignore: prefer_const_constructors
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.pressable(
              onTap: null,
              child: const Text('disabled'),
            ),
          ),
        ),
      );
      expect(find.text('disabled'), findsOneWidget);
    });

    testWidgets('点击触发 onTap 回调', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        // ignore: prefer_const_constructors
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.pressable(
              onTap: () => tapped++,
              child: const Text('tap-me'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('tap-me'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('按下时存在 AnimatedScale', (tester) async {
      await tester.pumpWidget(
        // ignore: prefer_const_constructors
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.pressable(
              onTap: () {},
              child: const Text('x'),
            ),
          ),
        ),
      );
      // 初始状态应包含 AnimatedScale（按下/弹起都使用它）
      expect(find.byType(AnimatedScale), findsOneWidget);
    });
  });
}
