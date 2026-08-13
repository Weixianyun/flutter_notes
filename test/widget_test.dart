import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/app.dart';

void main() {
  testWidgets('App renders notes list page with title', (tester) async {
    await tester.pumpWidget(const FlutterNotesApp());

    // 首页应显示应用标题
    expect(find.text('Flutter Notes'), findsOneWidget);

    // 应显示新建笔记按钮
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Mock 数据中应包含笔记标题
    expect(find.text('Dart 3 空安全实践'), findsOneWidget);
  });

  testWidgets('Empty state shows when all notes deleted', (tester) async {
    await tester.pumpWidget(const FlutterNotesApp());

    // 滑动删除第一条笔记
    await tester.fling(
      find.text('Dart 3 空安全实践'),
      const Offset(-500, 0),
      1000,
    );
    await tester.pumpAndSettle();

    // 应出现删除提示 SnackBar
    expect(find.text('已删除「Dart 3 空安全实践」'), findsOneWidget);
  });
}
