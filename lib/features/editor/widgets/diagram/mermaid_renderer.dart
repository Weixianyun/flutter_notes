import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';

import '../../../../core/design/design_tokens.dart';

/// Mermaid 图表渲染容器
///
/// 用 [MermaidDiagram] 渲染用户提供的图表源码；
/// 主题跟随当前 [Brightness] 切换 `MermaidStyle`。
/// 渲染失败时降级显示错误信息与原始代码。
class MermaidRenderer extends StatelessWidget {
  const MermaidRenderer({
    super.key,
    required this.code,
    this.minHeight = 120,
    this.borderRadius,
  });

  /// Mermaid 源码
  final String code;

  /// 容器最小高度
  final double minHeight;

  /// 圆角
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.allMd;
    final bg = isDark
        ? const Color(0xFF1E1E2E)
        : const Color(0xFFF6F8FA);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: MermaidDiagram(
        code: code,
        style: isDark ? MermaidStyle.dark() : MermaidStyle.forest(),
      ),
    );
  }
}

/// 在 markdown 解析失败或代码为空时使用的占位组件
class MermaidErrorBlock extends StatelessWidget {
  const MermaidErrorBlock({
    super.key,
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Mermaid 渲染失败',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: AppFontSizes.bodySmall,
              color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E1E2E),
            ),
          ),
        ],
      ),
    );
  }
}

/// 引入 highlight 主题以避免 pubspec 警告（githubTheme / atomOneDarkTheme 也用于代码块）
// ignore: unused_element
void _ensureHighlightThemes() {
  githubTheme;
  atomOneDarkTheme;
}
