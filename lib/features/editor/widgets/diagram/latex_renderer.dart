import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../../core/design/design_tokens.dart';

/// LaTeX 公式渲染器
///
/// 调用 [Math.tex] 渲染行内（`$..$`）或块级（`$$..$$`）公式。
/// 渲染失败时降级为原文 + 错误提示。
class LatexRenderer extends StatelessWidget {
  const LatexRenderer({
    super.key,
    required this.content,
    required this.isInline,
    this.fontSize,
  });

  /// 公式内容（不含 `$` 围栏）
  final String content;

  /// 行内 / 块级
  final bool isInline;

  /// 自定义字号（可选）
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseSize = fontSize ??
        (isInline ? AppFontSizes.bodyMedium : AppFontSizes.bodyMedium + 4);
    final color = theme.colorScheme.onSurface;

    if (isInline) {
      return Math.tex(
        content,
        mathStyle: MathStyle.text,
        textStyle: TextStyle(fontSize: baseSize, color: color),
        onErrorFallback: (err) => _ErrorFallback(
          content: content,
          message: err.messageWithType,
          inline: true,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          content,
          mathStyle: MathStyle.display,
          textStyle: TextStyle(fontSize: baseSize, color: color),
          onErrorFallback: (err) => _ErrorFallback(
            content: content,
            message: err.messageWithType,
            inline: false,
          ),
        ),
      ),
    );
  }
}

class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({
    required this.content,
    required this.message,
    required this.inline,
  });

  final String content;
  final String message;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.allXs,
      ),
      child: Text(
        'LaTeX 错误: $message',
        style: (inline
                ? theme.textTheme.bodySmall
                : theme.textTheme.bodyMedium)
            ?.copyWith(color: colorScheme.error, fontFamily: 'monospace'),
      ),
    );
  }
}
