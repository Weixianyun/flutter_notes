import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/design/design_tokens.dart';
import '../services/wiki_link_processor.dart';

/// Markdown 预览组件
///
/// 使用 flutter_markdown 渲染 Markdown 内容，
/// 支持 GitHub Flavored Markdown：表格、任务列表、删除线、代码块语法高亮。
/// 自动适配当前主题的明暗模式。
///
/// ## Wiki-Link 支持
/// 输入文本中的 `[[Target]]`、`[[Target#Heading]]`、`[[Target|Alias]]` 会被预处理
/// 替换为指向 `#wiki:Target` 的 markdown 链接，组件通过 [onWikiLinkTap] 回调
/// 把点击事件转发给业务层处理（导航到对应笔记）。未设置 [onWikiLinkTap] 时，
/// wiki-link 与普通文本一样不可点击。
class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({
    super.key,
    required this.data,
    this.scrollable = true,
    this.onWikiLinkTap,
    WikiLinkProcessor? processor,
  }) : _processor = processor;

  final String data;
  final bool scrollable;

  /// 用户点击 wiki-link 时的回调，参数为目标笔记标题与可选 heading
  final void Function(String target, String? heading)? onWikiLinkTap;

  final WikiLinkProcessor? _processor;

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
        height: AppLineHeights.body + 0.1,
        color: colorScheme.onSurface,
      ),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: colorScheme.primary,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      codeblockPadding: const EdgeInsets.fromLTRB(
        0,
        AppSpacing.xs,
        0,
        0,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: AppSpacing.md),
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        height: AppLineHeights.body,
      ),
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant,
        borderRadius: AppRadius.allSm,
      ),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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
        isDark: isDark,
        borderRadius: AppRadius.allMd,
      ),
    };

    final processedData =
        (_processor ?? const WikiLinkProcessor()).process(data);

    if (scrollable) {
      return Markdown(
        data: processedData,
        styleSheet: styleSheet,
        padding: const EdgeInsets.all(AppSpacing.md),
        selectable: true,
        extensionSet: md.ExtensionSet.gitHubWeb,
        builders: builders,
        onTapLink: (text, href, title) => _onTapLink(text, href, title),
        checkboxBuilder: (checked) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xxs),
          child: Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return MarkdownBody(
      data: processedData,
      styleSheet: styleSheet,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
      builders: builders,
      onTapLink: (text, href, title) => _onTapLink(text, href, title),
      checkboxBuilder: (checked) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xxs),
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
    if (href.startsWith('#wiki:')) {
      final target = WikiLinkProcessor.extractTarget(href);
      final heading = WikiLinkProcessor.extractHeading(href);
      if (target != null) {
        onWikiLinkTap?.call(target, heading);
      }
      return;
    }
    Clipboard.setData(ClipboardData(text: href));
  }
}

/// 代码块构建器
///
/// 为 `<pre>` 元素构建自定义渲染，支持语法高亮和语言标签。
class CodeBlockBuilder extends MarkdownElementBuilder {
  CodeBlockBuilder({
    required this.codeBg,
    required this.codeFg,
    required this.labelColor,
    required this.isDark,
    required this.borderRadius,
  });

  final Color codeBg;
  final Color codeFg;
  final Color labelColor;
  final bool isDark;
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
      isDark: isDark,
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
    required this.isDark,
    required this.borderRadius,
  });

  final String code;
  final String? language;
  final Color codeBg;
  final Color codeFg;
  final Color labelColor;
  final bool isDark;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final highlightTheme = isDark ? atomOneDarkTheme : githubTheme;

    return Container(
      decoration: BoxDecoration(
        color: codeBg,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (language != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xxs,
              ),
              child: Row(
                children: [
                  Text(
                    language!,
                    style: TextStyle(
                      fontSize: AppFontSizes.labelSmall,
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
          HighlightView(
            code,
            language: language ?? 'plaintext',
            theme: highlightTheme,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xxs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: AppFontSizes.bodyMedium,
              height: AppLineHeights.body,
            ),
          ),
        ],
      ),
    );
  }
}
