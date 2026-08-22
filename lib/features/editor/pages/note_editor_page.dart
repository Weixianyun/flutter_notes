import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/service_providers.dart';
import '../../notes/providers/notes_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/autosave_provider.dart';
import '../providers/editor_provider.dart';
import '../widgets/markdown_preview.dart';

/// 笔记编辑器页面
///
/// 支持新建和编辑笔记，提供 Markdown 编辑/预览切换、
/// 优先级选择和格式工具栏。通过 Riverpod [notesProvider]
/// 管理数据读写。
///
/// ## 自动保存
/// 编辑模式下，标题或内容变更后 1.5 秒防抖触发 [autosaveStateProvider]
/// 过渡：`idle` → `saving` → `saved(timestamp)`。保存失败显示 `error` 状态。
/// AppBar 底部展示字数、字符数和保存状态指示器。
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.noteId, this.highlight});

  /// 编辑已有笔记时传入 ID，新建时不传
  final String? noteId;

  /// 进入后需要高亮并选中的关键词（来自搜索跳转）
  final String? highlight;

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

  /// 自动保存防抖定时器
  Timer? _autosaveTimer;

  /// 触发自动保存的空闲时长
  static const _autosaveDelay = Duration(milliseconds: 1500);

  /// 最后一次保存成功的标题/内容快照，用于检测实际变更
  String _lastSavedTitle = '';
  String _lastSavedContent = '';

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
      // 新建笔记：使用用户配置的默认优先级
      _priority = ref.read(defaultPriorityProvider);
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
      _lastSavedTitle = note.title;
      _lastSavedContent = note.content;
      setState(() {
        _priority = note.priority;
        _tags = List.from(note.tags);
        _isLoading = false;
      });
      _applyHighlightIfNeeded();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 若携带 [widget.highlight],在笔记内容中定位第一处匹配并选中
  void _applyHighlightIfNeeded() {
    final token = widget.highlight?.trim();
    if (token == null || token.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hit = _findFirstMatch(_titleController.text, token) ??
          _findFirstMatch(_contentController.text, token);
      if (hit == null) return;
      if (hit.inTitle) {
        _titleController.selection = TextSelection(
          baseOffset: hit.start,
          extentOffset: hit.end,
        );
      } else {
        _contentController.selection = TextSelection(
          baseOffset: hit.start,
          extentOffset: hit.end,
        );
      }
    });
  }

  _HighlightHit? _findFirstMatch(String text, String token) {
    if (text.isEmpty || token.isEmpty) return null;
    final lower = text.toLowerCase();
    final lowerToken = token.toLowerCase();
    final idx = lower.indexOf(lowerToken);
    if (idx < 0) return null;
    return _HighlightHit(idx, idx + token.length, text == _titleController.text);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
    if (_isEditing) _scheduleAutosave();
  }

  /// 调度一次防抖自动保存
  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, _autosave);
  }

  /// 执行自动保存（仅编辑模式）
  Future<void> _autosave() async {
    if (!_isEditing || !mounted) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // 标题和内容都没变，跳过
    if (title == _lastSavedTitle && content == _lastSavedContent) return;

    // 两者都为空也不保存
    if (title.isEmpty && content.isEmpty) return;

    ref.read(autosaveStateProvider.notifier).state =
        const AutosaveState(status: AutosaveStatus.saving);

    final note = NoteModel(
      id: widget.noteId,
      title: title,
      content: content,
      priority: _priority,
      tags: _tags,
    );

    try {
      await ref.read(notesProvider.notifier).updateNote(note);
      _lastSavedTitle = title;
      _lastSavedContent = content;
      if (!mounted) return;
      ref.read(autosaveStateProvider.notifier).state = AutosaveState(
        status: AutosaveStatus.saved,
        savedAt: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      ref.read(autosaveStateProvider.notifier).state = AutosaveState(
        status: AutosaveStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPreview = ref.watch(previewModeProvider);
    // 新建笔记：默认按设置决定（auto preview），用户手动切换后跟随 previewModeProvider。
    // 编辑笔记：完全跟随用户切换状态。
    final autoPreview = ref.watch(markdownAutoPreviewProvider);
    final effectivePreview = !_isEditing
        ? (autoPreview || isPreview)
        : isPreview;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
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
          title: Text(_isEditing ? l10n.editorTitleEdit : l10n.editorTitleNew),
          actions: [
            IconButton(
              icon: Icon(effectivePreview ? Icons.edit : Icons.preview),
              tooltip: effectivePreview ? l10n.editTooltip : l10n.previewTooltip,
              onPressed: () {
                ref.read(previewModeProvider.notifier).state = !effectivePreview;
              },
            ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: l10n.exportTooltip,
                onPressed: _exportCurrentNote,
              ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: l10n.saveAction,
              onPressed: _isSaving ? null : _save,
            ),
          ],
          bottom: _isEditing
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(36),
                  child: _EditorStatusBar(
                    contentController: _contentController,
                  ),
                )
              : null,
        ),
        body: effectivePreview ? _buildPreview() : _buildEditor(colorScheme),
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
              hintText: '...',
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
              hintText: '',
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
    // 取消挂起的自动保存
    _autosaveTimer?.cancel();

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

// ── 编辑器底部状态栏：字数 + 字符数 + 自动保存状态 ──

class _EditorStatusBar extends ConsumerWidget {
  const _EditorStatusBar({
    required this.contentController,
  });

  final TextEditingController contentController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final autosave = ref.watch(autosaveStateProvider);

    // 监听内容变化以刷新字数统计
    final content = contentController.text;
    final words = _countWords(content);
    final chars = content.length;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (autosave.status) {
      case AutosaveStatus.idle:
        statusText = l10n.autosaveIdle;
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.edit_note;
      case AutosaveStatus.saving:
        statusText = l10n.autosaveSaving;
        statusColor = colorScheme.primary;
        statusIcon = Icons.cloud_sync_outlined;
      case AutosaveStatus.saved:
        final time = _formatTime(autosave.savedAt!);
        statusText = l10n.autosaveSavedAt(time);
        statusColor = colorScheme.tertiary;
        statusIcon = Icons.check_circle_outline;
      case AutosaveStatus.error:
        statusText = l10n.autosaveError;
        statusColor = colorScheme.error;
        statusIcon = Icons.error_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColor,
                ),
          ),
          const Spacer(),
          Text(
            '${l10n.wordCount(words)} · ${l10n.charCount(chars)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 按空白字符分词计算字数
  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    // CJK 字符按 1 字计数，连续 ASCII 字母/数字按 1 词计数
    final cjk = RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]');
    final cjkCount = cjk.allMatches(trimmed).length;
    final ascii = trimmed
        .replaceAll(cjk, ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
    return cjkCount + ascii;
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
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

/// 内部辅助：标识一次匹配的位置
class _HighlightHit {
  const _HighlightHit(this.start, this.end, this.inTitle);
  final int start;
  final int end;
  final bool inTitle;
}
