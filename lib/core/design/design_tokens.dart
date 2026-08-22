import 'package:flutter/material.dart';

/// 应用间距系统（8 倍数阶梯）
///
/// 所有 UI 间距必须使用这里定义的常量，避免散落的 5/7/13 等任意数字。
/// Material 3 推荐以 8dp 为基准，必要时折半或加倍。
class AppSpacing {
  AppSpacing._();

  /// 4dp：紧凑场景（图标内边距、小型标签）
  static const double xxs = 4;

  /// 8dp：标准小间距（图标与文字、列表项内）
  static const double xs = 8;

  /// 12dp：组件内边距（卡片内小段）
  static const double sm = 12;

  /// 16dp：标准间距（卡片内边距、列表项左右内边距）
  static const double md = 16;

  /// 20dp：较大间距（区块之间）
  static const double lg = 20;

  /// 24dp：大间距（页面顶部留白）
  static const double xl = 24;

  /// 32dp：超大间距（页面分割）
  static const double xxl = 32;

  /// 48dp：特大间距（Hero 区域）
  static const double xxxl = 48;

  /// 64dp：极限间距（启动页留白）
  static const double huge = 64;
}

/// 应用圆角系统（5 档）
///
/// 与 Material 3 组件（Card=12, Dialog=28, FAB=16）保持一致。
class AppRadius {
  AppRadius._();

  /// 4dp：标签、小徽章
  static const double xs = 4;

  /// 8dp：Chip、输入框
  static const double sm = 8;

  /// 12dp：Card、ListTile、Button
  static const double md = 12;

  /// 16dp：Dialog、大卡片
  static const double lg = 16;

  /// 28dp：FAB、特殊强调容器
  static const double xl = 28;

  /// 便捷：构造 BorderRadius
  static BorderRadius get allXs => BorderRadius.circular(xs);
  static BorderRadius get allSm => BorderRadius.circular(sm);
  static BorderRadius get allMd => BorderRadius.circular(md);
  static BorderRadius get allLg => BorderRadius.circular(lg);
  static BorderRadius get allXl => BorderRadius.circular(xl);
}

/// 应用动画时长（3 档 + 1 特殊）
///
/// 选值依据 Material 3 motion：
/// - 简单属性（颜色、尺寸）：150ms
/// - 容器/页面切换：280ms
/// - 复杂动效（多属性插值）：400ms
class AppDurations {
  AppDurations._();

  /// 150ms：颜色、淡入淡出、按钮反馈
  static const Duration fast = Duration(milliseconds: 150);

  /// 280ms：标准容器变化、页面切换
  static const Duration medium = Duration(milliseconds: 280);

  /// 400ms：复杂组合动效
  static const Duration slow = Duration(milliseconds: 400);

  /// 280ms × 1.5：列表项错位进入（stagger）
  static const Duration stagger = Duration(milliseconds: 420);
}

/// 应用动画曲线
class AppCurves {
  AppCurves._();

  /// 强调曲线：Material 3 emphasized 替代
  static const Curve emphasized = Cubic(0.2, 0.0, 0, 1.0);

  /// 标准缓出：easeOutCubic 等价
  static const Curve easeOut = Cubic(0.33, 1.0, 0.68, 1.0);

  /// 标准缓入：easeInCubic 等价
  static const Curve easeIn = Cubic(0.55, 0.06, 0.68, 0.19);
}

/// TextTheme 行高（Material 3 推荐）
///
/// 中英文混排时行高 1.3~1.5 之间最为平衡：
/// - display/title 类（粗体大字号）→ 1.2
/// - body 类（正文）→ 1.5
/// - label 类（小字、按钮）→ 1.4
class AppLineHeights {
  AppLineHeights._();

  static const double display = 1.2;
  static const double title = 1.25;
  static const double body = 1.5;
  static const double label = 1.4;
}

/// TextTheme 字号阶梯（Material 3 typography）
class AppFontSizes {
  AppFontSizes._();

  static const double displayLarge = 57;
  static const double displayMedium = 45;
  static const double displaySmall = 36;
  static const double headlineLarge = 32;
  static const double headlineMedium = 28;
  static const double headlineSmall = 24;
  static const double titleLarge = 22;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 11;
}

/// 在已有 [TextStyle] 上叠加指定行高
TextStyle withLineHeight(TextStyle base, double lineHeight) {
  return base.copyWith(height: lineHeight);
}
