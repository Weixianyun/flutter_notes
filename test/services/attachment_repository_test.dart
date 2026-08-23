import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/data/models/attachment.dart';
import 'package:flutter_notes/services/attachment_repository.dart';
import 'package:flutter_notes/services/attachment_storage.dart';

void main() {
  group('InMemoryAttachmentRepository', () {
    late MemoryAttachmentStorage storage;
    late InMemoryAttachmentRepository repo;

    setUp(() {
      storage = MemoryAttachmentStorage();
      repo = InMemoryAttachmentRepository(storage: storage);
    });

    Future<Attachment> makeAndRegister(String noteId, String name) async {
      final att = await storage.save(
        noteId: noteId,
        fileName: name,
        source: Stream.value(Uint8List.fromList([1, 2, 3])),
      );
      return repo.register(att);
    }

    test('register 后 listByNote 返回', () async {
      final a = await makeAndRegister('n1', 'a.png');
      final list = await repo.listByNote('n1');
      expect(list.length, 1);
      expect(list.first.id, a.id);
    });

    test('不同 note 互不干扰', () async {
      await makeAndRegister('n1', 'a.png');
      // 不同内容 → 不同 sha → 不会被去重
      final b = await storage.save(
        noteId: 'n1',
        fileName: 'b.png',
        source: Stream.value(Uint8List.fromList([4, 5, 6])),
      );
      final regB = await repo.register(b);
      // 把 regB 改归属到 n2（通过新 register）：直接重新注册到 n2 不行
      // 这里改为先 unregister，再以 n2 的归属 register 一个等价的 attachment
      await repo.unregister(regB.id);
      final bForN2 = b.copyWith(noteId: 'n2');
      await repo.register(bForN2);
      final l1 = await repo.listByNote('n1');
      final l2 = await repo.listByNote('n2');
      expect(l1.length, 1);
      expect(l2.length, 1);
      expect(l1.first.fileName, 'a.png');
      expect(l2.first.fileName, 'b.png');
    });

    test('unregister 从列表移除', () async {
      final a = await makeAndRegister('n1', 'a.png');
      await repo.unregister(a.id);
      expect((await repo.listByNote('n1')).isEmpty, isTrue);
    });

    test('delete 同时清理元数据', () async {
      final a = await makeAndRegister('n1', 'a.png');
      final ok = await repo.delete(a.id);
      expect(ok, isTrue);
      expect((await repo.listByNote('n1')).isEmpty, isTrue);
    });

    test('register 重复 id 不会重复入索引', () async {
      final raw = await storage.save(
        noteId: 'n1',
        fileName: 'a.png',
        source: Stream.value(Uint8List.fromList([1, 2, 3])),
      );
      final a = await repo.register(raw);
      await repo.register(a);
      expect((await repo.listByNote('n1')).length, 1);
    });
  });

  group('SharedPrefsAttachmentRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('register + listByNote 跨实例持久', () async {
      final storage = MemoryAttachmentStorage();
      final repo = SharedPrefsAttachmentRepository(storage: storage);
      final raw = await storage.save(
        noteId: 'n1',
        fileName: 'a.png',
        source: Stream.value(Uint8List.fromList([1])),
      );
      final att = await repo.register(raw);
      expect(att.id, isNotEmpty);

      // 模拟第二次启动：新建一个 repo 实例
      final repo2 = SharedPrefsAttachmentRepository(storage: storage);
      final list = await repo2.listByNote('n1');
      expect(list.length, 1);
      expect(list.first.id, att.id);
      expect(list.first.fileName, 'a.png');
    });

    test('delete 跨实例清理', () async {
      final storage = MemoryAttachmentStorage();
      final repo = SharedPrefsAttachmentRepository(storage: storage);
      final raw = await storage.save(
        noteId: 'n1',
        fileName: 'a.png',
        source: Stream.value(Uint8List.fromList([1])),
      );
      final att = await repo.register(raw);
      final ok = await repo.delete(att.id);
      expect(ok, isTrue);
      final list = await repo.listByNote('n1');
      expect(list.isEmpty, isTrue);
    });
  });
}
