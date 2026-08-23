import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/data/models/attachment.dart';

void main() {
  group('AttachmentKindX.fromMimeOrName', () {
    test('image mime → image', () {
      expect(
        AttachmentKindX.fromMimeOrName(mime: 'image/png', name: 'a.png'),
        AttachmentKind.image,
      );
    });
    test('audio mime → audio', () {
      expect(
        AttachmentKindX.fromMimeOrName(mime: 'audio/mpeg', name: 'a.mp3'),
        AttachmentKind.audio,
      );
    });
    test('video mime → video', () {
      expect(
        AttachmentKindX.fromMimeOrName(mime: 'video/mp4', name: 'a.mp4'),
        AttachmentKind.video,
      );
    });
    test('application/pdf → file', () {
      expect(
        AttachmentKindX.fromMimeOrName(mime: 'application/pdf', name: 'a.pdf'),
        AttachmentKind.file,
      );
    });
    test('未知 mime 但扩展名是 .png → image', () {
      expect(
        AttachmentKindX.fromMimeOrName(mime: null, name: 'photo.png'),
        AttachmentKind.image,
      );
    });
    test('未知 mime + 未知扩展名 → other', () {
      expect(
        AttachmentKindX.fromMimeOrName(mime: null, name: 'foo.xyz'),
        AttachmentKind.other,
      );
    });
  });

  group('Attachment', () {
    final base = Attachment(
      id: 'att-1',
      noteId: 'n-1',
      fileName: 'hello.png',
      relativePath: 'aa/bb.png',
      sha256: 'a' * 64,
      sizeBytes: 1024,
      mimeType: 'image/png',
      kind: AttachmentKind.image,
      createdAt: DateTime(2026, 8, 23),
    );

    test('prettySize 显示 KB', () {
      expect(base.prettySize, '1.0 KB');
    });
    test('prettySize 显示 MB', () {
      final big = base.copyWith(sizeBytes: 5 * 1024 * 1024);
      expect(big.prettySize, '5.0 MB');
    });
    test('prettySize 显示 GB', () {
      final huge = base.copyWith(sizeBytes: 3 * 1024 * 1024 * 1024);
      expect(huge.prettySize, contains('GB'));
    });
    test('prettySize 字节 < 1024 显示 B', () {
      expect(base.copyWith(sizeBytes: 500).prettySize, '500 B');
    });
    test('isImage 与 kind 一致', () {
      expect(base.isImage, isTrue);
      expect(base.copyWith(kind: AttachmentKind.file).isImage, isFalse);
    });

    test('toMap + fromMap 往返一致', () {
      final m = base.toMap();
      final restored = Attachment.fromMap(m);
      expect(restored.id, base.id);
      expect(restored.fileName, base.fileName);
      expect(restored.sha256, base.sha256);
      expect(restored.sizeBytes, base.sizeBytes);
      expect(restored.kind, base.kind);
      expect(restored.width, isNull);
    });

    test('copyWith 仅修改指定字段', () {
      final c = base.copyWith(alt: 'x');
      expect(c.alt, 'x');
      expect(c.fileName, base.fileName);
    });

    test('== 与 hashCode 基于 id', () {
      final a = base;
      final b = base.copyWith(fileName: 'other.png');
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('Attachment.guessMime 推断常见类型', () {
      expect(Attachment.guessMime('a.png'), 'image/png');
      expect(Attachment.guessMime('a.jpg'), 'image/jpeg');
      expect(Attachment.guessMime('a.pdf'), 'application/pdf');
      expect(Attachment.guessMime('noext'), 'application/octet-stream');
    });
  });
}
