import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/data/models/attachment.dart';
import 'package:flutter_notes/features/attachments/models/attachment_ref.dart';

void main() {
  const parser = AttachmentRefParser();

  group('AttachmentRefParser.parse', () {
    test('解析 attachment://<id>', () {
      final r = parser.parse('attachment://abc-123');
      expect(r, isNotNull);
      expect(r!.attachmentId, 'abc-123');
      expect(r.isImage, isFalse);
    });

    test('解析 attachment://<id>?name=foo.png → image', () {
      final r = parser.parse('attachment://xyz?name=foo.png');
      expect(r, isNotNull);
      expect(r!.isImage, isTrue);
      expect(r.alt, 'foo.png');
    });

    test('空 src 返回 null', () {
      expect(parser.parse(''), isNull);
    });

    test('非 attachment scheme 返回 null', () {
      expect(parser.parse('https://example.com/a.png'), isNull);
    });
  });

  group('AttachmentRefParser.extractAll', () {
    test('提取图片与文件两种引用', () {
      const text = '''
Here is an image ![](attachment://img1?name=a.png)
and a [download](attachment://doc1?name=doc.pdf).
''';
      final refs = parser.extractAll(text);
      expect(refs.length, 2);
      expect(refs[0].isImage, isTrue);
      expect(refs[0].attachmentId, 'img1');
      expect(refs[1].isImage, isFalse);
      expect(refs[1].attachmentId, 'doc1');
    });

    test('不提取普通 http 链接', () {
      const text = '[a](https://example.com) and ![](attachment://img1)';
      final refs = parser.extractAll(text);
      expect(refs.length, 1);
      expect(refs.first.attachmentId, 'img1');
    });
  });

  group('AttachmentRefParser.insert', () {
    test('在指定 offset 插入图片 markdown', () {
      final att = Attachment(
        id: 'id1',
        noteId: 'n',
        fileName: 'a.png',
        relativePath: 'a.png',
        sha256: 'x' * 64,
        sizeBytes: 100,
        mimeType: 'image/png',
        kind: AttachmentKind.image,
        createdAt: DateTime(2026, 1, 1),
      );
      const text = 'before  after';
      final out = parser.insert(text, 7, att);
      expect(out, contains('![a.png](attachment://id1?name=a.png)'));
      expect(out.startsWith('before '), isTrue);
    });

    test('图片不带 alt 退化为文件名', () {
      final att = Attachment(
        id: 'id2',
        noteId: 'n',
        fileName: 'doc.pdf',
        relativePath: 'd.pdf',
        sha256: 'y' * 64,
        sizeBytes: 100,
        mimeType: 'application/pdf',
        kind: AttachmentKind.file,
        createdAt: DateTime(2026, 1, 1),
      );
      const text = '';
      final out = parser.insert(text, 0, att);
      expect(out, contains('[doc.pdf](attachment://id2?name=doc.pdf)'));
    });
  });

  test('labelFor 在 alt 为空时退化为文件名或 id', () {
    expect(parser.labelFor(
        const AttachmentRef(attachmentId: 'x', alt: '', isImage: false),
        null), '附件 x');
    final att = Attachment(
      id: 'x',
      noteId: 'n',
      fileName: 'a.png',
      relativePath: 'a.png',
      sha256: 'z' * 64,
      sizeBytes: 1,
      mimeType: 'image/png',
      kind: AttachmentKind.image,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(
        parser.labelFor(
            const AttachmentRef(attachmentId: 'x', alt: '', isImage: false),
            att),
        'a.png');
  });

  test('fileNameFromSrc 抽取 name 参数', () {
    expect(parser.fileNameFromSrc('attachment://i?name=foo.png'), 'foo.png');
    expect(parser.fileNameFromSrc('attachment://i'), '');
  });
}
