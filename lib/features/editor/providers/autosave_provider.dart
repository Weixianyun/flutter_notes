import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 编辑器自动保存状态
///
/// 跟踪当前编辑器的自动保存生命周期：
/// - [AutosaveStatus.idle]: 空闲，无未保存变更
/// - [AutosaveStatus.saving]: 正在保存（防抖定时器已触发，正在写入）
/// - [AutosaveStatus.saved]: 已保存，附带保存时间戳
/// - [AutosaveStatus.error]: 保存失败，附带错误信息
enum AutosaveStatus { idle, saving, saved, error }

/// 自动保存状态数据
class AutosaveState {
  const AutosaveState({
    required this.status,
    this.savedAt,
    this.errorMessage,
  });

  final AutosaveStatus status;
  final DateTime? savedAt;
  final String? errorMessage;

  const AutosaveState.idle()
      : status = AutosaveStatus.idle,
        savedAt = null,
        errorMessage = null;

  AutosaveState copyWith({
    AutosaveStatus? status,
    DateTime? savedAt,
    String? errorMessage,
  }) {
    return AutosaveState(
      status: status ?? this.status,
      savedAt: savedAt ?? this.savedAt,
      errorMessage: errorMessage,
    );
  }
}

/// 编辑器自动保存状态 Provider
///
/// 每次打开编辑器时由 [NoteEditorPage] 初始化为 `idle`，
/// 自动保存触发时依次过渡为 `saving` → `saved` / `error`。
final autosaveStateProvider =
    StateProvider.autoDispose<AutosaveState>((ref) {
  return const AutosaveState.idle();
});
