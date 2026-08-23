import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';

/// 文件选择来源
enum AttachmentSource {
  /// 系统文件选择器（file_picker）
  filePicker,

  /// 拍照或从相册选择（image_picker）
  imagePicker,

  /// 取消
  cancel,
}

/// 文件选择结果
@immutable
class AttachmentPickResult {
  const AttachmentPickResult({required this.source, this.files = const []});

  final AttachmentSource source;
  final List<File> files;
}

/// 抽象的文件选择服务（便于在测试中注入）
abstract class AttachmentPicker {
  Future<AttachmentPickResult> pickImage();
  Future<AttachmentPickResult> pickFile();
}

/// 基于 file_picker 的实现
class FilePickerAttachmentPicker implements AttachmentPicker {
  const FilePickerAttachmentPicker();

  @override
  Future<AttachmentPickResult> pickImage() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.image,
      allowMultiple: true,
      withData: false,
    );
    if (result == null) {
      return const AttachmentPickResult(source: AttachmentSource.cancel);
    }
    final files = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList(growable: false);
    return AttachmentPickResult(
      source: AttachmentSource.filePicker,
      files: files,
    );
  }

  @override
  Future<AttachmentPickResult> pickFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.any,
      allowMultiple: true,
      withData: false,
    );
    if (result == null) {
      return const AttachmentPickResult(source: AttachmentSource.cancel);
    }
    final files = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList(growable: false);
    return AttachmentPickResult(
      source: AttachmentSource.filePicker,
      files: files,
    );
  }
}

/// 显示"添加附件"底部菜单
Future<AttachmentPickResult?> showAttachmentPickerSheet(
  BuildContext context, {
  AttachmentPicker? picker,
}) {
  return showModalBottomSheet<AttachmentPickResult>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('从相册 / 文件选择图片'),
              onTap: () async {
                final p = picker ?? const FilePickerAttachmentPicker();
                final r = await p.pickImage();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(r);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('从文件选择附件'),
              subtitle: const Text('支持任意文件类型'),
              onTap: () async {
                final p = picker ?? const FilePickerAttachmentPicker();
                final r = await p.pickFile();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(r);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

/// 显示一个 dialog 来填写 alt（图片）
Future<String?> showImageAltDialog(
  BuildContext context, {
  required String defaultAlt,
}) {
  final controller = TextEditingController(text: defaultAlt);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('设置图片说明 (alt)'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '替代文本',
          hintText: '图片加载失败时显示',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
