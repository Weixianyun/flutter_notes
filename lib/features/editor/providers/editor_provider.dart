import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 编辑器预览模式状态
///
/// `true` = 预览 Markdown 渲染效果，`false` = 编辑模式。
/// 使用 autoDispose 使每次打开编辑器时重置为编辑模式。
final previewModeProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
