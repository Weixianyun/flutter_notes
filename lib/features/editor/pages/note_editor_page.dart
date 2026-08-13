import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../notes/providers/notes_provider.dart';
import '../providers/editor_provider.dart';
import '../widgets/markdown_preview.dart';

/// 笔记编辑器页面
///
/// 支持新建和编辑笔记，提供 Markdown 编辑/预览切换、
/// 优先级选择和格式工具栏。通过 Riverpod [notesProvider]
/// 管理数据读写。
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.noteId});

  /// 编辑已有笔记时传入 ID，新建时不传
  final String? noteId;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late NotePriority _priority;
  late List<String> _tags;
  late final bool _isEditing;
  bool _hasChanges = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    final note = widget.noteId != null
        ? ref.read(notesProvider.notifier).getNoteById(widget.noteId!)
        : null;

    _isEditing = note != null;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _priority = note?.priority ?? NotePriority.medium;
    _tags = List.from(note?.tags ?? []);

    _titleController.addListener(_markChanged);
    _contentController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    final isPreview = ref.watch(previewModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasChanges || _isSaved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirm();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? '编辑笔记' : '新建笔记'),
          actions: [
            IconButton(
              icon: Icon(isPreview ? Icons.edit : Icons.preview),
              tooltip: isPreview ? '编辑' : '预览',
              onPressed: () {
                ref.read(previewModeProvider.notifier).state = !isPreview;
              },
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '保存',
              onPressed: _save,
            ),
          ],
        ),
        body: isPreview ? _buildPreview() : _buildEditor(colorScheme),
      ),
    );
  }

  // ── 编辑模式 ──

  Widget _buildEditor(ColorScheme colorScheme) {
    return Column(
      children: [
        // 标题输入
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            decoration: const InputDecoration(
              hintText: '输入标题...',
              border: InputBorder.none,
              filled: false,
            ),
            maxLines: 1,
            textInputAction: TextInputAction.next,
          ),
        ),
        // 优先级 + 标签
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _PrioritySelector(
                value: _priority,
                onChanged: (p) => setState(() {
                  _priority = p;
                  _hasChanges = true;
                }),
              ),
              const SizedBox(width: 8),
              if (_tags.isNotEmpty)
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: _tags.map((tag) => Chip(
                      label: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () => setState(() {
                        _tags.remove(tag);
                        _hasChanges = true;
                      }),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Markdown 工具栏
        _MarkdownToolbar(controller: _contentController),
        const Divider(height: 1),
        // 内容输入
        Expanded(
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: '开始输入 Markdown 内容...\n\n'
                  '## 支持的语法\n\n'
                  '- **加粗** / *斜体*\n'
                  '- `行内代码`\n'
                  '- > 引用\n'
                  '- - [ ] 待办列表\n'
                  '- | 表格 |\n'
                  '- ```代码块```',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.all(16),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
          ),
        ),
      ],
    );
  }

  // ── 预览模式 ──

  Widget _buildPreview() {
    final title = _titleController.text.trim();
    final content = _contentController.text;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        if (title.isNotEmpty) const SizedBox(height: 16),
        MarkdownPreview(
          data: content.isEmpty ? '*暂无内容*' : content,
          scrollable: false,
        ),
      ],
    );
  }

  // ── 保存 ──

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题和内容不能都为空')),
      );
      return;
    }

    final note = NoteModel(
      id: widget.noteId,
      title: title,
      content: content,
      priority: _priority,
      tags: _tags,
    );

    if (_isEditing) {
      ref.read(notesProvider.notifier).updateNote(note);
    } else {
      ref.read(notesProvider.notifier).addNote(note);
    }

    setState(() {
      _hasChanges = false;
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? '笔记已更新' : '笔记已创建'),
        action: SnackBarAction(
          label: '好的',
          onPressed: () {},
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  // ── 退出确认 ──

  Future<void> _showExitConfirm() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃更改？'),
        content: const Text('你有未保存的更改，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      setState(() => _hasChanges = false);
      Navigator.of(context).pop();
    }
  }
}

// ── 优先级选择器 ──

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});

  final NotePriority value;
  final ValueChanged<NotePriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<NotePriority>(
      segments: const [
        ButtonSegment(
          value: NotePriority.low,
          icon: Icon(Icons.arrow_downward, size: 14),
        ),
        ButtonSegment(
          value: NotePriority.medium,
          icon: Icon(Icons.drag_handle, size: 14),
        ),
        ButtonSegment(
          value: NotePriority.high,
          icon: Icon(Icons.arrow_upward, size: 14),
        ),
      ],
      selected: {value},
      onSelectionChanged: (set) => onChanged(set.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Markdown 格式工具栏 ──

class _MarkdownToolbar extends StatelessWidget {
  const _MarkdownToolbar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.format_bold,
            tooltip: '加粗',
            color: colorScheme.primary,
            onTap: () => _wrapSelection('**', '**'),
          ),
          _ToolButton(
            icon: Icons.format_italic,
            tooltip: '斜体',
            color: colorScheme.primary,
            onTap: () => _wrapSelection('*', '*'),
          ),
          _ToolButton(
            icon: Icons.code,
            tooltip: '行内代码',
            color: colorScheme.primary,
            onTap: () => _wrapSelection('`', '`'),
          ),
          _ToolButton(
            icon: Icons.title,
            tooltip: '标题',
            color: colorScheme.primary,
            onTap: () => _insertPrefix('## '),
          ),
          _ToolButton(
            icon: Icons.format_list_bulleted,
            tooltip: '无序列表',
            color: colorScheme.primary,
            onTap: () => _insertPrefix('- '),
          ),
          _ToolButton(
            icon: Icons.format_list_numbered,
            tooltip: '有序列表',
            color: colorScheme.primary,
            onTap: () => _insertPrefix('1. '),
          ),
          _ToolButton(
            icon: Icons.format_quote,
            tooltip: '引用',
            color: colorScheme.primary,
            onTap: () => _insertPrefix('> '),
          ),
          _ToolButton(
            icon: Icons.check_box_outlined,
            tooltip: '待办列表',
            color: colorScheme.primary,
            onTap: () => _insertPrefix('- [ ] '),
          ),
          _ToolButton(
            icon: Icons.link,
            tooltip: '链接',
            color: colorScheme.primary,
            onTap: () => _wrapSelection('[', '](url)'),
          ),
          _ToolButton(
            icon: Icons.horizontal_rule,
            tooltip: '代码块',
            color: colorScheme.primary,
            onTap: () => _wrapSelection('\n```\n', '\n```\n'),
          ),
        ],
      ),
    );
  }

  /// 在选中文本两侧包裹标记
  void _wrapSelection(String before, String after) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.isValid) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$before${text.substring(selection.start, selection.end)}$after',
      );
      controller.text = newText;
      final newOffset = selection.start + before.length;
      controller.selection = TextSelection.collapsed(offset: newOffset);
    }
  }

  /// 在行首插入前缀
  void _insertPrefix(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.isValid) {
      // 找到当前行的起始位置
      int lineStart = selection.start;
      while (lineStart > 0 && text[lineStart - 1] != '\n') {
        lineStart--;
      }
      final newText = text.replaceRange(lineStart, lineStart, prefix);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    }
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: color,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
