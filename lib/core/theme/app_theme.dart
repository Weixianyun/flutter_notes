import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 应用主题配置
///
/// 提供三套 [ThemeData]：浅色（Light）、深色（Dark）、AMOLED 真黑。
/// - 浅色 / 深色：基于 Material 3 `ColorScheme.fromSeed` 自动生成色板
/// - AMOLED：surface 全黑（#000000），极致省电且对比度更突出
///
/// 所有主题均：
/// - 启用 Material 3 (`useMaterial3: true`)
/// - 定制 AppBar / Card / 输入框 / 列表 / 导航栏组件
/// - 包含 `pageTransitionsTheme` 启用更平滑的平台切换动画
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
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
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
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isAmoled ? const Color(0xFF0F0F0F) : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isAmoled
            ? const Color(0xFF0A0A0A)
            : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
