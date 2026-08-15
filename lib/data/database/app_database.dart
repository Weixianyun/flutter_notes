import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 笔记表
///
/// 存储笔记的完整数据，枚举和标签列表以字符串形式持久化。
/// 主键为 UUID 字符串。
class Notes extends Table {
  /// UUID 主键
  TextColumn get id => text()();

  /// 标题
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Markdown 正文
  TextColumn get content => text().withDefault(const Constant(''))();

  /// 优先级（枚举名称：low / medium / high）
  TextColumn get priority =>
      text().withDefault(const Constant('medium'))();

  /// 状态（枚举名称：draft / published / archived）
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// 标签列表（JSON 数组字符串）
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// 创建时间
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 更新时间
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 软删除时间（null 表示未删除）
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 应用数据库
///
/// 基于 drift 的本地 SQLite 数据库，管理笔记数据的持久化存储。
/// 使用 [AppDatabase.forTesting] 可创建内存数据库用于测试。
@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用构造函数（内存数据库，不持久化）
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts(m);
          await _seedData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(notes, notes.deletedAt);
            await _createFts(m);
            await _populateFts();
          }
        },
      );

  /// 创建 FTS5 全文索引虚拟表和触发器
  Future<void> _createFts(Migrator m) async {
    await m.database.customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        note_id UNINDEXED,
        title,
        content,
        tags,
        tokenize = 'unicode61'
      );
    ''');

    await m.database.customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(note_id, title, content, tags)
        VALUES (new.id, new.title, new.content, new.tags);
      END;
    ''');

    await m.database.customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
        DELETE FROM notes_fts WHERE note_id = old.id;
      END;
    ''');

    await m.database.customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
        DELETE FROM notes_fts WHERE note_id = old.id;
        INSERT INTO notes_fts(note_id, title, content, tags)
        VALUES (new.id, new.title, new.content, new.tags);
      END;
    ''');
  }

  /// 从现有笔记数据填充 FTS 索引
  Future<void> _populateFts() async {
    await customStatement('''
      INSERT INTO notes_fts(note_id, title, content, tags)
      SELECT id, title, content, tags FROM notes;
    ''');
  }

  /// 首次创建时插入种子数据
  Future<void> _seedData() async {
    final now = DateTime.now();
    final seedNotes = [
      NotesCompanion.insert(
        id: 'seed-1',
        title: const Value('Dart 3 空安全实践'),
        content: const Value(
          '## 空安全核心\n\nDart 3 的空安全是健全的（sound），'
              '类型系统层面保证非空变量不会持有 `null`。\n\n'
              '关键操作符：`?` `!` `??` `?.`',
        ),
        priority: const Value('high'),
        tags: const Value('["Dart","空安全"]'),
        createdAt: Value(now.subtract(const Duration(hours: 5))),
        updatedAt: Value(now.subtract(const Duration(hours: 5))),
      ),
      NotesCompanion.insert(
        id: 'seed-2',
        title: const Value('Flutter Material 3 主题配置'),
        content: const Value(
          '使用 `ColorScheme.fromSeed` 生成完整色板，'
              '配合 `ThemeData` 定制 AppBar、Card、输入框等组件样式。',
        ),
        priority: const Value('medium'),
        tags: const Value('["Flutter","Material3","主题"]'),
        createdAt: Value(now.subtract(const Duration(hours: 4))),
        updatedAt: Value(now.subtract(const Duration(hours: 4))),
      ),
      NotesCompanion.insert(
        id: 'seed-3',
        title: const Value('Riverpod 状态管理入门'),
        content: const Value(
          '## Riverpod 核心概念\n\n'
              '- **Provider**：只读状态\n'
              '- **NotifierProvider**：可变状态（推荐）\n'
              '- **FutureProvider**：异步状态\n'
              '- **StreamProvider**：流式状态\n\n'
              '```dart\nclass CounterNotifier extends Notifier<int> {\n'
              '  @override\n  int build() => 0;\n\n'
              '  void increment() => state++;\n}\n```',
        ),
        priority: const Value('medium'),
        tags: const Value('["Riverpod","状态管理"]'),
        createdAt: Value(now.subtract(const Duration(hours: 3))),
        updatedAt: Value(now.subtract(const Duration(hours: 3))),
      ),
      NotesCompanion.insert(
        id: 'seed-4',
        title: const Value('drift 数据库设计'),
        content: const Value(
          '设计笔记表结构：\n\n'
              '| 字段 | 类型 | 说明 |\n|------|------|------|\n'
              '| id | TEXT | UUID 主键 |\n| title | TEXT | 标题 |\n'
              '| content | TEXT | Markdown 正文 |\n'
              '| priority | TEXT | 优先级枚举 |\n'
              '| status | TEXT | 状态枚举 |\n'
              '| tags | TEXT | JSON 数组 |\n'
              '| created_at | INTEGER | 创建时间戳 |\n'
              '| updated_at | INTEGER | 更新时间戳 |',
        ),
        priority: const Value('low'),
        tags: const Value('["drift","数据库"]'),
        createdAt: Value(now.subtract(const Duration(hours: 2))),
        updatedAt: Value(now.subtract(const Duration(hours: 2))),
      ),
      NotesCompanion.insert(
        id: 'seed-5',
        title: const Value('GitHub OAuth 认证流程'),
        content: const Value(
          '1. 用户点击同步按钮\n2. 打开 WebView 跳转授权页\n'
              '3. 获取 authorization_code\n4. 换取 access_token\n'
              '5. 使用 token 调用 GitHub API\n\n'
              '> 注意：token 需加密存储，使用 AES-256',
        ),
        priority: const Value('high'),
        tags: const Value('["GitHub","OAuth","同步"]'),
        createdAt: Value(now.subtract(const Duration(hours: 1))),
        updatedAt: Value(now.subtract(const Duration(hours: 1))),
      ),
      NotesCompanion.insert(
        id: 'seed-6',
        title: const Value('Markdown 编辑器功能清单'),
        content: const Value(
          '## 核心功能\n\n'
              '- [x] 标题输入\n- [x] Markdown 内容编辑\n'
              '- [x] 实时预览切换\n- [ ] 工具栏（加粗、斜体、链接等）\n'
              '- [ ] 图片插入\n- [ ] 代码块高亮\n\n'
              '### 快捷键\n\n'
              '| 快捷键 | 功能 |\n|--------|------|\n'
              '| Ctrl+B | 加粗 |\n| Ctrl+I | 斜体 |\n'
              '| Ctrl+K | 插入链接 |',
        ),
        priority: const Value('medium'),
        tags: const Value('["编辑器","Markdown"]'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ];

    await batch((b) {
      b.insertAll(notes, seedNotes);
    });
  }
}

/// 生产环境数据库连接
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'flutter_notes.db'));
    return NativeDatabase(file);
  });
}
