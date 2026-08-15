import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/models/note_model.dart';
import 'sync_service.dart';

/// 笔记导出服务
///
/// 将笔记导出为 Markdown 文件到本地存储。
/// 支持单条笔记导出和批量导出。
class ExportService {
  ExportService(this._syncService);

  final SyncService _syncService;

  /// 导出单条笔记
  ///
  /// 返回导出文件的完整路径。
  Future<String> exportNote(NoteModel note) async {
    final dir = await _getExportDirectory();
    final fileName = _safeFileName(note.title.isEmpty ? note.id : note.title);
    final file = File('${dir.path}/$fileName.md');
    final markdown = _syncService.noteToMarkdown(note);
    await file.writeAsString(markdown);
    return file.path;
  }

  /// 批量导出所有笔记
  ///
  /// 返回导出目录路径和成功/失败计数。
  Future<ExportResult> exportAllNotes(List<NoteModel> notes) async {
    final dir = await _getExportDirectory();
    int success = 0;
    final errors = <String>[];

    for (final note in notes) {
      try {
        final fileName = _safeFileName(note.title.isEmpty ? note.id : note.title);
        final file = File('${dir.path}/$fileName.md');
        final markdown = _syncService.noteToMarkdown(note);
        await file.writeAsString(markdown);
        success++;
      } catch (e) {
        errors.add('${note.title}: $e');
      }
    }

    return ExportResult(
      directoryPath: dir.path,
      total: notes.length,
      success: success,
      errors: errors,
    );
  }

  /// 获取导出目录（不存在则创建）
  Future<Directory> _getExportDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${docsDir.path}/flutter_notes_export');
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// 将标题转换为安全的文件名
  String _safeFileName(String text) {
    final slug = _syncService.slugify(text);
    return slug.isEmpty ? 'untitled' : slug;
  }
}

/// 导出结果
class ExportResult {
  const ExportResult({
    required this.directoryPath,
    required this.total,
    required this.success,
    required this.errors,
  });

  final String directoryPath;
  final int total;
  final int success;
  final List<String> errors;

  int get failed => total - success;
  bool get isSuccess => errors.isEmpty;
}
