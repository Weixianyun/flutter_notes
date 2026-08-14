import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_provider.dart';
import '../../../data/models/note_model.dart';
import '../../../data/repositories/note_repository.dart';

/// 笔记仓库 Provider
///
/// 暴露 [NoteRepository] 实例，使用基于 drift 的 [DriftNoteRepository]。
/// 测试时可通过 override 替换为 [MockNoteRepository]。
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftNoteRepository(db);
});

/// 笔记列表状态管理
///
/// 使用 Riverpod 2.x [AsyncNotifier] 管理笔记列表的增删改查。
/// 所有变更异步写入 [NoteRepository]，通过 [ref.invalidateSelf] 刷新状态。
class NotesNotifier extends AsyncNotifier<List<NoteModel>> {
  @override
  Future<List<NoteModel>> build() async {
    final repository = ref.read(noteRepositoryProvider);
    return repository.getAllNotes();
  }

  /// 新增笔记
  Future<void> addNote(NoteModel note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.addNote(note);
    ref.invalidateSelf();
  }

  /// 更新笔记
  Future<void> updateNote(NoteModel note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.updateNote(note);
    ref.invalidateSelf();
  }

  /// 删除笔记
  Future<void> deleteNote(String id) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNote(id);
    ref.invalidateSelf();
  }

  /// 根据 ID 获取笔记
  Future<NoteModel?> getNoteById(String id) async {
    final repository = ref.read(noteRepositoryProvider);
    return repository.getNoteById(id);
  }

  /// 刷新列表（从仓库重新加载）
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// 清空所有笔记
  Future<void> clearAllNotes() async {
    final repository = ref.read(noteRepositoryProvider);
    final notes = await repository.getAllNotes();
    for (final note in notes) {
      await repository.deleteNote(note.id);
    }
    ref.invalidateSelf();
  }
}

/// 笔记列表 Provider
final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<NoteModel>>(NotesNotifier.new);
