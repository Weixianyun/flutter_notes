import 'package:path/path.dart' as p;

import '../../../data/models/attachment.dart';

/// 一个被 Markdown 文本引用的附件
///
/// Markdown 语法支持：
/// - 图片：`![alt](attachment://<id>)` 或 `![alt](attachment://<id>?name=foo.png)`
/// - 通用文件：`[label](attachment://<id>)`
class AttachmentRef {
  const AttachmentRef({
    required this.attachmentId,
    required this.alt,
    required this.isImage,
  });

  final String attachmentId;
  final String alt;
  final bool isImage;

  /// 渲染为 Markdown 引用
  String toMarkdown(Attachment attachment) {
    final name = Uri.encodeComponent(attachment.fileName);
    final query = '?name=$name';
    final href = 'attachment://${attachment.id}$query';
    if (isImage) {
      final alt = this.alt.isEmpty ? attachment.fileName : this.alt;
      return '![$alt]($href)';
    }
    return '[$alt]($href)';
  }

  @override
  String toString() =>
      'AttachmentRef(id: $attachmentId, isImage: $isImage, alt: $alt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentRef && other.attachmentId == attachmentId;

  @override
  int get hashCode => attachmentId.hashCode;
}

/// Markdown 附件引用解析器
///
/// 把 `attachment://<id>?name=...` 还原成 [AttachmentRef]
class AttachmentRefParser {
  const AttachmentRefParser();

  /// 解析 markdown `src` (如 `attachment://abc123?name=foo.png`)
  AttachmentRef? parse(String src) {
    if (src.isEmpty) return null;
    final uri = Uri.tryParse(src);
    if (uri == null || uri.scheme != 'attachment') return null;
    final id = uri.path.isNotEmpty ? uri.path : uri.host;
    if (id.isEmpty) return null;
    final name = uri.queryParameters['name'];
    final alt = uri.queryParameters['alt'] ?? name ?? id;
    final isImage = name != null && _imageExtRegExp.hasMatch(name.toLowerCase());
    return AttachmentRef(
      attachmentId: Uri.decodeComponent(id),
      alt: Uri.decodeComponent(alt),
      isImage: isImage,
    );
  }

  /// 从 Markdown 文本中提取全部附件引用
  ///
  /// 匹配 `![alt](attachment://id)` 与 `[label](attachment://id)`。
  List<AttachmentRef> extractAll(String markdown) {
    final result = <AttachmentRef>[];
    for (final m in _refRegExp.allMatches(markdown)) {
      final isImage = (m.group(1) ?? '').startsWith('!');
      final alt = m.group(2) ?? '';
      final src = m.group(3) ?? '';
      final ref = parse(src);
      if (ref != null) {
        result.add(AttachmentRef(
          attachmentId: ref.attachmentId,
          alt: alt,
          isImage: isImage,
        ));
      }
    }
    return result;
  }

  /// 在指定位置插入新附件的 Markdown 引用，返回新文本
  String insert(String markdown, int offset, Attachment attachment) {
    final ref = AttachmentRef(
      attachmentId: attachment.id,
      alt: attachment.alt ?? attachment.fileName,
      isImage: attachment.isImage,
    );
    final snippet = ref.toMarkdown(attachment);
    final clamped = offset.clamp(0, markdown.length);
    return markdown.replaceRange(clamped, clamped, snippet);
  }

  /// 把 Markdown 中的附件引用路径还原为文件名（调试/UI 用）
  String labelFor(AttachmentRef ref, Attachment? attachment) {
    if (ref.alt.isNotEmpty) return ref.alt;
    return attachment?.fileName ?? '附件 ${ref.attachmentId}';
  }

  /// 由 `attachment://<id>?name=foo.png` 解析出来的 host 部分如果包含非法字符，
  /// 兼容 ID 中可能存在的 `path`
  String fileNameFromSrc(String src) {
    final uri = Uri.tryParse(src);
    if (uri == null) return '';
    return uri.queryParameters['name'] != null
        ? Uri.decodeComponent(uri.queryParameters['name']!)
        : p.basename(Uri.decodeComponent(uri.path));
  }

  static final RegExp _refRegExp = RegExp(
    r'(!?)\[([^\]]*)\]\((attachment://[^)\s]+)\)',
  );

  static final RegExp _imageExtRegExp = RegExp(
    r'\.(png|jpg|jpeg|gif|webp|bmp|svg|heic|heif)$',
  );

  /// 工具：把任意字符串编码为 attachment URL 安全的字符串
  String encode(String value) => Uri.encodeComponent(value);
}
