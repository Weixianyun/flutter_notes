import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';
import '../../models/diagram_block.dart';
import '../../models/diagram_language.dart';
import 'latex_renderer.dart';
import 'mermaid_renderer.dart';
import 'plantuml_renderer.dart';

/// 统一调度器：根据 [DiagramBlock.language] 选择合适的渲染器
///
/// 目前实现的渲染目标：
/// - [DiagramLanguage.mermaid] → [MermaidRenderer]
/// - [DiagramLanguage.latex] / [DiagramLanguage.math] / [DiagramLanguage.katex] → [LatexRenderer]（块级）
/// - [DiagramLanguage.plantuml] → [PlantumlRenderer]（使用 puml_canvas 离线渲染）
class DiagramBlockView extends StatelessWidget {
  const DiagramBlockView({super.key, required this.block});

  final DiagramBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.language) {
      case DiagramLanguage.mermaid:
        if (block.raw.trim().isEmpty) {
          return _EmptyDiagramHint(language: block.language);
        }
        return MermaidRenderer(code: block.raw);
      case DiagramLanguage.latex:
      case DiagramLanguage.math:
      case DiagramLanguage.katex:
        if (block.raw.trim().isEmpty) {
          return _EmptyDiagramHint(language: block.language);
        }
        return LatexRenderer(content: block.raw, isInline: false);
      case DiagramLanguage.plantuml:
        if (block.raw.trim().isEmpty) {
          return _EmptyDiagramHint(language: block.language);
        }
        return PlantumlRenderer(code: block.raw);
      case DiagramLanguage.other:
        return const SizedBox.shrink();
    }
  }
}

class _EmptyDiagramHint extends StatelessWidget {
  const _EmptyDiagramHint({required this.language});

  final DiagramLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        '空 ${language.displayLabel} 代码块',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
