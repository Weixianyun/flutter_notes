import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crypto_service.dart';
import 'export_service.dart';
import 'github_service.dart';
import 'preferences_service.dart';
import 'sync_service.dart';

/// SharedPreferences 实例 Provider
///
/// 必须在 `main.dart` 中 override 为已初始化的实例。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider 必须在 main.dart 中 override');
});

/// 偏好设置服务 Provider
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

/// 加密服务 Provider
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(ref.watch(sharedPreferencesProvider));
});

/// GitHub 服务 Provider
final githubServiceProvider = Provider<GitHubService>((ref) {
  final crypto = ref.watch(encryptionServiceProvider);
  return GitHubService(crypto);
});

/// 解密后的 GitHub token Provider
///
/// 从 PreferencesService 读取加密 token 并解密。
/// 未登录时返回 null。
final githubTokenProvider = Provider<String?>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final crypto = ref.watch(encryptionServiceProvider);
  final encrypted = prefs.getEncryptedToken();
  if (encrypted == null) return null;
  try {
    return crypto.decrypt(encrypted);
  } catch (_) {
    return null;
  }
});

/// 同步服务 Provider
///
/// 依赖有效的 GitHub token，未登录时抛出异常。
final syncServiceProvider = Provider<SyncService?>((ref) {
  final token = ref.watch(githubTokenProvider);
  if (token == null) return null;
  final github = ref.watch(githubServiceProvider);
  return SyncService(github, token);
});

/// 导出服务 Provider
///
/// 复用 SyncService 的 noteToMarkdown/slugify 方法进行本地导出。
/// 不依赖 GitHub token。
final exportServiceProvider = Provider<ExportService>((ref) {
  final github = ref.watch(githubServiceProvider);
  final sync = SyncService(github, 'export-only');
  return ExportService(sync);
});
