import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/providers/settings_provider.dart';

/// 应用偏好设置服务
///
/// 封装 `SharedPreferences`，提供类型安全的设置项读写。
/// 在 `main.dart` 中初始化并通过 Provider 注入。
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // ── 存储键 ──
  static const _themeModeKey = 'theme_mode';
  static const _seedColorKey = 'seed_color';
  static const _markdownAutoPreviewKey = 'markdown_auto_preview';
  static const _defaultPriorityKey = 'default_priority';
  static const _notesDensityKey = 'notes_density';
  static const _encryptedTokenKey = 'github_encrypted_token';
  static const _syncRepoOwnerKey = 'sync_repo_owner';
  static const _syncRepoNameKey = 'sync_repo_name';
  static const _localeCodeKey = 'locale_code';

  // ── 主题模式 ──

  /// 获取主题模式（默认跟随系统）
  AppThemeMode getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return AppThemeMode.fromStorageKey(value);
  }

  /// 设置主题模式
  Future<void> setThemeMode(AppThemeMode mode) {
    return _prefs.setString(_themeModeKey, mode.storageKey);
  }

  // ── 种子色 ──

  /// 获取种子色 ARGB 值（默认紫色 0xFF6750A4）
  int getSeedColor() {
    return _prefs.getInt(_seedColorKey) ?? 0xFF6750A4;
  }

  /// 设置种子色
  Future<void> setSeedColor(int argb) {
    return _prefs.setInt(_seedColorKey, argb);
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

  // ── 笔记列表密度 ──

  /// 获取笔记列表密度（默认 `comfortable`）
  ///
  /// 取值：`comfortable`（默认）、`compact`。
  /// 返回字符串以保持 PreferencesService 的简单类型边界。
  String getNotesDensity() {
    return _prefs.getString(_notesDensityKey) ?? 'comfortable';
  }

  /// 设置笔记列表密度
  Future<void> setNotesDensity(String density) {
    return _prefs.setString(_notesDensityKey, density);
  }

  // ── GitHub Token（加密存储）──

  /// 获取加密的 GitHub token
  String? getEncryptedToken() => _prefs.getString(_encryptedTokenKey);

  /// 设置加密的 GitHub token
  Future<void> setEncryptedToken(String encryptedToken) {
    return _prefs.setString(_encryptedTokenKey, encryptedToken);
  }

  /// 清除 GitHub token
  Future<void> clearToken() => _prefs.remove(_encryptedTokenKey);

  /// 判断是否已存储 token
  bool get hasToken => _prefs.containsKey(_encryptedTokenKey);

  // ── 同步仓库配置 ──

  /// 获取同步仓库 owner
  String? getSyncRepoOwner() => _prefs.getString(_syncRepoOwnerKey);

  /// 设置同步仓库 owner
  Future<void> setSyncRepoOwner(String owner) {
    return _prefs.setString(_syncRepoOwnerKey, owner);
  }

  /// 获取同步仓库名称
  String? getSyncRepoName() => _prefs.getString(_syncRepoNameKey);

  /// 设置同步仓库名称
  Future<void> setSyncRepoName(String name) {
    return _prefs.setString(_syncRepoNameKey, name);
  }

  /// 清除同步仓库配置
  Future<void> clearSyncConfig() async {
    await _prefs.remove(_syncRepoOwnerKey);
    await _prefs.remove(_syncRepoNameKey);
  }

  // ── 语言设置 ──

  /// 获取应用语言代码（null 表示跟随系统）
  String? getLocaleCode() => _prefs.getString(_localeCodeKey);

  /// 设置应用语言代码（传 null 表示跟随系统）
  Future<void> setLocaleCode(String? code) async {
    if (code == null) {
      await _prefs.remove(_localeCodeKey);
    } else {
      await _prefs.setString(_localeCodeKey, code);
    }
  }
}
