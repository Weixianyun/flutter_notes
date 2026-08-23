import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/data/models/attachment.dart';
import 'package:flutter_notes/services/attachment_storage.dart';

void main() {
  group('MemoryAttachmentStorage', () {
    late MemoryAttachmentStorage storage;

    setUp(() {
      storage = MemoryAttachmentStorage();
    });

    test('save 返回含 sha256 的附件', () async {
      final att = await storage.save(
        noteId: 'n1',
        fileName: 'hello.txt',
        source: Stream.value(Uint8List.fromList([1, 2, 3, 4, 5])),
      );
      expect(att.noteId, 'n1');
      expect(att.fileName, 'hello.txt');
      expect(att.sha256.length, 64);
      expect(att.sizeBytes, 5);
      expect(att.kind, AttachmentKind.file);
    });

    test('相同内容两次 save 视为去重（只生成 1 个 sha）', () async {
      final a = await storage.save(
        noteId: 'n1',
        fileName: 'a.png',
        source: Stream.value(Uint8List.fromList([1, 2, 3])),
      );
      final b = await storage.save(
        noteId: 'n1',
        fileName: 'a-copy.png',
        source: Stream.value(Uint8List.fromList([1, 2, 3])),
      );
      expect(b.sha256, a.sha256);
    });

    test('不同内容不同 sha', () async {
      final a = await storage.save(
        noteId: 'n1',
        fileName: 'a.bin',
        source: Stream.value(Uint8List.fromList([1])),
      );
      final b = await storage.save(
        noteId: 'n1',
        fileName: 'b.bin',
        source: Stream.value(Uint8List.fromList([2])),
      );
      expect(a.sha256 == b.sha256, isFalse);
    });

    test('saveFromFile 写入并返回 Attachment', () async {
      final tmp = await Directory.systemTemp.createTemp('att_test_');
      final f = File('${tmp.path}/hello.png');
      await f.writeAsBytes([9, 9, 9, 9]);
      final att = await storage.saveFromFile(noteId: 'n2', file: f);
      expect(att.fileName, 'hello.png');
      expect(att.sha256.length, 64);
      expect(att.kind, AttachmentKind.image);
      await tmp.delete(recursive: true);
    });

    test('findBySha 命中已存附件', () async {
      final a = await storage.save(
        noteId: 'n1',
        fileName: 'x.png',
        source: Stream.value(Uint8List.fromList([7, 7, 7])),
      );
      final found = await storage.findBySha(a.sha256);
      expect(found, isNotNull);
      expect(found!.sha256, a.sha256);
    });

    test('findBySha 未命中返回 null', () async {
      final found = await storage.findBySha('00' * 32);
      expect(found, isNull);
    });

    test('openFile 写出到临时目录', () async {
      final a = await storage.save(
        noteId: 'n1',
        fileName: 'x.bin',
        source: Stream.value(Uint8List.fromList([1, 2, 3])),
      );
      final f = await storage.openFile(a);
      expect(await f.exists(), isTrue);
      final bytes = await f.readAsBytes();
      expect(bytes, [1, 2, 3]);
    });
  });
}
