import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/attachment.dart';
import 'attachment_storage.dart';

/// 缩略图规格
class ThumbnailSpec {
  const ThumbnailSpec({required this.maxWidth, required this.maxHeight});

  /// 短边最大像素
  final int maxWidth;
  final int maxHeight;

  /// 短边最大像素后缀
  String get key => 'w${maxWidth}xh$maxHeight';
}

/// 缩略图服务接口
abstract class ThumbnailService {
  /// 生成（如果不存在）或返回 [attachment] 的缩略图路径
  Future<File> ensureThumbnail(Attachment attachment, ThumbnailSpec spec);

  /// 列出已生成的缩略图（用于回收）
  Future<List<File>> listAll();

  /// 删除全部缩略图（用于清空缓存）
  Future<int> clearAll();

  /// 缩略图根目录
  Future<Directory> get rootDir;
}

/// 基于 [image] + 物理文件的本地缩略图服务
class LocalThumbnailService implements ThumbnailService {
  LocalThumbnailService({this._overrideRootDir});

  static const String _folderName = 'thumbnails';
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
  Future<File> ensureThumbnail(Attachment attachment, ThumbnailSpec spec) async {
    if (!attachment.isImage) {
      throw ArgumentError('Attachment ${attachment.id} is not an image');
    }
    final dir = await rootDir;
    final ext = _formatExt(attachment.fileName);
    final cacheName = '${attachment.sha256}-${spec.key}.$ext';
    final out = File(p.join(dir.path, cacheName));
    if (await out.exists() && await out.length() > 0) {
      return out;
    }
    final storage = _storageFor(attachment);
    final src = await storage.openFile(attachment);
    final bytes = await src.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      // 不可解码：写一份原始副本作为占位
      await out.writeAsBytes(bytes, flush: true);
      return out;
    }
    final resized = _resizeIfNeeded(image, spec);
    final encoded = _encode(resized, attachment.fileName);
    await out.writeAsBytes(encoded, flush: true);
    return out;
  }

  @override
  Future<List<File>> listAll() async {
    final dir = await rootDir;
    final result = <File>[];
    await for (final ent in dir.list()) {
      if (ent is File) result.add(ent);
    }
    return result;
  }

  @override
  Future<int> clearAll() async {
    final dir = await rootDir;
    int count = 0;
    await for (final ent in dir.list()) {
      if (ent is File) {
        try {
          await ent.delete();
          count++;
        } catch (_) {/* ignore */}
      }
    }
    return count;
  }

  AttachmentStorage _storageFor(Attachment a) {
    final storage = _currentStorage;
    if (storage == null) {
      throw StateError(
          'ThumbnailService.storage not set. Use the setter before ensureThumbnail.');
    }
    return storage;
  }

  AttachmentStorage? _currentStorage;
  set storage(AttachmentStorage s) => _currentStorage = s;

  /// 缩小到不超过 [spec] 的最短边
  static img.Image _resizeIfNeeded(img.Image image, ThumbnailSpec spec) {
    final w = image.width;
    final h = image.height;
    if (w <= spec.maxWidth && h <= spec.maxHeight) return image;
    final ratio = (spec.maxWidth / w) < (spec.maxHeight / h)
        ? spec.maxWidth / w
        : spec.maxHeight / h;
    final nw = (w * ratio).round();
    final nh = (h * ratio).round();
    return img.copyResize(image, width: nw, height: nh);
  }

  static Uint8List _encode(img.Image image, String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return Uint8List.fromList(img.encodeJpg(image));
      case '.png':
        return Uint8List.fromList(img.encodePng(image));
      case '.gif':
        return Uint8List.fromList(img.encodeGif(image));
      case '.bmp':
        return Uint8List.fromList(img.encodeBmp(image));
      case '.webp':
        // image 包不支持 webp 编码，统一退化为 png
        return Uint8List.fromList(img.encodePng(image));
      default:
        return Uint8List.fromList(img.encodePng(image));
    }
  }

  static String _formatExt(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext.isEmpty) return 'img';
    return ext.substring(1);
  }
}

/// 内存缩略图服务（用于测试）
class MemoryThumbnailService implements ThumbnailService {
  MemoryThumbnailService();

  final Map<String, Uint8List> _cache = <String, Uint8List>{};

  @override
  Future<Directory> get rootDir async => Directory('memory://thumbnails');

  @override
  Future<File> ensureThumbnail(Attachment attachment, ThumbnailSpec spec) async {
    if (!attachment.isImage) {
      throw ArgumentError('Attachment ${attachment.id} is not an image');
    }
    final key = '${attachment.sha256}-${spec.key}';
    final existing = _cache[key];
    if (existing != null) {
      return _materialize(key, existing);
    }
    // 占位 1 像素 png
    final bytes = Uint8List.fromList(img.encodePng(img.Image(width: 1, height: 1)));
    _cache[key] = bytes;
    return _materialize(key, bytes);
  }

  Future<File> _materialize(String key, Uint8List bytes) async {
    final tmp = await Directory.systemTemp.createTemp('thumb_');
    final f = File(p.join(tmp.path, key));
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  @override
  Future<List<File>> listAll() async => const <File>[];

  @override
  Future<int> clearAll() async {
    final n = _cache.length;
    _cache.clear();
    return n;
  }
}
