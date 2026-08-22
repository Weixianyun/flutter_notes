import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note_model.dart';
import '../../../services/service_providers.dart';

/// 笔记列表密度
enum NotesDensity { comfortable, compact }

/// 主题模式（应用层）
///
/// 相比 Flutter 自带的 [ThemeMode]（仅 light/dark/system），
/// 这里显式加入 `amoled` 用于 OLED 设备的真黑背景。
enum AppThemeMode {
  light,
  dark,
  amoled,
  system;

  String get storageKey => switch (this) {
        AppThemeMode.light => 'light',
        AppThemeMode.dark => 'dark',
        AppThemeMode.amoled => 'amoled',
        AppThemeMode.system => 'system',
      };

  static AppThemeMode fromStorageKey(String? key) {
    return switch (key) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      'amoled' => AppThemeMode.amoled,
      _ => AppThemeMode.system,
    };
  }

  /// 映射到 Material 的 [ThemeMode]
  ///
  /// AMOLED 复用 dark 的色彩分支，但 [AppTheme] 会用 [AppTheme.amoled] 替换。
  ThemeMode toMaterialThemeMode() => switch (this) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark || AppThemeMode.amoled => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  /// 是否启用深色（dark 或 amoled 之一）
  bool get isDark =>
      this == AppThemeMode.dark ||
      this == AppThemeMode.amoled ||
      this == AppThemeMode.system;
}

/// 主题模式状态管理
///
/// 支持浅色、深色、AMOLED 真黑、跟随系统四种模式。
/// 通过 [PreferencesService] 持久化保存，应用启动时自动恢复。
class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.getThemeMode();
  }

  /// 设置主题模式并持久化
  void setMode(AppThemeMode mode) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setThemeMode(mode);
    state = mode;
  }
}

/// 主题模式 Provider
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, AppThemeMode>(ThemeModeNotifier.new);

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

/// Markdown 自动预览状态管理
///
/// 控制新建笔记是否默认进入预览模式。持久化到 SharedPreferences。
class MarkdownAutoPreviewNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.getMarkdownAutoPreview();
  }

  void setEnabled(bool value) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setMarkdownAutoPreview(value);
    state = value;
  }
}

/// Markdown 自动预览 Provider
final markdownAutoPreviewProvider =
    NotifierProvider<MarkdownAutoPreviewNotifier, bool>(
  MarkdownAutoPreviewNotifier.new,
);

/// 新建笔记默认优先级状态管理
///
/// 持久化 [NotePriority] 名称到 SharedPreferences，新建笔记时读取。
class DefaultPriorityNotifier extends Notifier<NotePriority> {
  @override
  NotePriority build() {
    final prefs = ref.read(preferencesServiceProvider);
    final name = prefs.getDefaultPriority();
    return NotePriority.values.firstWhere(
      (p) => p.name == name,
      orElse: () => NotePriority.medium,
    );
  }

  void setPriority(NotePriority priority) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setDefaultPriority(priority.name);
    state = priority;
  }
}

/// 新建笔记默认优先级 Provider
final defaultPriorityProvider =
    NotifierProvider<DefaultPriorityNotifier, NotePriority>(
  DefaultPriorityNotifier.new,
);

/// 笔记列表密度状态管理
///
/// 持久化到 SharedPreferences，列表页根据此值调整卡片内边距。
class NotesDensityNotifier extends Notifier<NotesDensity> {
  @override
  NotesDensity build() {
    final prefs = ref.read(preferencesServiceProvider);
    final value = prefs.getNotesDensity();
    return NotesDensity.values.firstWhere(
      (d) => d.name == value,
      orElse: () => NotesDensity.comfortable,
    );
  }

  void setDensity(NotesDensity density) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setNotesDensity(density.name);
    state = density;
  }
}

/// 笔记列表密度 Provider
final notesDensityProvider =
    NotifierProvider<NotesDensityNotifier, NotesDensity>(
  NotesDensityNotifier.new,
);

/// 加密状态 Provider（用于设置页展示）
final encryptionStatusProvider = Provider<bool>((ref) {
  final crypto = ref.watch(encryptionServiceProvider);
  return crypto.hasKey;
});

/// 应用版本号
const String appVersion = '0.1.0';

/// GitHub 仓库地址
const String githubRepoUrl = 'https://github.com/Weixianyun/flutter_notes';

/// 支持的本地化列表
const supportedLocales = <Locale>[
  Locale('en'),
  Locale('zh'),
];

/// 应用语言状态管理
///
/// null 表示跟随系统设置，否则为显式选择的语言代码。
class AppLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final prefs = ref.read(preferencesServiceProvider);
    final code = prefs.getLocaleCode();
    if (code == null) return null;
    return Locale(code);
  }

  /// 设置应用语言（null = 跟随系统）
  Future<void> setLocale(Locale? locale) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setLocaleCode(locale?.languageCode);
    state = locale;
  }
}

/// 应用语言 Provider
final appLocaleProvider =
    NotifierProvider<AppLocaleNotifier, Locale?>(AppLocaleNotifier.new);

