import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Markdown 预览组件
///
/// 使用 flutter_markdown 渲染 Markdown 内容，
/// 支持 GitHub Flavored Markdown：表格、任务列表、删除线、代码块语言标签。
/// 自动适配当前主题的明暗模式。
class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({
    super.key,
    required this.data,
    this.scrollable = true,
  });

  final String data;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final codeBg = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF6F8FA);
    final codeFg = isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E1E2E);

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      h2: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      h3: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      p: theme.textTheme.bodyMedium?.copyWith(
        height: 1.6,
        color: colorScheme.onSurface,
      ),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: colorScheme.primary,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      codeblockPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16),
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
      ),
      checkbox: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
      ),
      del: theme.textTheme.bodyMedium?.copyWith(
        decoration: TextDecoration.lineThrough,
        color: colorScheme.onSurfaceVariant,
      ),
      a: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );

    final builders = {
      'pre': CodeBlockBuilder(
        codeBg: codeBg,
        codeFg: codeFg,
        labelColor: isDark ? const Color(0xFF6C7086) : const Color(0xFF6E7781),
        borderRadius: BorderRadius.circular(12),
      ),
    };

    if (scrollable) {
      return Markdown(
        data: data,
        styleSheet: styleSheet,
        padding: const EdgeInsets.all(16),
        selectable: true,
        extensionSet: md.ExtensionSet.gitHubWeb,
        builders: builders,
        onTapLink: _onTapLink,
        checkboxBuilder: (checked) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
      builders: builders,
      onTapLink: _onTapLink,
      checkboxBuilder: (checked) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  void _onTapLink(String text, String? href, String title) {
    if (href == null) return;
    Clipboard.setData(ClipboardData(text: href));
  }
}

/// 代码块构建器
///
/// 为 `<pre>` 元素构建自定义渲染，显示语言标签和带样式的代码内容。
class CodeBlockBuilder extends MarkdownElementBuilder {
  CodeBlockBuilder({
    required this.codeBg,
    required this.codeFg,
    required this.labelColor,
    required this.borderRadius,
  });

  final Color codeBg;
  final Color codeFg;
  final Color labelColor;
  final BorderRadius borderRadius;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final codeElement = element.children
        ?.whereType<md.Element>()
        .firstWhere((e) => e.tag == 'code', orElse: () => element);

    String? language;
    if (codeElement != null) {
      final className = codeElement.attributes['class'];
      if (className != null) {
        final match = RegExp(r'language-(\w+)').firstMatch(className);
        language = match?.group(1);
      }
    }

    final code = element.textContent.trimRight();

    return _CodeBlockWidget(
      code: code,
      language: language,
      codeBg: codeBg,
      codeFg: codeFg,
      labelColor: labelColor,
      borderRadius: borderRadius,
    );
  }
}

class _CodeBlockWidget extends StatelessWidget {
  const _CodeBlockWidget({
    required this.code,
    required this.language,
    required this.codeBg,
    required this.codeFg,
    required this.labelColor,
    required this.borderRadius,
  });

  final String code;
  final String? language;
  final Color codeBg;
  final Color codeFg;
  final Color labelColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: codeBg,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (language != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    language!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.copy, size: 14, color: labelColor),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: codeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
