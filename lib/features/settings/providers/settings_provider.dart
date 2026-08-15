import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/service_providers.dart';

/// 主题模式状态管理
///
/// 支持浅色、深色、跟随系统三种模式。
/// 通过 [PreferencesService] 持久化保存，应用启动时自动恢复。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.getThemeMode();
  }

  /// 设置主题模式并持久化
  void setMode(ThemeMode mode) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setThemeMode(mode);
    state = mode;
  }
}

/// 主题模式 Provider
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// 种子色状态管理
///
/// 用户可在设置中选择多种种子色，通过 [ColorScheme.fromSeed]
/// 动态生成完整色板。选择持久化到 SharedPreferences。
class SeedColorNotifier extends Notifier<Color> {
  @override
  Color build() {
    final prefs = ref.read(preferencesServiceProvider);
    return Color(prefs.getSeedColor());
  }

  /// 设置种子色并持久化
  void setColor(Color color) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setSeedColor(color.toARGB32());
    state = color;
  }
}

/// 种子色 Provider
final seedColorProvider =
    NotifierProvider<SeedColorNotifier, Color>(SeedColorNotifier.new);

/// 加密状态 Provider（用于设置页展示）
final encryptionStatusProvider = Provider<bool>((ref) {
  final crypto = ref.watch(encryptionServiceProvider);
  return crypto.hasKey;
});

/// 应用版本号
const String appVersion = '0.1.0';

/// GitHub 仓库地址
const String githubRepoUrl = 'https://github.com/Weixianyun/flutter_notes';
