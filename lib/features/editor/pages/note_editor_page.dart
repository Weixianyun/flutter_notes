import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../../services/service_providers.dart';
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
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();

    if (widget.noteId != null) {
      _isLoading = true;
      _isEditing = true;
      _priority = NotePriority.medium;
      _tags = [];
      _loadNote();
    } else {
      _isEditing = false;
      _priority = NotePriority.medium;
      _tags = [];
    }

    _titleController.addListener(_markChanged);
    _contentController.addListener(_markChanged);
  }

  Future<void> _loadNote() async {
    final note = await ref.read(notesProvider.notifier).getNoteById(
          widget.noteId!,
        );
    if (note != null && mounted) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      setState(() {
        _priority = note.priority;
        _tags = List.from(note.tags);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: '导出',
                onPressed: _exportCurrentNote,
              ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '保存',
              onPressed: _isSaving ? null : _save,
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题和内容不能都为空')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final note = NoteModel(
      id: widget.noteId,
      title: title,
      content: content,
      priority: _priority,
      tags: _tags,
    );

    if (_isEditing) {
      await ref.read(notesProvider.notifier).updateNote(note);
    } else {
      await ref.read(notesProvider.notifier).addNote(note);
    }

    if (!mounted) return;

    setState(() {
      _hasChanges = false;
      _isSaved = true;
      _isSaving = false;
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

  Future<void> _exportCurrentNote() async {
    final note = await ref.read(notesProvider.notifier).getNoteById(widget.noteId!);
    if (note == null) return;

    try {
      final exportService = ref.read(exportServiceProvider);
      final filePath = await exportService.exportNote(note);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出成功'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('已导出为 Markdown 文件：'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('路径已复制')),
                );
              },
              child: const Text('复制路径'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
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
            icon: Icons.image_outlined,
            tooltip: '图片',
            color: colorScheme.primary,
            onTap: () => _showImageDialog(context),
          ),
          _ToolButton(
            icon: Icons.horizontal_rule,
            tooltip: '代码块',
            color: colorScheme.primary,
            onTap: () => _wrapSelection('\n```dart\n', '\n```\n'),
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

  /// 在光标位置插入文本
  void _insertAtCursor(String text) {
    final currentText = controller.text;
    final selection = controller.selection;
    final insertOffset = selection.isValid ? selection.start : currentText.length;
    final newText = currentText.replaceRange(
      insertOffset,
      selection.isValid ? selection.end : currentText.length,
      text,
    );
    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: insertOffset + text.length,
    );
  }

  /// 图片插入对话框
  void _showImageDialog(BuildContext context) {
    final urlController = TextEditingController();
    final altController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('插入图片'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '图片 URL',
                hintText: 'https://example.com/image.png',
                prefixIcon: Icon(Icons.link, size: 20),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: altController,
              decoration: const InputDecoration(
                labelText: '替代文本',
                hintText: '图片描述（可选）',
                prefixIcon: Icon(Icons.text_fields, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final url = urlController.text.trim();
              final alt = altController.text.trim();
              if (url.isNotEmpty) {
                _insertAtCursor('![$alt]($url)');
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('插入'),
          ),
        ],
      ),
    );
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
