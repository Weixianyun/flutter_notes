import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/core/design/design_tokens.dart';

void main() {
  group('AppSpacing - 8 倍数阶梯', () {
    test('所有间距常量是正数且单调递增', () {
      const ladder = <double>[
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.huge,
      ];
      for (final v in ladder) {
        expect(v, greaterThan(0));
      }
      for (var i = 1; i < ladder.length; i++) {
        expect(ladder[i], greaterThan(ladder[i - 1]));
      }
    });

    test('标准档位符合 8dp 基准', () {
      expect(AppSpacing.xs, 8);
      expect(AppSpacing.sm, 12);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 20);
      expect(AppSpacing.xl, 24);
      expect(AppSpacing.xxl, 32);
    });

    test('xxs 是 xs 的一半，xxl 是 md 的两倍', () {
      expect(AppSpacing.xxs * 2, AppSpacing.xs);
      expect(AppSpacing.xxl, AppSpacing.md * 2);
    });
  });

  group('AppRadius - 圆角阶梯', () {
    test('所有圆角常量是正数且单调递增', () {
      const ladder = <double>[
        AppRadius.xs,
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
      ];
      for (final v in ladder) {
        expect(v, greaterThan(0));
      }
      for (var i = 1; i < ladder.length; i++) {
        expect(ladder[i], greaterThan(ladder[i - 1]));
      }
    });

    test('与 Material 3 默认值对齐：Card=12, FAB=16', () {
      expect(AppRadius.md, 12);
      expect(AppRadius.lg, 16);
    });

    test('BorderRadius 便捷访问器返回对应圆角', () {
      expect(AppRadius.allXs, const BorderRadius.all(Radius.circular(4)));
      expect(AppRadius.allSm, const BorderRadius.all(Radius.circular(8)));
      expect(AppRadius.allMd, const BorderRadius.all(Radius.circular(12)));
      expect(AppRadius.allLg, const BorderRadius.all(Radius.circular(16)));
      expect(AppRadius.allXl, const BorderRadius.all(Radius.circular(28)));
    });
  });

  group('AppDurations - 动画时长', () {
    test('三档时长满足 fast < medium < slow', () {
      expect(AppDurations.fast.inMilliseconds,
          lessThan(AppDurations.medium.inMilliseconds));
      expect(AppDurations.medium.inMilliseconds,
          lessThan(AppDurations.slow.inMilliseconds));
    });

    test('关键档位时长符合 Material 3 motion 建议', () {
      expect(AppDurations.fast, const Duration(milliseconds: 150));
      expect(AppDurations.medium, const Duration(milliseconds: 280));
      expect(AppDurations.slow, const Duration(milliseconds: 400));
    });

    test('stagger 档位大于 medium', () {
      expect(
        AppDurations.stagger.inMilliseconds,
        greaterThan(AppDurations.medium.inMilliseconds),
      );
    });
  });

  group('AppCurves - 动画曲线', () {
    test('三条曲线是合法 Curve 实例', () {
      expect(AppCurves.emphasized, isA<Curve>());
      expect(AppCurves.easeOut, isA<Curve>());
      expect(AppCurves.easeIn, isA<Curve>());
    });

    test('曲线在 t=0 与 t=1 处的值分别为 0 和 1', () {
      for (final c in <Curve>[AppCurves.emphasized, AppCurves.easeOut, AppCurves.easeIn]) {
        expect(c.transform(0.0), closeTo(0.0, 1e-9));
        expect(c.transform(1.0), closeTo(1.0, 1e-9));
      }
    });

    test('easeOut 在中段 t=0.5 处高于 easeIn（典型缓出 vs 缓入）', () {
      expect(
        AppCurves.easeOut.transform(0.5),
        greaterThan(AppCurves.easeIn.transform(0.5)),
      );
    });
  });

  group('AppLineHeights - 行高', () {
    test('行高单调递增：display < title < label < body', () {
      expect(AppLineHeights.display, lessThan(AppLineHeights.title));
      expect(AppLineHeights.title, lessThan(AppLineHeights.label));
      expect(AppLineHeights.label, lessThan(AppLineHeights.body));
    });

    test('行高落在可读区间 [1.0, 2.0]', () {
      for (final h in <double>[
        AppLineHeights.display,
        AppLineHeights.title,
        AppLineHeights.body,
        AppLineHeights.label,
      ]) {
        expect(h, greaterThanOrEqualTo(1.0));
        expect(h, lessThanOrEqualTo(2.0));
      }
    });
  });

  group('AppFontSizes - 字号阶梯', () {
    test('displayLarge > displayMedium > displaySmall', () {
      expect(AppFontSizes.displayLarge, greaterThan(AppFontSizes.displayMedium));
      expect(AppFontSizes.displayMedium, greaterThan(AppFontSizes.displaySmall));
    });

    test('titleLarge > titleMedium > titleSmall', () {
      expect(AppFontSizes.titleLarge, greaterThan(AppFontSizes.titleMedium));
      expect(AppFontSizes.titleMedium, greaterThan(AppFontSizes.titleSmall));
    });

    test('bodyLarge > bodyMedium > bodySmall', () {
      expect(AppFontSizes.bodyLarge, greaterThan(AppFontSizes.bodyMedium));
      expect(AppFontSizes.bodyMedium, greaterThan(AppFontSizes.bodySmall));
    });

    test('titleSmall 与 bodyLarge 关键值固定（14/16）', () {
      expect(AppFontSizes.titleSmall, 14);
      expect(AppFontSizes.bodyLarge, 16);
    });
  });

  group('withLineHeight - 行高叠加工具', () {
    test('叠加行高到既有 TextStyle', () {
      const base = TextStyle(fontSize: 16);
      final updated = withLineHeight(base, 1.5);
      expect(updated.fontSize, 16);
      expect(updated.height, 1.5);
    });

    test('原 TextStyle 不被修改（不可变）', () {
      const base = TextStyle(fontSize: 14);
      withLineHeight(base, 1.4);
      expect(base.height, isNull);
    });
  });
}
