import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/core/design/app_animations.dart';

void main() {
  group('AppAnimations.noteHeroTag', () {
    test('相同 noteId 产出相同 tag', () {
      expect(AppAnimations.noteHeroTag('abc'), AppAnimations.noteHeroTag('abc'));
    });

    test('不同 noteId 产出不同 tag', () {
      expect(
        AppAnimations.noteHeroTag('abc'),
        isNot(AppAnimations.noteHeroTag('def')),
      );
    });

    test('tag 派生规则可被外部代码稳定依赖（"note-card-" 前缀）', () {
      expect(AppAnimations.noteHeroTag('xyz'), 'note-card-xyz');
    });
  });

  group('AppAnimations.noteHero', () {
    testWidgets('渲染单一 Hero widget 且 tag 一致', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.noteHero(
              noteId: 'note-1',
              child: const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsOneWidget);
      final hero = tester.widget<Hero>(heroFinder);
      expect(hero.tag, 'note-card-note-1');
    });

    testWidgets('在多卡片场景下,各自 tag 独立', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppAnimations.noteHero(
                  noteId: 'a',
                  child: const Text('A'),
                ),
                AppAnimations.noteHero(
                  noteId: 'b',
                  child: const Text('B'),
                ),
              ],
            ),
          ),
        ),
      );

      final heroes = tester.widgetList<Hero>(find.byType(Hero)).toList();
      expect(heroes, hasLength(2));
      final tags = heroes.map((h) => h.tag).toSet();
      expect(tags, containsAll(<Object>['note-card-a', 'note-card-b']));
    });

    testWidgets('noteHeroTag 可与裸 Hero 配对同 tag', (tester) async {
      const noteId = 'pair-test';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: AppAnimations.noteHero(
                    noteId: noteId,
                    child: const SizedBox(width: 50, height: 50),
                  ),
                ),
                Positioned(
                  left: 200,
                  top: 200,
                  child: Hero(
                    tag: AppAnimations.noteHeroTag(noteId),
                    child: const SizedBox(width: 200, height: 100),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsNWidgets(2));
    });
  });

  group('AppAnimations.noteHero 飞行配置', () {
    testWidgets('Hero 使用 MaterialRectArcTween 让 flight 走弧线', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.noteHero(
              noteId: 'arc-test',
              child: const SizedBox(width: 30, height: 30),
            ),
          ),
        ),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
      final tween = hero.createRectTween!(Rect.zero, const Rect.fromLTWH(0, 0, 10, 10));
      expect(tween, isA<MaterialRectArcTween>());
    });

    testWidgets('flightShuttleBuilder 已挂载', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnimations.noteHero(
              noteId: 'shuttle-test',
              child: const SizedBox(width: 30, height: 30),
            ),
          ),
        ),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.flightShuttleBuilder, isNotNull);
    });
  });
}
