import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/models/attachment.dart';
import 'attachment_storage.dart';

/// 附件仓库接口
///
/// 负责 [Attachment] 的元数据持久化与查询。物理文件由 [AttachmentStorage] 负责。
abstract class AttachmentRepository {
  /// 列出属于某笔记的全部附件
  Future<List<Attachment>> listByNote(String noteId);

  /// 添加（已写入 [AttachmentStorage] 后再 register）
  Future<Attachment> register(Attachment attachment);

  /// 取消注册（不再属于笔记）
  Future<void> unregister(String attachmentId);

  /// 物理删除（包括文件）
  Future<bool> delete(String attachmentId);

  /// 通过 ID 查找
  Future<Attachment?> findById(String id);
}

/// 基于 SharedPreferences 的简易元数据存储
///
/// 每条记录用 `<noteId>::<attachmentId>` 做 key；适用于轻量场景，
/// 后续可平滑迁移到 drift。
class SharedPrefsAttachmentRepository implements AttachmentRepository {
  SharedPrefsAttachmentRepository({
    required this.storage,
    SharedPreferences? prefs,
  }) : _prefsFuture = prefs == null
            ? SharedPreferences.getInstance()
            : Future.value(prefs);

  final AttachmentStorage storage;
  final Future<SharedPreferences> _prefsFuture;
  static const String _prefix = 'attachment::';
  static const String _indexKey = 'attachment_index::';

  Future<SharedPreferences> get _prefs => _prefsFuture;

  Future<List<String>> _readIndex(String noteId) async {
    final p = await _prefs;
    return p.getStringList('$_indexKey$noteId') ?? <String>[];
  }

  Future<void> _writeIndex(String noteId, List<String> ids) async {
    final p = await _prefs;
    await p.setStringList('$_indexKey$noteId', ids);
  }

  @override
  Future<List<Attachment>> listByNote(String noteId) async {
    final ids = await _readIndex(noteId);
    final result = <Attachment>[];
    for (final id in ids) {
      final a = await findById(id);
      if (a != null) result.add(a);
    }
    return result;
  }

  @override
  Future<Attachment> register(Attachment attachment) async {
    final p = await _prefs;
    // 如果 id 为空（来自 storage.findBySha），补一个
    final newId = attachment.id.isEmpty ? const Uuid().v4() : attachment.id;
    final a = attachment.copyWith(id: newId);
    await p.setString('$_prefix${a.id}', _encode(a));
    final ids = await _readIndex(a.noteId);
    if (!ids.contains(a.id)) {
      ids.add(a.id);
      await _writeIndex(a.noteId, ids);
    }
    return a;
  }

  @override
  Future<void> unregister(String attachmentId) async {
    final p = await _prefs;
    final raw = p.getString('$_prefix$attachmentId');
    if (raw == null) return;
    final a = _decode(raw);
    await p.remove('$_prefix$attachmentId');
    final ids = await _readIndex(a.noteId);
    ids.remove(attachmentId);
    await _writeIndex(a.noteId, ids);
  }

  @override
  Future<bool> delete(String attachmentId) async {
    final a = await findById(attachmentId);
    if (a == null) return false;
    await storage.delete(a, forcePhysical: true);
    await unregister(attachmentId);
    return true;
  }

  @override
  Future<Attachment?> findById(String id) async {
    final p = await _prefs;
    final raw = p.getString('$_prefix$id');
    if (raw == null) return null;
    return _decode(raw);
  }

  String _encode(Attachment a) => jsonEncode(a.toMap());

  Attachment _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('Invalid attachment encoded value', raw);
    }
    final map = decoded.cast<String, dynamic>();
    final size = int.tryParse('${map['sizeBytes']}') ?? 0;
    final width = int.tryParse('${map['width']}');
    final height = int.tryParse('${map['height']}');
    return Attachment(
      id: '${map['id']}',
      noteId: '${map['noteId']}',
      fileName: '${map['fileName']}',
      relativePath: '${map['relativePath']}',
      sha256: '${map['sha256']}',
      sizeBytes: size,
      mimeType: '${map['mimeType']}',
      kind: AttachmentKind.values.firstWhere(
        (e) => e.name == '${map['kind']}',
        orElse: () => AttachmentKind.other,
      ),
      createdAt:
          DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
      width: width,
      height: height,
      alt: map['alt'] as String?,
    );
  }
}

/// 内存附件仓库（用于测试）
class InMemoryAttachmentRepository implements AttachmentRepository {
  InMemoryAttachmentRepository({required this.storage});

  final AttachmentStorage storage;
  final Map<String, Attachment> _byId = <String, Attachment>{};
  final Map<String, List<String>> _byNote = <String, List<String>>{};

  @override
  Future<Attachment> register(Attachment attachment) async {
    final newId = attachment.id.isEmpty ? const Uuid().v4() : attachment.id;
    final a = attachment.copyWith(id: newId);
    _byId[a.id] = a;
    final list = _byNote.putIfAbsent(a.noteId, () => <String>[]);
    if (!list.contains(a.id)) list.add(a.id);
    return a;
  }

  @override
  Future<bool> delete(String attachmentId) async {
    final a = _byId[attachmentId];
    if (a == null) return false;
    await storage.delete(a, forcePhysical: true);
    _byId.remove(attachmentId);
    _byNote[a.noteId]?.remove(attachmentId);
    return true;
  }

  @override
  Future<Attachment?> findById(String id) async => _byId[id];

  @override
  Future<List<Attachment>> listByNote(String noteId) async {
    final ids = _byNote[noteId] ?? <String>[];
    return ids.map((id) => _byId[id]!).toList(growable: false);
  }

  @override
  Future<void> unregister(String attachmentId) async {
    final a = _byId[attachmentId];
    if (a == null) return;
    _byId.remove(attachmentId);
    _byNote[a.noteId]?.remove(attachmentId);
  }
}

/// 业务门面：组合存储 + 仓库 + Markdown 引用解析
class AttachmentService {
  AttachmentService({
    required this.storage,
    required this.repository,
  });

  final AttachmentStorage storage;
  final AttachmentRepository repository;

  /// 从 [File] 导入附件并注册到笔记
  Future<Attachment> importFromFile({
    required String noteId,
    required File file,
    String? alt,
  }) async {
    final saved = await storage.saveFromFile(noteId: noteId, file: file, alt: alt);
    return repository.register(saved);
  }

  /// 列出笔记的全部附件
  Future<List<Attachment>> listForNote(String noteId) =>
      repository.listByNote(noteId);

  /// 从笔记中移除附件
  Future<void> remove(String attachmentId) =>
      repository.delete(attachmentId);

  /// 打开附件的物理文件
  Future<File> open(Attachment a) => storage.openFile(a);
}
