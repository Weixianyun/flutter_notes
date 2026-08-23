import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/attachment.dart';
import '../../../services/attachment_repository.dart';
import '../../../services/attachment_storage.dart';
import '../../../services/thumbnail_service.dart';

/// Riverpod：附件仓库
final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return InMemoryAttachmentRepository(
    storage: ref.watch(attachmentStorageProvider),
  );
});

/// Riverpod：附件存储
final attachmentStorageProvider = Provider<AttachmentStorage>((ref) {
  return LocalAttachmentStorage();
});

/// Riverpod：缩略图服务
final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  final svc = LocalThumbnailService();
  // 提供 storage 给缩略图使用以打开原图
  svc.storage = ref.watch(attachmentStorageProvider);
  return svc;
});

/// Riverpod：附件门面
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService(
    storage: ref.watch(attachmentStorageProvider),
    repository: ref.watch(attachmentRepositoryProvider),
  );
});

/// Riverpod：笔记的全部附件
final noteAttachmentsProvider =
    FutureProvider.family<List<Attachment>, String>((ref, noteId) async {
  final svc = ref.watch(attachmentServiceProvider);
  return svc.listForNote(noteId);
});

/// 异步导入附件并注册到笔记
class ImportAttachmentController {
  ImportAttachmentController(this._ref);

  final Ref _ref;

  Future<Attachment?> importFromFile({
    required String noteId,
    required File file,
    String? alt,
  }) async {
    final svc = _ref.read(attachmentServiceProvider);
    final result = await svc.importFromFile(noteId: noteId, file: file, alt: alt);
    _invalidate(noteId);
    return result;
  }

  Future<List<Attachment>> importMany({
    required String noteId,
    required List<File> files,
  }) async {
    final result = <Attachment>[];
    for (final f in files) {
      final a = await importFromFile(noteId: noteId, file: f);
      if (a != null) result.add(a);
    }
    return result;
  }

  Future<void> remove(String noteId, String attachmentId) async {
    final svc = _ref.read(attachmentServiceProvider);
    await svc.remove(attachmentId);
    _invalidate(noteId);
  }

  void _invalidate(String noteId) {
    _ref.invalidate(noteAttachmentsProvider(noteId));
  }
}

final importAttachmentControllerProvider =
    Provider<ImportAttachmentController>((ref) {
  return ImportAttachmentController(ref);
});

/// 缩略图生成：缓存到内存
final thumbnailFileProvider =
    FutureProvider.family<File, ({String attachmentId, int maxSize})>((ref, k) async {
  // 这里我们不依赖 Attachment 实例以减少代码复杂；
  // 调用方应在拿到 Attachment 后直接用 service 生成。
  throw UnimplementedError(
      'thumbnailFileProvider requires direct service usage; use ThumbnailService.ensureThumbnail');
});
