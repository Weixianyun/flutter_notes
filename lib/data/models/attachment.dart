import 'package:flutter/foundation.dart';

import 'package:mime/mime.dart';

/// 附件种类
///
/// 用于区分不同附件类型在 UI / Markdown 插入 / 缩略图策略上的差异。
enum AttachmentKind {
  /// 图片（png/jpg/webp/gif 等）
  image,

  /// 通用文档（pdf/doc/xlsx/...）
  file,

  /// 音频
  audio,

  /// 视频
  video,

  /// 其它二进制
  other,
}

extension AttachmentKindX on AttachmentKind {
  /// 从 MIME / 文件名推断
  static AttachmentKind fromMimeOrName({
    required String? mime,
    required String? name,
  }) {
    final m = (mime ?? '').toLowerCase();
    if (m.startsWith('image/')) return AttachmentKind.image;
    if (m.startsWith('audio/')) return AttachmentKind.audio;
    if (m.startsWith('video/')) return AttachmentKind.video;
    if (m == 'application/pdf' ||
        m.contains('officedocument') ||
        m.contains('msword') ||
        m.contains('text/')) {
      return AttachmentKind.file;
    }
    final ext = (name ?? '').toLowerCase();
    if (RegExp(r'\.(png|jpg|jpeg|gif|webp|bmp|svg|heic|heif)$')
        .hasMatch(ext)) {
      return AttachmentKind.image;
    }
    if (RegExp(r'\.(mp3|wav|flac|m4a|aac|ogg)$').hasMatch(ext)) {
      return AttachmentKind.audio;
    }
    if (RegExp(r'\.(mp4|mov|mkv|webm|avi)$').hasMatch(ext)) {
      return AttachmentKind.video;
    }
    if (RegExp(r'\.(pdf|doc|docx|xls|xlsx|ppt|pptx|txt|md|json|xml)$')
        .hasMatch(ext)) {
      return AttachmentKind.file;
    }
    return AttachmentKind.other;
  }

  /// UI 提示
  String get label {
    switch (this) {
      case AttachmentKind.image:
        return '图片';
      case AttachmentKind.file:
        return '文件';
      case AttachmentKind.audio:
        return '音频';
      case AttachmentKind.video:
        return '视频';
      case AttachmentKind.other:
        return '附件';
    }
  }
}

/// 笔记附件
///
/// 表示一个被笔记引用的本地文件。文件实际存储在
/// [AttachmentStorage] 管理的目录下，路径为 `relativePath`，
/// 通过 `sha256` 防止重复。
@immutable
class Attachment {
  const Attachment({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.relativePath,
    required this.sha256,
    required this.sizeBytes,
    required this.mimeType,
    required this.kind,
    required this.createdAt,
    this.width,
    this.height,
    this.alt,
  });

  /// 复制并修改部分字段
  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      fileName: map['fileName'] as String,
      relativePath: map['relativePath'] as String,
      sha256: map['sha256'] as String,
      sizeBytes: (map['sizeBytes'] as num).toInt(),
      mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
      kind: AttachmentKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => AttachmentKind.other,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      alt: map['alt'] as String?,
    );
  }

  /// 唯一 ID（UUID v4）
  final String id;

  /// 所属笔记 ID
  final String noteId;

  /// 用户看到的文件名（含扩展名）
  final String fileName;

  /// 相对存储路径（基于 AttachmentStorage rootDir）
  final String relativePath;

  /// 文件内容的 SHA-256（hex），用于去重
  final String sha256;

  /// 文件大小（字节）
  final int sizeBytes;

  /// MIME 类型
  final String mimeType;

  /// 附件类型
  final AttachmentKind kind;

  /// 第一次插入时间
  final DateTime createdAt;

  /// 图片宽度（仅图片类型）
  final int? width;

  /// 图片高度（仅图片类型）
  final int? height;

  /// 替代文本（用于 Markdown `![alt](url)`）
  final String? alt;

  /// 是否为图片
  bool get isImage => kind == AttachmentKind.image;

  /// 人类可读大小（如 `12.3 KB` / `5.6 MB`）
  String get prettySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'noteId': noteId,
        'fileName': fileName,
        'relativePath': relativePath,
        'sha256': sha256,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (alt != null) 'alt': alt,
      };

  Attachment copyWith({
    String? id,
    String? noteId,
    String? fileName,
    String? relativePath,
    String? sha256,
    int? sizeBytes,
    String? mimeType,
    AttachmentKind? kind,
    DateTime? createdAt,
    int? width,
    int? height,
    String? alt,
  }) {
    return Attachment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      fileName: fileName ?? this.fileName,
      relativePath: relativePath ?? this.relativePath,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
      alt: alt ?? this.alt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Attachment && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Attachment(id: $id, name: $fileName, kind: $kind, size: $sizeBytes)';

  /// 由文件名推断 mime（当用户未指定时）
  static String guessMime(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }
}
