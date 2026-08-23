import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/attachment.dart';

class _HexSink implements Sink<Digest> {
  String? _value;
  String get value => _value ?? '';
  @override
  void add(Digest data) {
    _value = data.toString();
  }
  @override
  void close() {}
}

/// 抽象的附件存储后端
///
/// 设计为可注入实现，便于在测试中传入 `MemoryAttachmentStorage`。
abstract class AttachmentStorage {
  /// 根目录
  Future<Directory> get rootDir;

  /// 把 [source] 写入存储，返回新附件的 [Attachment]（含 sha256 / size / mime）
  Future<Attachment> save({
    required String noteId,
    required String fileName,
    required Stream<List<int>> source,
    int? sizeBytes,
    String? mimeType,
    String? alt,
  });

  /// 把本地 [file] 移入存储（推荐使用，避免内存中转）
  Future<Attachment> saveFromFile({
    required String noteId,
    required File file,
    String? alt,
  });

  /// 由 sha256 查找已存在的附件（去重）
  Future<Attachment?> findBySha(String sha256);

  /// 打开附件的 [File]（用于显示或分享）
  Future<File> openFile(Attachment attachment);

  /// 删除单个附件；若无人再引用则同时删物理文件
  Future<bool> delete(Attachment attachment, {bool forcePhysical = false});

  /// 解析相对路径为绝对路径
  File resolveFile(String relativePath);
}

/// 基于 [path_provider] 的本地文件系统实现
class LocalAttachmentStorage implements AttachmentStorage {
  LocalAttachmentStorage({this._overrideRootDir});

  static const String _folderName = 'attachments';

  final Directory? _overrideRootDir;
  Directory? _resolvedRoot;

  @override
  Future<Directory> get rootDir async {
    if (_resolvedRoot != null) return _resolvedRoot!;
    final base = _overrideRootDir ??
        await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _resolvedRoot = dir;
    return dir;
  }

  @override
  File resolveFile(String relativePath) {
    if (relativePath.isEmpty) {
      throw ArgumentError('relativePath is empty');
    }
    if (p.isAbsolute(relativePath)) {
      return File(relativePath);
    }
    final root = _resolvedRoot;
    if (root == null) {
      // 调用顺序错误：必须在 rootDir 初始化后再调用
      throw StateError(
          'LocalAttachmentStorage.rootDir not initialized. Await rootDir first.');
    }
    return File(p.join(root.path, relativePath));
  }

  @override
  Future<Attachment> save({
    required String noteId,
    required String fileName,
    required Stream<List<int>> source,
    int? sizeBytes,
    String? mimeType,
    String? alt,
  }) async {
    final root = await rootDir;
    final buffer = <int>[];
    final hexSink = _HexSink();
    final hash = sha256.startChunkedConversion(hexSink);
    await for (final chunk in source) {
      buffer.addAll(chunk);
      hash.add(chunk);
    }
    hash.close();
    final digest = hexSink.value;
    final rel = _relativePathFor(digest, fileName);

    // 去重：相同 sha256 不重复写入
    final existing = await _findByDigest(digest);
    if (existing != null) return existing;

    final file = File(p.join(root.path, rel));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(Uint8List.fromList(buffer), flush: true);

    final size = sizeBytes ?? buffer.length;
    final mime = mimeType ?? Attachment.guessMime(fileName);
    final kind = AttachmentKindX.fromMimeOrName(mime: mime, name: fileName);
    return Attachment(
      id: const Uuid().v4(),
      noteId: noteId,
      fileName: fileName,
      relativePath: rel,
      sha256: digest,
      sizeBytes: size,
      mimeType: mime,
      kind: kind,
      createdAt: DateTime.now(),
      alt: alt,
    );
  }

  @override
  Future<Attachment> saveFromFile({
    required String noteId,
    required File file,
    String? alt,
  }) async {
    if (!await file.exists()) {
      throw FileSystemException('Source file not found', file.path);
    }
    final fileName = p.basename(file.path);
    final size = await file.length();
    final hexSink = _HexSink();
    final hash = sha256.startChunkedConversion(hexSink);
    final buffer = <int>[];
    await for (final chunk in file.openRead()) {
      hash.add(chunk);
      buffer.addAll(chunk);
    }
    hash.close();
    final digest = hexSink.value;
    final rel = _relativePathFor(digest, fileName);

    final existing = await _findByDigest(digest);
    if (existing != null) return existing;

    final root = await rootDir;
    final dest = File(p.join(root.path, rel));
    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }
    await file.copy(dest.path);

    final mime = Attachment.guessMime(fileName);
    final kind =
        AttachmentKindX.fromMimeOrName(mime: mime, name: fileName);
    return Attachment(
      id: const Uuid().v4(),
      noteId: noteId,
      fileName: fileName,
      relativePath: rel,
      sha256: digest,
      sizeBytes: size,
      mimeType: mime,
      kind: kind,
      createdAt: DateTime.now(),
      alt: alt,
    );
  }

  @override
  Future<Attachment?> findBySha(String sha256) => _findByDigest(sha256);

  Future<Attachment?> _findByDigest(String sha256) async {
    final root = await rootDir;
    final prefix = sha256.substring(0, 2);
    final rest = sha256.substring(2);
    final dir = Directory(p.join(root.path, prefix));
    if (!await dir.exists()) return null;
    await for (final ent in dir.list()) {
      if (ent is! File) continue;
      final rel = p.relative(ent.path, from: root.path);
      if (rel.startsWith('$prefix/') &&
          rel.substring(prefix.length + 1).startsWith(rest)) {
        final stat = await ent.stat();
        // 解析回 filename: 取 relative path 末段并去 sha 前缀
        final base = p.basename(ent.path);
        final stripped = base.substring(rest.length);
        final originalName = stripped.isEmpty ? base : stripped;
        final mime = Attachment.guessMime(originalName);
        final kind = AttachmentKindX.fromMimeOrName(
            mime: mime, name: originalName);
        // 注意：这里 noteId / id 是未知（查重时不携带），用空 ID
        return Attachment(
          id: '',
          noteId: '',
          fileName: originalName,
          relativePath: rel,
          sha256: sha256,
          sizeBytes: stat.size,
          mimeType: mime,
          kind: kind,
          createdAt: stat.modified,
        );
      }
    }
    return null;
  }

  @override
  Future<File> openFile(Attachment attachment) async {
    final f = resolveFile(attachment.relativePath);
    if (!await f.exists()) {
      throw FileSystemException('Attachment file missing', f.path);
    }
    return f;
  }

  @override
  Future<bool> delete(Attachment attachment,
      {bool forcePhysical = false}) async {
    final f = resolveFile(attachment.relativePath);
    if (await f.exists()) {
      if (forcePhysical) {
        await f.delete();
        return true;
      }
    }
    return false;
  }

  /// 把 sha256 拆成两段：`<2>/<rest>__<fileName>` 作为路径
  /// 这样可以避免单目录文件过多
  String _relativePathFor(String sha256, String fileName) {
    final safeName = fileName.replaceAll(RegExp(r'[/\\]'), '_');
    final ext = p.extension(safeName);
    final prefix = sha256.substring(0, 2);
    final rest = sha256.substring(2);
    return p.join(prefix, '$rest$ext');
  }
}

/// 内存附件存储（用于测试）
class MemoryAttachmentStorage implements AttachmentStorage {
  MemoryAttachmentStorage();

  final Map<String, _MemEntry> _files = <String, _MemEntry>{};
  final List<Attachment> _attachments = <Attachment>[];

  @override
  Future<Directory> get rootDir async => Directory('memory://attachments');

  @override
  Future<Attachment> save({
    required String noteId,
    required String fileName,
    required Stream<List<int>> source,
    int? sizeBytes,
    String? mimeType,
    String? alt,
  }) async {
    final buffer = <int>[];
    final hexSink = _HexSink();
    final hash = sha256.startChunkedConversion(hexSink);
    await for (final chunk in source) {
      buffer.addAll(chunk);
      hash.add(chunk);
    }
    hash.close();
    final digest = hexSink.value;

    final existing = await findBySha(digest);
    if (existing != null) return existing;

    final rel = digest;
    _files[rel] = _MemEntry(buffer, fileName);
    final size = sizeBytes ?? buffer.length;
    final mime = mimeType ?? Attachment.guessMime(fileName);
    final kind = AttachmentKindX.fromMimeOrName(mime: mime, name: fileName);
    final att = Attachment(
      id: const Uuid().v4(),
      noteId: noteId,
      fileName: fileName,
      relativePath: rel,
      sha256: digest,
      sizeBytes: size,
      mimeType: mime,
      kind: kind,
      createdAt: DateTime.now(),
      alt: alt,
    );
    _attachments.add(att);
    return att;
  }

  @override
  Future<Attachment> saveFromFile({
    required String noteId,
    required File file,
    String? alt,
  }) async {
    final bytes = await file.readAsBytes();
    final fileName = p.basename(file.path);
    final stream = Stream.value(bytes);
    return save(noteId: noteId, fileName: fileName, source: stream,
        sizeBytes: bytes.length, alt: alt);
  }

  @override
  Future<Attachment?> findBySha(String sha256) async {
    for (final a in _attachments) {
      if (a.sha256 == sha256) return a;
    }
    return null;
  }

  @override
  Future<File> openFile(Attachment attachment) async {
    final entry = _files[attachment.relativePath];
    if (entry == null) {
      throw FileSystemException(
          'Attachment not in memory', attachment.relativePath);
    }
    // 把内存文件写到临时目录
    final tmp = await Directory.systemTemp.createTemp('mem_attachment_');
    final f = File(p.join(tmp.path, attachment.fileName));
    await f.writeAsBytes(entry.bytes, flush: true);
    return f;
  }

  @override
  Future<bool> delete(Attachment attachment,
      {bool forcePhysical = false}) async {
    _files.remove(attachment.relativePath);
    _attachments.removeWhere((a) => a.id == attachment.id);
    return true;
  }

  @override
  File resolveFile(String relativePath) {
    final entry = _files[relativePath];
    if (entry == null) {
      throw FileSystemException('Unknown attachment', relativePath);
    }
    // 返回一个尚未写入的 File handle（调用方负责读 / 写）
    return File('memory://$relativePath');
  }

  /// 测试用：直接读取内存字节
  List<int> readBytes(String relativePath) {
    return _files[relativePath]?.bytes ?? const <int>[];
  }
}

class _MemEntry {
  _MemEntry(this.bytes, this.originalName);
  final List<int> bytes;
  final String originalName;
}
