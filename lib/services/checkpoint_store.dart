import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/sync_checkpoint.dart';

/// 同步断点持久化抽象
///
/// 与 [PreferencesService] 解耦，方便在测试中使用内存实现。
abstract class CheckpointStore {
  /// 读取当前持久化的 checkpoint（null 表示无断点）
  SyncCheckpoint? load();

  /// 写入 checkpoint
  Future<void> save(SyncCheckpoint checkpoint);

  /// 清除 checkpoint
  Future<void> clear();
}

/// 基于 [SharedPreferences] 的默认实现
class SharedPrefsCheckpointStore implements CheckpointStore {
  SharedPrefsCheckpointStore(this._prefs);

  static const _key = 'sync_checkpoint_v1';
  final SharedPreferences _prefs;

  @override
  SyncCheckpoint? load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return SyncCheckpoint.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(SyncCheckpoint checkpoint) {
    return _prefs.setString(_key, jsonEncode(checkpoint.toJsonMap()));
  }

  @override
  Future<void> clear() => _prefs.remove(_key);
}
