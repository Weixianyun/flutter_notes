/// 图表/数学代码块支持的语言枚举
///
/// 涵盖 Week 8 新增的图表与数学语法：
/// - [mermaid]：流程图、时序图、类图等
/// - [latex]：LaTeX 数学公式（块级 `$$..$$` 与行内 `$..$`）
/// - [math]：LaTeX 的别名（GitHub Flavored Markdown 风格）
/// - [plantuml]：PlantUML 图（暂用降级渲染）
/// - [katex]：KaTeX 风格公式
/// - [other]：未识别的语言（按普通代码块处理）
enum DiagramLanguage {
  mermaid,
  latex,
  math,
  katex,
  plantuml,
  other;

  /// 代码块语言标记（如 ` ```mermaid `）→ [DiagramLanguage]
  ///
  /// 识别规则：
  /// - 忽略前后空白与大小写
  /// - `mermaid` / `mmd` → [mermaid]
  /// - `latex` / `tex` → [latex]
  /// - `math` / `katex` → [math] / [katex]
  /// - `plantuml` / `puml` / `uml` → [plantuml]
  /// - 其它或空 → [other]
  static DiagramLanguage fromCodeFence(String? info) {
    if (info == null) return DiagramLanguage.other;
    final normalized = info.trim().toLowerCase();
    if (normalized.isEmpty) return DiagramLanguage.other;
    switch (normalized) {
      case 'mermaid':
      case 'mmd':
        return DiagramLanguage.mermaid;
      case 'latex':
      case 'tex':
        return DiagramLanguage.latex;
      case 'math':
        return DiagramLanguage.math;
      case 'katex':
        return DiagramLanguage.katex;
      case 'plantuml':
      case 'puml':
      case 'uml':
        return DiagramLanguage.plantuml;
      default:
        return DiagramLanguage.other;
    }
  }

  /// 是否由 [DiagramRenderer] 直接渲染（不作为普通代码块）
  bool get isDiagram =>
      this == DiagramLanguage.mermaid ||
      this == DiagramLanguage.latex ||
      this == DiagramLanguage.math ||
      this == DiagramLanguage.katex ||
      this == DiagramLanguage.plantuml;

  /// 渲染层显示用的标签
  String get displayLabel {
    switch (this) {
      case DiagramLanguage.mermaid:
        return 'Mermaid';
      case DiagramLanguage.latex:
      case DiagramLanguage.math:
      case DiagramLanguage.katex:
        return 'Math';
      case DiagramLanguage.plantuml:
        return 'PlantUML';
      case DiagramLanguage.other:
        return 'Code';
    }
  }
}
