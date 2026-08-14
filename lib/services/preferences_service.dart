import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用偏好设置服务
///
/// 封装 `SharedPreferences`，提供类型安全的设置项读写。
/// 在 `main.dart` 中初始化并通过 Provider 注入。
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // ── 存储键 ──
  static const _themeModeKey = 'theme_mode';
  static const _markdownAutoPreviewKey = 'markdown_auto_preview';
  static const _defaultPriorityKey = 'default_priority';

  // ── 主题模式 ──

  /// 获取主题模式（默认跟随系统）
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) {
    return _prefs.setString(_themeModeKey, mode.name);
  }

  // ── Markdown 自动预览 ──

  /// 是否开启 Markdown 自动预览（默认开启）
  bool getMarkdownAutoPreview() {
    return _prefs.getBool(_markdownAutoPreviewKey) ?? true;
  }

  /// 设置 Markdown 自动预览
  Future<void> setMarkdownAutoPreview(bool value) {
    return _prefs.setBool(_markdownAutoPreviewKey, value);
  }

  // ── 默认优先级 ──

  /// 获取默认笔记优先级（默认 medium）
  String getDefaultPriority() {
    return _prefs.getString(_defaultPriorityKey) ?? 'medium';
  }

  /// 设置默认笔记优先级
  Future<void> setDefaultPriority(String priority) {
    return _prefs.setString(_defaultPriorityKey, priority);
  }
}
