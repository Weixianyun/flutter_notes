import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/note_card.dart';

/// 笔记列表页面
///
/// 应用首页，展示所有笔记的卡片列表。
/// 支持搜索入口、新建笔记、列表浏览。
/// 当前使用 Mock 数据，Week 2 接入数据库后替换为真实数据源。
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  late List<NoteModel> _notes;

  @override
  void initState() {
    super.initState();
    _notes = _generateMockNotes();
  }

  /// 生成 Mock 数据（后续替换为数据库查询）
  List<NoteModel> _generateMockNotes() {
    return [
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
        content: 'Riverpod 2.x 提供编译时安全的依赖注入，'
            '配合 `riverpod_annotation` 实现代码生成。',
        priority: NotePriority.medium,
        tags: ['Riverpod', '状态管理'],
      ),
      NoteModel(
        title: 'drift 数据库设计',
        content: '设计笔记表结构：id, title, content, priority, '
            'status, tags, created_at, updated_at。',
        priority: NotePriority.low,
        tags: ['drift', '数据库'],
      ),
      NoteModel(
        title: 'GitHub OAuth 认证流程',
        content: '1. 用户点击同步按钮\n2. 打开 WebView 跳转授权页\n'
            '3. 获取 authorization_code\n4. 换取 access_token\n'
            '5. 使用 token 调用 GitHub API',
        priority: NotePriority.high,
        tags: ['GitHub', 'OAuth', '同步'],
      ),
      NoteModel(
        title: '今日待办',
        content: '- 完成 Dart 基础复习\n- 搭建应用骨架\n- 笔记列表页 UI',
        priority: NotePriority.low,
        tags: ['待办'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索笔记',
            onPressed: () => Navigator.pushNamed(context, AppRouter.search),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多',
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
      body: _notes.isEmpty ? _buildEmptyState() : _buildNotesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote,
        icon: const Icon(Icons.add),
        label: const Text('新建笔记'),
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey(note.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            onDismissed: (_) => _deleteNote(note),
            child: NoteCard(
              note: note,
              onTap: () => _openNote(note),
              onLongPress: () => _showNoteOptions(note),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.note_add_outlined,
      title: '还没有任何笔记',
      subtitle: '点击右下角按钮创建你的第一条笔记',
      actionLabel: '新建笔记',
      onAction: _createNote,
    );
  }

  void _createNote() {
    Navigator.pushNamed(context, AppRouter.editor);
  }

  void _openNote(NoteModel note) {
    Navigator.pushNamed(context, AppRouter.editor, arguments: note.id);
  }

  void _deleteNote(NoteModel note) {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除「${note.title}」'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() {
              _notes.add(note);
            });
          },
        ),
      ),
    );
  }

  void _showNoteOptions(NoteModel note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('复制内容'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('归档'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(note);
              },
            ),
          ],
        ),
      ),
    );
  }
}
