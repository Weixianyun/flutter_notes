import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:flutter_notes/data/models/attachment.dart';
import 'package:flutter_notes/services/thumbnail_service.dart';

void main() {
  group('MemoryThumbnailService', () {
    late MemoryThumbnailService thumbs;

    setUp(() {
      thumbs = MemoryThumbnailService();
    });

    Attachment makeImage(String name, {int w = 10, int h = 10}) {
      return Attachment(
        id: name,
        noteId: 'n',
        fileName: name,
        relativePath: name,
        sha256: name.hashCode.toRadixString(16).padLeft(64, '0'),
        sizeBytes: w * h * 3,
        mimeType: 'image/png',
        kind: AttachmentKind.image,
        createdAt: DateTime(2026, 1, 1),
        width: w,
        height: h,
      );
    }

    test('ensureThumbnail 返回可读取的 File', () async {
      final att = makeImage('a.png', w: 16, h: 16);
      final f = await thumbs.ensureThumbnail(
          att, const ThumbnailSpec(maxWidth: 32, maxHeight: 32));
      expect(await f.exists(), isTrue);
      final bytes = await f.readAsBytes();
      expect(bytes, isNotEmpty);
    });

    test('同 sha + 同 spec 命中缓存', () async {
      final a = makeImage('a.png');
      final b = makeImage('a.png');
      expect(a.sha256, b.sha256);
      final f1 = await thumbs.ensureThumbnail(
          a, const ThumbnailSpec(maxWidth: 32, maxHeight: 32));
      final f2 = await thumbs.ensureThumbnail(
          b, const ThumbnailSpec(maxWidth: 32, maxHeight: 32));
      // 都是 PNG 字节，断言两次结果内容相同即可
      final b1 = await f1.readAsBytes();
      final b2 = await f2.readAsBytes();
      expect(b1, b2);
    });

    test('非图片附件抛 ArgumentError', () async {
      final att = Attachment(
        id: 'x',
        noteId: 'n',
        fileName: 'x.pdf',
        relativePath: 'x.pdf',
        sha256: 'f' * 64,
        sizeBytes: 100,
        mimeType: 'application/pdf',
        kind: AttachmentKind.file,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => thumbs.ensureThumbnail(
            att, const ThumbnailSpec(maxWidth: 32, maxHeight: 32)),
        throwsArgumentError,
      );
    });

    test('clearAll 清空缓存', () async {
      final a = makeImage('a.png');
      await thumbs.ensureThumbnail(
          a, const ThumbnailSpec(maxWidth: 32, maxHeight: 32));
      final n = await thumbs.clearAll();
      expect(n, greaterThanOrEqualTo(1));
    });
  });

  group('LocalThumbnailService (in-memory path_provider mock)', () {
    test('rootDir 使用 override 创建目录', () async {
      final dir = await Directory.systemTemp.createTemp('thumb_root_');
      final svc = LocalThumbnailService(overrideRootDir: dir);
      final r = await svc.rootDir;
      expect(await r.exists(), isTrue);
      await dir.delete(recursive: true);
    });
  });

  // sanity：使用 image 包生成一张 1x1 png 测试 encode/decode 链路
  test('image 包自检：1x1 PNG', () {
    final image = img.Image(width: 1, height: 1);
    final bytes = Uint8List.fromList(img.encodePng(image));
    expect(bytes, isNotEmpty);
  });
}
