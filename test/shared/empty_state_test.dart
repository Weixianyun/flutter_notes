import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/shared/widgets/empty_state.dart';

void main() {
  group('EmptyState - token 集成', () {
    testWidgets('渲染 icon + title + 可选 subtitle + 可选 action',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_outlined,
              title: '暂无内容',
              subtitle: '点击下方按钮添加',
              actionLabel: '新建',
              onAction: _noop,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.note_outlined), findsOneWidget);
      expect(find.text('暂无内容'), findsOneWidget);
      expect(find.text('点击下方按钮添加'), findsOneWidget);
      expect(find.text('新建'), findsOneWidget);
    });

    testWidgets('无 subtitle / action 时不渲染', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.delete_outline,
              title: '回收站为空',
            ),
          ),
        ),
      );
      expect(find.text('回收站为空'), findsOneWidget);
      // subtitle 缺失时不渲染额外空白
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('AppRadius - 圆角便捷访问器', () {
    test('allXs / allSm / allMd / allLg / allXl 返回 BorderRadius.all',
        () {
      expect(AppRadius.allXs, isA<BorderRadius>());
      expect(AppRadius.allSm, isA<BorderRadius>());
      expect(AppRadius.allMd, isA<BorderRadius>());
      expect(AppRadius.allLg, isA<BorderRadius>());
      expect(AppRadius.allXl, isA<BorderRadius>());
    });
  });
}

void _noop() {}
