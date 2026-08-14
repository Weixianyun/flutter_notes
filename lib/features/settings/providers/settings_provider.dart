import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式状态管理
///
/// 支持浅色、深色、跟随系统三种模式。
/// Week 2 接入 shared_preferences 后将持久化保存。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// 设置主题模式
  void setMode(ThemeMode mode) => state = mode;
}

/// 主题模式 Provider
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// 应用版本号
const String appVersion = '0.1.0';

/// GitHub 仓库地址
const String githubRepoUrl = 'https://github.com/Weixianyun/flutter_notes';
