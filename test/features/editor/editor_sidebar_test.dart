import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/features/editor/services/backlink_index.dart';
import 'package:flutter_notes/features/editor/widgets/editor_sidebar.dart';

NoteModel _note(String id, String title, String content) {
  return NoteModel(
    id: id,
    title: title,
    content: content,
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('EditorSidebar - 容器渲染', () {
    testWidgets('展示两个 Tab：大纲 + 反向', (tester) async {
      final index = BacklinkIndex(const <NoteModel>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorSidebar(
              content: '# A\n## B',
              targetTitle: 'A',
              index: index,
            ),
          ),
        ),
      );

      expect(find.text('大纲'), findsOneWidget);
      expect(find.text('反向'), findsOneWidget);
    });

    testWidgets('默认显示 outline 列表（第一 tab）', (tester) async {
      final index = BacklinkIndex(const <NoteModel>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 400,
              child: EditorSidebar(
                content: '# A\n## B',
                targetTitle: 'A',
                index: index,
              ),
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('切到反向 Tab 显示空状态文案', (tester) async {
      final index = BacklinkIndex(const <NoteModel>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 400,
              child: EditorSidebar(
                content: '# Title',
                targetTitle: 'Lonely',
                index: index,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('反向'));
      await tester.pumpAndSettle();

      expect(find.textContaining('暂无反向链接'), findsOneWidget);
    });

    testWidgets('有反向链接时切到反向 Tab 显示源笔记条目', (tester) async {
      final a = _note('a', 'Source A', 'ref [[Target]]');
      final b = _note('b', 'Source B', 'also ref [[Target]]');
      final index = BacklinkIndex([a, b]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 400,
              child: EditorSidebar(
                content: '# Target',
                targetTitle: 'Target',
                index: index,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('反向'));
      await tester.pumpAndSettle();

      expect(find.text('Source A'), findsOneWidget);
      expect(find.text('Source B'), findsOneWidget);
    });
  });

  group('EditorSidebar - 交互回调', () {
    testWidgets('点击 outline 节点触发 onJumpToOffset', (tester) async {
      final index = BacklinkIndex(const <NoteModel>[]);
      int? jumpedOffset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 400,
              child: EditorSidebar(
                content: '# Title\n\nbody',
                targetTitle: 'Title',
                index: index,
                onJumpToOffset: (offset) => jumpedOffset = offset,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();

      expect(jumpedOffset, isNotNull);
      expect(jumpedOffset, 0);
    });

    testWidgets('点击 backlink 条目触发 onOpenSource', (tester) async {
      final source = _note('src', 'My Source', 'ref [[Target]]');
      final index = BacklinkIndex([source]);
      BacklinkEntry? opened;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 400,
              child: EditorSidebar(
                content: '# Target',
                targetTitle: 'Target',
                index: index,
                onOpenSource: (entry) => opened = entry,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('反向'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Source'));
      await tester.pumpAndSettle();

      expect(opened, isNotNull);
      expect(opened!.sourceNoteId, 'src');
      expect(opened!.link.target, 'Target');
    });
  });
}
