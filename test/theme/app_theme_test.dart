import 'package:flutter/material.dart';
import 'package:flutter_notes/core/theme/app_theme.dart';
import 'package:flutter_notes/features/settings/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppThemeMode', () {
    test('storageKey is human-readable lowercase', () {
      expect(AppThemeMode.light.storageKey, 'light');
      expect(AppThemeMode.dark.storageKey, 'dark');
      expect(AppThemeMode.amoled.storageKey, 'amoled');
      expect(AppThemeMode.system.storageKey, 'system');
    });

    test('fromStorageKey round-trips through storageKey', () {
      for (final mode in AppThemeMode.values) {
        expect(AppThemeMode.fromStorageKey(mode.storageKey), mode);
      }
    });

    test('fromStorageKey defaults to system on unknown / null', () {
      expect(AppThemeMode.fromStorageKey(null), AppThemeMode.system);
      expect(AppThemeMode.fromStorageKey(''), AppThemeMode.system);
      expect(AppThemeMode.fromStorageKey('nonsense'), AppThemeMode.system);
    });

    test('toMaterialThemeMode maps AMOLED to dark', () {
      expect(AppThemeMode.light.toMaterialThemeMode(), ThemeMode.light);
      expect(AppThemeMode.dark.toMaterialThemeMode(), ThemeMode.dark);
      expect(AppThemeMode.amoled.toMaterialThemeMode(), ThemeMode.dark);
      expect(AppThemeMode.system.toMaterialThemeMode(), ThemeMode.system);
    });

    test('isDark is true for dark / amoled / system', () {
      expect(AppThemeMode.light.isDark, isFalse);
      expect(AppThemeMode.dark.isDark, isTrue);
      expect(AppThemeMode.amoled.isDark, isTrue);
      expect(AppThemeMode.system.isDark, isTrue);
    });
  });

  group('AppTheme factory', () {
    test('light theme uses light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme uses dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('amoled theme uses dark brightness and pure black scaffold', () {
      final theme = AppTheme.amoled();
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(theme.useMaterial3, isTrue);
    });

    test('seed color propagates into ColorScheme.primary', () {
      const seed = Color(0xFF1565C0);
      final light = AppTheme.light(seedColor: seed);
      final dark = AppTheme.dark(seedColor: seed);
      final amoled = AppTheme.amoled(seedColor: seed);
      // 蓝色 seed 在三种主题下都应该生成一个蓝色系 primary
      final lightBlue = light.colorScheme.primary.toARGB32() & 0xFFFFFF;
      final darkBlue = dark.colorScheme.primary.toARGB32() & 0xFFFFFF;
      expect(lightBlue, isNot(equals(0)));
      expect(darkBlue, isNot(equals(0)));
      expect(amoled.scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('all themes configure snackBarTheme with floating behavior', () {
      expect(AppTheme.light().snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(AppTheme.dark().snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(AppTheme.amoled().snackBarTheme.behavior, SnackBarBehavior.floating);
    });

    test('all themes set page transitions theme', () {
      for (final theme in [
        AppTheme.light(),
        AppTheme.dark(),
        AppTheme.amoled(),
      ]) {
        expect(theme.pageTransitionsTheme, isNotNull);
        expect(theme.pageTransitionsTheme.builders, isNotEmpty);
      }
    });
  });
}
