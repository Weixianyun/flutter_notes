import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/features/editor/services/outline_service.dart';

void main() {
  const svc = OutlineService();

  group('OutlineService 基础解析', () {
    test('空文本返回空列表', () {
      expect(svc.extract(''), isEmpty);
      expect(svc.flatten(''), isEmpty);
      expect(svc.count(''), 0);
    });

    test('无 heading 的文本返回空列表', () {
      const text = 'just a paragraph\nanother line\n#notHeading\n #alsoNot';
      expect(svc.extract(text), isEmpty);
    });

    test('解析单个 h1', () {
      const text = '# Title\n\nbody';
      final roots = svc.extract(text);
      expect(roots, hasLength(1));
      expect(roots.first.level, 1);
      expect(roots.first.title, 'Title');
      expect(roots.first.depth, 0);
      expect(roots.first.children, isEmpty);
    });

    test('解析 h1..h6', () {
      const text = '# A\n## B\n### C\n#### D\n##### E\n###### F';
      final flat = svc.flatten(text);
      expect(flat.map((n) => n.level), [1, 2, 3, 4, 5, 6]);
      expect(flat.map((n) => n.title), ['A', 'B', 'C', 'D', 'E', 'F']);
    });

    test('# 后必须有空格（否则不算 heading）', () {
      const text = '#notHeading\n# Real Heading';
      final flat = svc.flatten(text);
      expect(flat, hasLength(1));
      expect(flat.first.title, 'Real Heading');
    });

    test('超过 6 个 # 视为普通文本', () {
      const text = '####### Too Deep\n# Real';
      final flat = svc.flatten(text);
      expect(flat, hasLength(1));
      expect(flat.first.title, 'Real');
    });

    test('空标题被忽略（仅有 # 与空白）', () {
      const text = '# \n# \n# Real';
      final flat = svc.flatten(text);
      expect(flat, hasLength(1));
      expect(flat.first.title, 'Real');
    });

    test('行内首尾 # 兼容（# Title #）', () {
      const text = '# Title #';
      final flat = svc.flatten(text);
      expect(flat, hasLength(1));
      expect(flat.first.title, 'Title');
    });
  });

  group('OutlineService 嵌套结构', () {
    test('按 level 正确建树', () {
      const text = '# A\n## A1\n## A2\n### A2a\n# B';
      final roots = svc.extract(text);
      expect(roots, hasLength(2));
      expect(roots[0].title, 'A');
      expect(roots[0].children, hasLength(2));
      expect(roots[0].children[0].title, 'A1');
      expect(roots[0].children[0].children, isEmpty);
      expect(roots[0].children[1].title, 'A2');
      expect(roots[0].children[1].children, hasLength(1));
      expect(roots[0].children[1].children[0].title, 'A2a');
      expect(roots[1].title, 'B');
    });

    test('同级跃迁正确弹栈', () {
      const text = '## A\n# B\n## C';
      final roots = svc.extract(text);
      expect(roots, hasLength(2));
      expect(roots[0].title, 'A');
      expect(roots[1].title, 'B');
      expect(roots[1].children, hasLength(1));
      expect(roots[1].children.first.title, 'C');
    });

    test('反向跃迁（从 h3 回到 h1）正确弹栈', () {
      const text = '### A\n# B\n## C';
      final roots = svc.extract(text);
      expect(roots, hasLength(2));
      // A 应该作为根节点（因为没有任何更高级 heading）
      expect(roots[0].title, 'A');
      expect(roots[0].level, 3);
      expect(roots[1].title, 'B');
      expect(roots[1].children.first.title, 'C');
    });

    test('depth 与 children 层级一致', () {
      const text = '# A\n## B\n### C\n# D\n## E';
      final flat = svc.flatten(text);
      final depths = flat.map((n) => n.depth).toList();
      expect(depths, [0, 1, 2, 0, 1]);
    });
  });

  group('OutlineService offset 校验', () {
    test('startOffset / endOffset 正确指向原文', () {
      const text = 'preamble\n# Title\nbody';
      final flat = svc.flatten(text);
      expect(flat, hasLength(1));
      // 9 = 'preamble\n' 长度
      expect(flat.first.startOffset, 9);
      expect(flat.first.endOffset, 9 + '# Title'.length);
      // 抽取的切片应该是 '# Title'
      expect(text.substring(flat.first.startOffset, flat.first.endOffset),
          '# Title');
    });
  });

  group('OutlineService count / flatten', () {
    test('count 包含嵌套', () {
      const text = '# A\n## B\n### C\n# D';
      expect(svc.count(text), 4);
    });

    test('flatten 按文档顺序', () {
      const text = '## B\n# A\n### C';
      final flat = svc.flatten(text);
      expect(flat.map((n) => n.title), ['B', 'A', 'C']);
    });
  });
}
