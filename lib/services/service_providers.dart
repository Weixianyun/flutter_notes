import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crypto_service.dart';
import 'preferences_service.dart';

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
