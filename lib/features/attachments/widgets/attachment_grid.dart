import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../data/models/attachment.dart';
import '../../../services/thumbnail_service.dart';
import '../providers/attachment_providers.dart';

/// 附件网格：缩略图（图片）/ 文件图标（非图片）
class AttachmentGrid extends ConsumerWidget {
  const AttachmentGrid({
    super.key,
    required this.noteId,
    this.onTap,
    this.onLongPress,
    this.maxCrossAxisExtent = 120,
  });

  /// 笔记 ID
  final String noteId;

  /// 单击附件回调
  final void Function(Attachment attachment)? onTap;

  /// 长按回调（用于删除等操作）
  final void Function(Attachment attachment)? onLongPress;

  /// 缩略图列宽度
  final double maxCrossAxisExtent;

  static const ThumbnailSpec _spec = ThumbnailSpec(maxWidth: 240, maxHeight: 240);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(noteAttachmentsProvider(noteId));
    return asyncList.when(
      data: (attachments) {
        if (attachments.isEmpty) return const SizedBox.shrink();
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.xs),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attachments.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent,
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final att = attachments[index];
            return _AttachmentTile(
              attachment: att,
              onTap: () => onTap?.call(att),
              onLongPress: () => onLongPress?.call(att),
              spec: _spec,
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('加载附件失败: $err',
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.spec,
    this.onTap,
    this.onLongPress,
  });

  final Attachment attachment;
  final ThumbnailSpec spec;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: attachment.isImage
            ? _buildImageThumb(ref)
            : _buildFileBadge(theme, colorScheme),
      ),
    );
  }

  Widget _buildImageThumb(WidgetRef ref) {
    final key = _ThumbKey(attachment: attachment, spec: spec);
    final future = ref.watch(_thumbnailFileProvider(key));
    return future.when(
      data: (file) => Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _Placeholder(icon: Icons.broken_image),
      ),
      loading: () => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const _Placeholder(icon: Icons.broken_image),
    );
  }

  Widget _buildFileBadge(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _iconFor(attachment.kind),
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            attachment.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            attachment.prettySize,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: AppFontSizes.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AttachmentKind k) {
    switch (k) {
      case AttachmentKind.image:
        return Icons.image_outlined;
      case AttachmentKind.file:
        return Icons.description_outlined;
      case AttachmentKind.audio:
        return Icons.audiotrack_outlined;
      case AttachmentKind.video:
        return Icons.movie_outlined;
      case AttachmentKind.other:
        return Icons.attachment;
    }
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

/// 缩略图 FutureProvider
final _thumbnailFileProvider = FutureProvider.family<File, _ThumbKey>((
  ref,
  k,
) async {
  final svc = ref.watch(thumbnailServiceProvider);
  return svc.ensureThumbnail(k.attachment, k.spec);
});

class _ThumbKey {
  const _ThumbKey({required this.attachment, required this.spec});
  final Attachment attachment;
  final ThumbnailSpec spec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ThumbKey && other.attachment.id == attachment.id &&
          other.spec.key == spec.key;

  @override
  int get hashCode => Object.hash(attachment.id, spec.key);
}
