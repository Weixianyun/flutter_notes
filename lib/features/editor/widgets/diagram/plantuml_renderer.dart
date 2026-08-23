import 'package:flutter/material.dart';
import 'package:puml_canvas/puml_canvas.dart';

import '../../../../core/design/design_tokens.dart';

/// PlantUML 图渲染器
///
/// 使用 puml_canvas 解析 PlantUML 源码并在 Canvas 上绘制。
/// 若源码不合法（缺少 `@startuml`/`@enduml` 包裹），自动补充围栏后再尝试。
class PlantumlRenderer extends StatefulWidget {
  const PlantumlRenderer({
    super.key,
    required this.code,
    this.minHeight = 180,
  });

  final String code;
  final double minHeight;

  @override
  State<PlantumlRenderer> createState() => _PlantumlRendererState();
}

class _PlantumlRendererState extends State<PlantumlRenderer> {
  late String _normalized;

  @override
  void initState() {
    super.initState();
    _normalized = _ensureBoundaries(widget.code);
  }

  @override
  void didUpdateWidget(covariant PlantumlRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      _normalized = _ensureBoundaries(widget.code);
    }
  }

  /// 自动补全 @startuml / @enduml 围栏（很多用户写时省略）
  static String _ensureBoundaries(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return trimmed;
    var src = trimmed;
    if (!RegExp(r'@start\w+').hasMatch(src)) {
      src = '@startuml\n$src';
    }
    if (!RegExp(r'@end\w+').hasMatch(src)) {
      src = '$src\n@enduml';
    }
    return src;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF1E1E2E)
        : const Color(0xFFF6F8FA);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: widget.minHeight),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: PumlView(source: _normalized),
      ),
    );
  }
}
