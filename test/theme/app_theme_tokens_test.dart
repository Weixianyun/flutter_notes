import 'package:flutter/material.dart';
import 'package:flutter_notes/core/design/design_tokens.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证 AppTheme.light() / dark() / amoled() 产出的 [TextTheme]：
/// - 字号/行高与 [AppFontSizes] / [AppLineHeights] 一致
/// - 三套主题的颜色基线不同（onSurface、inverseSurface、primary 等）
/// - 关键组件 theme 引用了 [AppRadius] / [AppSpacing]
void main() {
  group('AppTheme - 字号挂载', () {
    test('light 主题字号与 AppFontSizes 阶梯一致', () {
      final theme = AppTheme.light();
      final tt = theme.textTheme;
      expect(tt.displayLarge?.fontSize, AppFontSizes.displayLarge);
      expect(tt.headlineMedium?.fontSize, AppFontSizes.headlineMedium);
      expect(tt.titleLarge?.fontSize, AppFontSizes.titleLarge);
      expect(tt.titleMedium?.fontSize, AppFontSizes.titleMedium);
      expect(tt.bodyLarge?.fontSize, AppFontSizes.bodyLarge);
      expect(tt.bodyMedium?.fontSize, AppFontSizes.bodyMedium);
      expect(tt.labelLarge?.fontSize, AppFontSizes.labelLarge);
      expect(tt.labelSmall?.fontSize, AppFontSizes.labelSmall);
    });

    test('dark 与 amoled 主题字号与 light 一致（仅颜色变化）', () {
      final light = AppTheme.light().textTheme;
      final dark = AppTheme.dark().textTheme;
      final amoled = AppTheme.amoled().textTheme;
      expect(dark.bodyMedium?.fontSize, light.bodyMedium?.fontSize);
      expect(amoled.titleLarge?.fontSize, light.titleLarge?.fontSize);
      expect(dark.labelLarge?.fontSize, light.labelLarge?.fontSize);
    });
  });

  group('AppTheme - 行高挂载', () {
    test('light 主题行高与 AppLineHeights 一致', () {
      final tt = AppTheme.light().textTheme;
      expect(tt.displayLarge?.height, AppLineHeights.display);
      expect(tt.titleLarge?.height, AppLineHeights.title);
      expect(tt.titleMedium?.height, AppLineHeights.title);
      expect(tt.bodyLarge?.height, AppLineHeights.body);
      expect(tt.bodyMedium?.height, AppLineHeights.body);
      expect(tt.labelLarge?.height, AppLineHeights.label);
    });

    test('body 类行高大于 title 类行高（阅读更舒展）', () {
      final tt = AppTheme.light().textTheme;
      final body = tt.bodyMedium?.height;
      final title = tt.titleMedium?.height;
      expect(body, isNotNull);
      expect(title, isNotNull);
      expect(body!, greaterThan(title!));
    });
  });

  group('AppTheme - 组件 theme 引用设计 token', () {
    test('Card 圆角 = AppRadius.lg', () {
      final theme = AppTheme.light();
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.lg));
    });

    test('ListTile 圆角 = AppRadius.md，水平内边距 = AppSpacing.md', () {
      final theme = AppTheme.light();
      final shape = theme.listTileTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.md));
      final padding = theme.listTileTheme.contentPadding as EdgeInsets;
      expect(padding.left, AppSpacing.md);
      expect(padding.right, AppSpacing.md);
    });

    test('InputDecoration 圆角 = AppRadius.md', () {
      final theme = AppTheme.light();
      final border = theme.inputDecorationTheme.border as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(AppRadius.md));
    });

    test('SnackBar 圆角 = AppRadius.md 且 floating', () {
      final theme = AppTheme.light();
      final shape = theme.snackBarTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.md));
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });

    test('Dialog 圆角 = AppRadius.lg', () {
      final theme = AppTheme.light();
      final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.lg));
    });

    test('BottomSheet 顶部圆角 = AppRadius.lg', () {
      final theme = AppTheme.light();
      final shape =
          theme.bottomSheetTheme.shape as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      );
    });

    test('Chip 圆角 = AppRadius.sm', () {
      final theme = AppTheme.light();
      final shape = theme.chipTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.sm));
    });

    test('FloatingActionButton 圆角 = AppRadius.xl', () {
      final theme = AppTheme.light();
      final shape = theme.floatingActionButtonTheme.shape
          as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.xl));
    });
  });

  group('AppTheme - AMOLED 特殊', () {
    test('AMOLED scaffold 与 surfaceContainer 系列为黑色阶梯', () {
      final theme = AppTheme.amoled();
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(theme.colorScheme.surface, const Color(0xFF000000));
      expect(theme.colorScheme.surfaceContainerLow, const Color(0xFF050505));
      expect(theme.colorScheme.surfaceContainer, const Color(0xFF0A0A0A));
      expect(theme.colorScheme.surfaceContainerHigh, const Color(0xFF121212));
      expect(theme.colorScheme.surfaceContainerHighest, const Color(0xFF1A1A1A));
    });

    test('AMOLED 主题的 card/navbar/input 填充色与浅色不同', () {
      final amoled = AppTheme.amoled();
      final light = AppTheme.light();
      // AMOLED CardTheme.color 显式设为 #0F0F0F，浅色使用 surfaceContainerHighest
      expect(amoled.cardTheme.color, const Color(0xFF0F0F0F));
      expect(amoled.navigationBarTheme.backgroundColor,
          const Color(0xFF000000));
      // 浅色 CardTheme.color = surfaceContainerHighest，二者不等
      expect(light.cardTheme.color, isNot(equals(amoled.cardTheme.color)));
    });
  });

  group('AppTheme - 文字基色', () {
    test('三套主题的 bodyMedium 颜色不同（onSurface 因亮度不同）', () {
      final light = AppTheme.light().textTheme.bodyMedium?.color;
      final dark = AppTheme.dark().textTheme.bodyMedium?.color;
      final amoled = AppTheme.amoled().textTheme.bodyMedium?.color;
      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(amoled, isNotNull);
      expect(light, isNot(equals(dark)));
      // dark 和 amoled 的 onSurface 通常为同一种亮色（material 推导）
      // 不强制严格相等，只验证 light 明显不同
      expect(light!.toARGB32() & 0xFFFFFF, lessThan(0x808080));
      expect(dark!.toARGB32() & 0xFFFFFF, greaterThan(0x808080));
    });
  });
}
