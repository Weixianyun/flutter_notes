import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../../data/repositories/note_repository.dart';

/// 笔记仓库 Provider
///
/// 暴露 [NoteRepository] 实例，当前返回 [MockNoteRepository]。
/// Week 2 接入 drift 后替换为数据库实现。
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return MockNoteRepository();
});

/// 笔记列表状态管理
///
/// 使用 Riverpod 2.x [Notifier] 管理笔记列表的增删改查。
/// 所有变更同步写入 [NoteRepository]，确保数据一致性。
class NotesNotifier extends Notifier<List<NoteModel>> {
  late final NoteRepository _repository;

  @override
  List<NoteModel> build() {
    _repository = ref.read(noteRepositoryProvider);
    return _repository.getAllNotes();
  }

  /// 新增笔记
  void addNote(NoteModel note) {
    _repository.addNote(note);
    state = [note, ...state];
  }

  /// 更新笔记
  void updateNote(NoteModel note) {
    _repository.updateNote(note);
    state = [
      for (final n in state)
        if (n.id == note.id) note else n,
    ];
  }

  /// 删除笔记
  void deleteNote(String id) {
    _repository.deleteNote(id);
    state = state.where((n) => n.id != id).toList();
  }

  /// 根据 ID 获取笔记
  NoteModel? getNoteById(String id) {
    return _repository.getNoteById(id);
  }

  /// 刷新列表（从仓库重新加载）
  void refresh() {
    state = _repository.getAllNotes();
  }
}

/// 笔记列表 Provider
final notesProvider =
    NotifierProvider<NotesNotifier, List<NoteModel>>(NotesNotifier.new);
