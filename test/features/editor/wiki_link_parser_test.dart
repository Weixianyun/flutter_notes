import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/data/models/wiki_link.dart';
import 'package:flutter_notes/features/editor/services/wiki_link_parser.dart';

void main() {
  const parser = WikiLinkParser();

  group('WikiLinkParser 基本语法', () {
    test('空文本返回空列表', () {
      expect(parser.parse(''), isEmpty);
    });

    test('无链接的文本返回空列表', () {
      expect(parser.parse('hello world\nno links here'), isEmpty);
    });

    test('解析 [[Target]]', () {
      final links = parser.parse('see [[Target Note]] please');
      expect(links, hasLength(1));
      expect(links.first.target, 'Target Note');
      expect(links.first.alias, isNull);
      expect(links.first.heading, isNull);
      expect(links.first.start, 4);
      expect(links.first.end, 4 + '[[Target Note]]'.length);
    });

    test('解析 [[Target|Alias]]', () {
      final links = parser.parse('see [[Target Note|display]] please');
      expect(links, hasLength(1));
      expect(links.first.target, 'Target Note');
      expect(links.first.alias, 'display');
      expect(links.first.displayText, 'display');
    });

    test('解析 [[Target#Heading]]', () {
      final links = parser.parse('jump to [[My Note#Section 1]] now');
      expect(links, hasLength(1));
      expect(links.first.target, 'My Note');
      expect(links.first.heading, 'Section 1');
      expect(links.first.displayText, 'My Note#Section 1');
      expect(links.first.destination, 'My Note#Section 1');
    });

    test('解析 [[Target#Heading|Alias]]', () {
      final links = parser.parse('see [[My Note#Section|my alias]]');
      expect(links, hasLength(1));
      expect(links.first.target, 'My Note');
      expect(links.first.heading, 'Section');
      expect(links.first.alias, 'my alias');
      expect(links.first.displayText, 'my alias');
    });

    test('[[Alias]] 的 alias 缺失回退到 destination 显示', () {
      // alias 缺失时 destination 仍是 target#heading
      final links = parser.parse('see [[My Note#Sec]]');
      expect(links, hasLength(1));
      expect(links.first.displayText, 'My Note#Sec');
    });
  });

  group('WikiLinkParser 边界情况', () {
    test('多个链接依次解析', () {
      final text = '链接到 [[A]] 和 [[B]] 还有 [[C|别名]]';
      final links = parser.parse(text);
      expect(links, hasLength(3));
      expect(links.map((l) => l.target), ['A', 'B', 'C']);
      expect(links[2].alias, '别名');
    });

    test('空链接 [[]] 被忽略', () {
      expect(parser.parse('before [[]] after'), isEmpty);
    });

    test('只有 # 后面没有 heading 也允许', () {
      final links = parser.parse('see [[Target#]]');
      expect(links, hasLength(1));
      expect(links.first.target, 'Target');
      expect(links.first.heading, isNull);
    });

    test('未闭合的 [[ 不被解析', () {
      expect(parser.parse('a [[unfinished link text'), isEmpty);
    });

    test('链接内不允许换行，遇到换行终止', () {
      final links = parser.parse('a [[first\nb]] end');
      expect(links, isEmpty);
    });

    test('嵌套 [[ 会终止外层链接', () {
      // 从第二个 [[ 起重新开始匹配
      final text = 'a [[outer [[inner]] tail';
      final links = parser.parse(text);
      expect(links, hasLength(1));
      expect(links.first.target, 'inner');
    });

    test('多余空格被 trim', () {
      final links = parser.parse('see [[  Spaced Target  ]]');
      expect(links, hasLength(1));
      expect(links.first.target, 'Spaced Target');
    });

    test('空 alias 被忽略', () {
      final links = parser.parse('[[Target|]]');
      expect(links, hasLength(1));
      expect(links.first.alias, isNull);
    });
  });

  group('WikiLinkParser.extractTargets', () {
    test('提取去重后的 target 列表（保持首次出现顺序）', () {
      final targets =
          parser.extractTargets('[[A]] and [[B]] and [[A]] and [[C]]');
      expect(targets, ['A', 'B', 'C']);
    });

    test('大小写不敏感去重', () {
      final targets = parser.extractTargets('[[Hello]] [[HELLO]] [[hello]]');
      expect(targets, hasLength(1));
      expect(targets.first, 'Hello');
    });
  });

  group('WikiLink 模型', () {
    test('displayText 优先 alias', () {
      const link = WikiLink(
        target: 'T',
        heading: 'H',
        alias: 'A',
        start: 0,
        end: 0,
      );
      expect(link.displayText, 'A');
    });

    test('displayText 在无 alias 时拼接 target#heading', () {
      const link = WikiLink(
        target: 'T',
        heading: 'H',
        start: 0,
        end: 0,
      );
      expect(link.displayText, 'T#H');
    });

    test('displayText 在都为空时返回 target', () {
      const link = WikiLink(target: 'T', start: 0, end: 0);
      expect(link.displayText, 'T');
    });

    test('destination 拼接 target#heading', () {
      const link = WikiLink(target: 'T', heading: 'H', start: 0, end: 0);
      expect(link.destination, 'T#H');
    });
  });
}
