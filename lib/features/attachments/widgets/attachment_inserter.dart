import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/attachment.dart';
import '../models/attachment_ref.dart';
import '../providers/attachment_providers.dart';
import 'attachment_picker_sheet.dart';

/// 在编辑器中插入附件的辅助控件
///
/// 由 NoteEditorPage 在工具栏按下"添加附件"时调用：
/// 1. 打开 [showAttachmentPickerSheet] 选文件；
/// 2. 调 [ImportAttachmentController.importMany] 写入存储；
/// 3. 通过 [AttachmentRefParser.insert] 把 `attachment://` 引用插入光标处。
class AttachmentInserter {
  AttachmentInserter({
    required this.ref,
    required this.controller,
    required this.noteId,
  });

  final WidgetRef ref;
  final TextEditingController controller;
  final String noteId;

  static const AttachmentRefParser _parser = AttachmentRefParser();

  /// 触发完整的"选 → 导入 → 插入"流程
  Future<int> pickAndInsert(BuildContext context) async {
    final pick = await showAttachmentPickerSheet(context);
    if (pick == null || pick.files.isEmpty) return 0;
    final ctrl = ref.read(importAttachmentControllerProvider);
    final List<Attachment> atts = await ctrl.importMany(
      noteId: noteId,
      files: pick.files,
    );
    if (atts.isEmpty) return 0;
    final text = controller.text;
    final sel = controller.selection;
    final offset = sel.isValid ? sel.start : text.length;
    final newText = _insertMany(text, offset, atts);
    final delta = newText.length - text.length;
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + delta),
      composing: TextRange.empty,
    );
    // 触发一次剪贴板提示音
    await HapticFeedback.lightImpact();
    return atts.length;
  }

  String _insertMany(String source, int offset, List<Attachment> atts) {
    var buffer = source;
    var offsetCursor = offset;
    for (final att in atts) {
      final snippet = _parser.insert(buffer, offsetCursor, att);
      final delta = snippet.length - buffer.length;
      buffer = snippet;
      offsetCursor += delta;
    }
    return buffer;
  }
}
