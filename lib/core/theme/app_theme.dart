import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import 'app_colors.dart';

/// 应用主题配置
///
/// 提供三套 [ThemeData]：浅色（Light）、深色（Dark）、AMOLED 真黑。
/// - 浅色 / 深色：基于 Material 3 `ColorScheme.fromSeed` 自动生成色板
/// - AMOLED：surface 全黑（#000000），极致省电且对比度更突出
///
/// 所有主题均：
/// - 启用 Material 3 (`useMaterial3: true`)
/// - 引用 [AppSpacing] / [AppRadius] / [AppDurations] 统一设计 token
/// - 提供 [TextTheme] 覆盖，统一中英文混排行高
/// - 启用 `pageTransitionsTheme` 提供更平滑的平台切换动画
class AppTheme {
  AppTheme._();

  // ── 公开 API ──

  /// 浅色主题
  static ThemeData light({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.seed,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme, isAmoled: false);
  }

  /// 深色主题
  static ThemeData dark({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.seed,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme, isAmoled: false);
  }

  /// AMOLED 真黑主题
  ///
  /// 与 [dark] 区别：surface 强制 #000000，其它衍生背景
  /// （surfaceContainer、surfaceContainerHighest）映射到不同深度的黑，
  /// 使 OLED 屏幕的"关像素"区域完全熄灭，达到极致省电与对比度效果。
  static ThemeData amoled({Color? seedColor}) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.seed,
      brightness: Brightness.dark,
    );
    final colorScheme = base.copyWith(
      surface: const Color(0xFF000000),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF050505),
      surfaceContainer: const Color(0xFF0A0A0A),
      surfaceContainerHigh: const Color(0xFF121212),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
    );
    return _buildTheme(colorScheme, isAmoled: true);
  }

  // ── 内部构造 ──

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    required bool isAmoled,
  }) {
    final scaffoldBg = isAmoled ? const Color(0xFF000000) : colorScheme.surface;
    final textTheme = _buildTextTheme(colorScheme.onSurface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      primaryTextTheme: _buildTextTheme(colorScheme.onPrimary),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      // 提供更柔和的页面切换动画
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        toolbarHeight: 56,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isAmoled
            ? const Color(0xFF0F0F0F)
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isAmoled
            ? const Color(0xFF0A0A0A)
            : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isAmoled
            ? const Color(0xFF000000)
            : colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHigh,
        circularTrackColor: colorScheme.surfaceContainerHigh,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// 中英文混排优化的 [TextTheme]
  ///
  /// 在 Material 3 默认字号基础上统一行高：
  /// - display/title 类用 1.2~1.25（紧凑）
  /// - body 用 1.5（阅读舒适）
  /// - label 用 1.4（按钮/标签平衡）
  static TextTheme _buildTextTheme(Color base) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: AppFontSizes.displayLarge,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: base,
        height: AppLineHeights.display,
      ),
      displayMedium: TextStyle(
        fontSize: AppFontSizes.displayMedium,
        fontWeight: FontWeight.w400,
        color: base,
        height: AppLineHeights.display,
      ),
      displaySmall: TextStyle(
        fontSize: AppFontSizes.displaySmall,
        fontWeight: FontWeight.w400,
        color: base,
        height: AppLineHeights.display,
      ),
      headlineLarge: TextStyle(
        fontSize: AppFontSizes.headlineLarge,
        fontWeight: FontWeight.w600,
        color: base,
        height: AppLineHeights.title,
      ),
      headlineMedium: TextStyle(
        fontSize: AppFontSizes.headlineMedium,
        fontWeight: FontWeight.w600,
        color: base,
        height: AppLineHeights.title,
      ),
      headlineSmall: TextStyle(
        fontSize: AppFontSizes.headlineSmall,
        fontWeight: FontWeight.w600,
        color: base,
        height: AppLineHeights.title,
      ),
      titleLarge: TextStyle(
        fontSize: AppFontSizes.titleLarge,
        fontWeight: FontWeight.w600,
        color: base,
        height: AppLineHeights.title,
      ),
      titleMedium: TextStyle(
        fontSize: AppFontSizes.titleMedium,
        fontWeight: FontWeight.w600,
        color: base,
        height: AppLineHeights.title,
      ),
      titleSmall: TextStyle(
        fontSize: AppFontSizes.titleSmall,
        fontWeight: FontWeight.w500,
        color: base,
        height: AppLineHeights.title,
      ),
      bodyLarge: TextStyle(
        fontSize: AppFontSizes.bodyLarge,
        fontWeight: FontWeight.w400,
        color: base,
        height: AppLineHeights.body,
      ),
      bodyMedium: TextStyle(
        fontSize: AppFontSizes.bodyMedium,
        fontWeight: FontWeight.w400,
        color: base,
        height: AppLineHeights.body,
      ),
      bodySmall: TextStyle(
        fontSize: AppFontSizes.bodySmall,
        fontWeight: FontWeight.w400,
        color: base,
        height: AppLineHeights.body,
      ),
      labelLarge: TextStyle(
        fontSize: AppFontSizes.labelLarge,
        fontWeight: FontWeight.w500,
        color: base,
        height: AppLineHeights.label,
      ),
      labelMedium: TextStyle(
        fontSize: AppFontSizes.labelMedium,
        fontWeight: FontWeight.w500,
        color: base,
        height: AppLineHeights.label,
      ),
      labelSmall: TextStyle(
        fontSize: AppFontSizes.labelSmall,
        fontWeight: FontWeight.w500,
        color: base,
        height: AppLineHeights.label,
      ),
    );
  }
}
