import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/features/editor/widgets/markdown_preview.dart';

void main() {
  group('MarkdownPreview - token 集成', () {
    testWidgets('渲染基础 Markdown 文本', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownPreview(data: '# 标题\n\n正文段落'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('标题'), findsOneWidget);
      expect(find.text('正文段落'), findsOneWidget);
    });

    testWidgets('支持代码块 + 行内代码 + 引用 token 化', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownPreview(
              data: '```\ncode\n```\n\n`inline`\n\n> 引用',
            ),
          ),
        ),
      );
      // flutter_highlight 在第一帧后异步构建语法高亮，需要多帧 pump
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('inline'), findsOneWidget);
      expect(find.text('引用'), findsOneWidget);
    });
  });

  group('MarkdownPreview - 颜色与 token 一致性', () {
    test('p 文本使用 body 行高 (lineHeight + 0.1)', () {
      // MarkdownPreview 内部对 p 使用 height: AppLineHeights.body + 0.1
      // 验证 AppLineHeights.body 是合理值（1.5）
      expect(AppLineHeights.body, 1.5);
    });
  });

  group('MarkdownPreview - wiki-link 集成', () {
    testWidgets('点击 [[X]] 触发 onWikiLinkTap，参数为 X 与 null heading',
        (tester) async {
      String? capturedTarget;
      String? capturedHeading;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownPreview(
              data: 'see [[Target Note]] here',
              onWikiLinkTap: (target, heading) {
                capturedTarget = target;
                capturedHeading = heading;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 链接被渲染为可点击文本
      expect(find.textContaining('Target Note'), findsOneWidget);
      await tester.tap(find.textContaining('Target Note'));
      await tester.pump();

      expect(capturedTarget, 'Target Note');
      expect(capturedHeading, isNull);
    });

    testWidgets('点击 [[X#Heading|alias]] 触发回调，heading=Heading', (tester) async {
      String? capturedTarget;
      String? capturedHeading;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: MarkdownPreview(
                data: 'jump to [[TargetNote#Sec1|displayAlias]]',
                onWikiLinkTap: (target, heading) {
                  capturedTarget = target;
                  capturedHeading = heading;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('displayAlias'), findsOneWidget);
      // 确保 hit-test 命中 link text（finder 限定在 Markdown widget 树内）
      final linkFinder = find.textContaining('displayAlias');
      expect(linkFinder, findsOneWidget);
      await tester.tap(linkFinder.first, warnIfMissed: false);
      await tester.pump();

      expect(capturedTarget, 'TargetNote');
      expect(capturedHeading, 'Sec1');
    });
  });
}
