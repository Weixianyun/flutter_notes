import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/note_model.dart';

/// 笔记数据仓库抽象接口
///
/// 定义笔记 CRUD 操作契约。所有方法均为异步，
/// 由 [DriftNoteRepository] 基于 drift 数据库实现。
abstract class NoteRepository {
  /// 获取全部笔记（按更新时间倒序）
  Future<List<NoteModel>> getAllNotes();

  /// 根据 ID 获取单条笔记
  Future<NoteModel?> getNoteById(String id);

  /// 新增笔记，返回带生成 ID 的笔记
  Future<NoteModel> addNote(NoteModel note);

  /// 更新笔记
  Future<void> updateNote(NoteModel note);

  /// 删除笔记
  Future<void> deleteNote(String id);

  /// 监听全部笔记变化（按更新时间倒序）
  Stream<List<NoteModel>> watchAllNotes();
}

/// drift 笔记仓库实现
///
/// 基于 [AppDatabase] 实现持久化存储，将数据库实体 [Note]
/// 与领域模型 [NoteModel] 互相转换。
class DriftNoteRepository implements NoteRepository {
  DriftNoteRepository(this._db);

  final AppDatabase _db;

  // ── 实体转换 ──

  NoteModel _toModel(Note row) {
    return NoteModel(
      id: row.id,
      title: row.title,
      content: row.content,
      priority: NotePriority.values.firstWhere(
        (e) => e.name == row.priority,
        orElse: () => NotePriority.medium,
      ),
      status: NoteStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => NoteStatus.draft,
      ),
      tags: (jsonDecode(row.tags) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  NotesCompanion _toCompanion(NoteModel note) {
    return NotesCompanion(
      id: Value(note.id),
      title: Value(note.title),
      content: Value(note.content),
      priority: Value(note.priority.name),
      status: Value(note.status.name),
      tags: Value(jsonEncode(note.tags)),
      createdAt: Value(note.createdAt),
      updatedAt: Value(note.updatedAt),
    );
  }

  // ── CRUD ──

  @override
  Future<List<NoteModel>> getAllNotes() async {
    final rows = await (_db.select(_db.notes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    final row = await (_db.select(_db.notes)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toModel(row) : null;
  }

  @override
  Future<NoteModel> addNote(NoteModel note) async {
    await _db.into(_db.notes).insert(_toCompanion(note));
    return note;
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(note.id)))
        .write(_toCompanion(note));
  }

  @override
  Future<void> deleteNote(String id) async {
    await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<NoteModel>> watchAllNotes() {
    return (_db.select(_db.notes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }
}

/// Mock 笔记仓库（内存存储，异步兼容）
///
/// 使用静态列表模拟数据库，应用重启后数据重置。
/// 主要用于测试和快速原型验证。
class MockNoteRepository implements NoteRepository {
  MockNoteRepository() : _notes = List.from(_seedData);

  static final List<NoteModel> _seedData = [
    NoteModel(
      title: 'Dart 3 空安全实践',
      content: '## 空安全核心\n\nDart 3 的空安全是健全的（sound），'
          '类型系统层面保证非空变量不会持有 `null`。\n\n'
          '关键操作符：`?` `!` `??` `?.`',
      priority: NotePriority.high,
      tags: ['Dart', '空安全'],
    ),
    NoteModel(
      title: 'Flutter Material 3 主题配置',
      content: '使用 `ColorScheme.fromSeed` 生成完整色板，'
          '配合 `ThemeData` 定制 AppBar、Card、输入框等组件样式。',
      priority: NotePriority.medium,
      tags: ['Flutter', 'Material3', '主题'],
    ),
    NoteModel(
      title: 'Riverpod 状态管理入门',
      content: '## Riverpod 核心概念\n\n'
          '- **Provider**：只读状态\n'
          '- **NotifierProvider**：可变状态（推荐）\n'
          '- **FutureProvider**：异步状态\n'
          '- **StreamProvider**：流式状态\n\n'
          '```dart\nclass CounterNotifier extends Notifier<int> {\n'
          '  @override\n  int build() => 0;\n\n'
          '  void increment() => state++;\n}\n```',
      priority: NotePriority.medium,
      tags: ['Riverpod', '状态管理'],
    ),
    NoteModel(
      title: 'drift 数据库设计',
      content: '设计笔记表结构：\n\n'
          '| 字段 | 类型 | 说明 |\n|------|------|------|\n'
          '| id | TEXT | UUID 主键 |\n| title | TEXT | 标题 |\n'
          '| content | TEXT | Markdown 正文 |\n'
          '| priority | TEXT | 优先级枚举 |\n'
          '| status | TEXT | 状态枚举 |\n'
          '| tags | TEXT | JSON 数组 |\n'
          '| created_at | INTEGER | 创建时间戳 |\n'
          '| updated_at | INTEGER | 更新时间戳 |',
      priority: NotePriority.low,
      tags: ['drift', '数据库'],
    ),
    NoteModel(
      title: 'GitHub OAuth 认证流程',
      content: '1. 用户点击同步按钮\n2. 打开 WebView 跳转授权页\n'
          '3. 获取 authorization_code\n4. 换取 access_token\n'
          '5. 使用 token 调用 GitHub API\n\n'
          '> 注意：token 需加密存储，使用 AES-256',
      priority: NotePriority.high,
      tags: ['GitHub', 'OAuth', '同步'],
    ),
    NoteModel(
      title: 'Markdown 编辑器功能清单',
      content: '## 核心功能\n\n'
          '- [x] 标题输入\n- [x] Markdown 内容编辑\n'
          '- [x] 实时预览切换\n- [ ] 工具栏（加粗、斜体、链接等）\n'
          '- [ ] 图片插入\n- [ ] 代码块高亮\n\n'
          '### 快捷键\n\n'
          '| 快捷键 | 功能 |\n|--------|------|\n'
          '| Ctrl+B | 加粗 |\n| Ctrl+I | 斜体 |\n'
          '| Ctrl+K | 插入链接 |',
      priority: NotePriority.medium,
      tags: ['编辑器', 'Markdown'],
    ),
  ];

  final List<NoteModel> _notes;

  @override
  Future<List<NoteModel>> getAllNotes() async {
    return List.from(
      _notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<NoteModel> addNote(NoteModel note) async {
    _notes.add(note);
    return note;
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
  }

  @override
  Stream<List<NoteModel>> watchAllNotes() async* {
    yield await getAllNotes();
  }
}
