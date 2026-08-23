import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../notes/providers/notes_provider.dart';
import '../services/backlink_index.dart';

/// 全局反向链接索引 Provider
///
/// 监听 [notesProvider] 的笔记列表变化，自动重建 [BacklinkIndex]。
/// 在编辑器中根据当前笔记标题反查引用了它的笔记条目。
///
/// [notesProvider] 在加载过程中是 [AsyncLoading]，此时索引按空列表处理；
/// 一旦加载完成（或变更）会触发重建。
final backlinkIndexProvider = Provider<BacklinkIndex>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final notes = notesAsync.maybeWhen(
    data: (data) => data,
    orElse: () => const <NoteModel>[],
  );
  return BacklinkIndex(notes);
});

/// 异步版本：在 notes 真正加载完成后才能取到 BacklinkIndex。
///
/// 适用于 widget 测试需要等待初始异步数据完成。
final backlinkIndexReadyProvider = FutureProvider<BacklinkIndex>((ref) async {
  final notes = await ref.watch(notesProvider.future);
  return BacklinkIndex(notes);
});
