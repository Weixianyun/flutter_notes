import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 性能指标类型
enum PerformanceMetricKind { startup, scroll }

/// 单条性能记录
class PerformanceMetric {
  const PerformanceMetric({
    required this.kind,
    required this.valueMs,
    required this.recordedAt,
  });

  /// 指标类型
  final PerformanceMetricKind kind;

  /// 数值（启动时间：ms，滚动：平均帧耗时 ms）
  final double valueMs;

  /// 记录时间
  final DateTime recordedAt;

  /// 派生 FPS（仅滚动类型有），1 秒 / 平均帧耗时
  double? get fps {
    if (kind != PerformanceMetricKind.scroll) return null;
    if (valueMs <= 0) return null;
    return 1000.0 / valueMs;
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'value': valueMs,
        'at': recordedAt.toIso8601String(),
      };

  static PerformanceMetric? fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String?;
    final value = (json['value'] as num?)?.toDouble();
    final at = json['at'] as String?;
    if (kindName == null || value == null || at == null) return null;
    final kind = PerformanceMetricKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => PerformanceMetricKind.startup,
    );
    return PerformanceMetric(
      kind: kind,
      valueMs: value,
      recordedAt: DateTime.tryParse(at) ?? DateTime.now(),
    );
  }
}

/// 性能监控服务
///
/// 负责：
/// - 持久化「启用开关」到 SharedPreferences
/// - 持久化最近 N 条 [PerformanceMetric] 记录
/// - 提供冷启动时间点（[processStartTime] 来自 `PlatformDispatcher`）
///
/// 数据以 JSON 字符串存储，单 key 保存一个 List，体积小（每条约 80 字节）。
class PerformanceService {
  PerformanceService(this._prefs);

  final SharedPreferences _prefs;

  static const _enabledKey = 'performance_enabled';
  static const _metricsKey = 'performance_metrics';
  static const int _maxRecords = 20;

  /// 测试用：暴露最大记录数
  static int get maxRecordsForTest => _maxRecords;

  bool _enabled = true;

  /// 进程启动时间（毫秒）
  ///
  /// 由 `main()` 在 `WidgetsFlutterBinding.ensureInitialized()` 之前调用
  /// [markProcessStart] 写入。在首帧回调中可用 `DateTime.now() - processStartMs`
  /// 计算冷启动耗时。
  static int processStartMs = 0;

  /// 在 `main()` 入口处调用，记录进程启动时刻
  static void markProcessStart() {
    processStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// 是否启用性能采集
  bool get enabled {
    _enabled = _prefs.getBool(_enabledKey) ?? true;
    return _enabled;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(_enabledKey, value);
  }

  /// 当前所有性能记录（按时间倒序）
  List<PerformanceMetric> getMetrics() {
    final raw = _prefs.getString(_metricsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PerformanceMetric.fromJson)
          .whereType<PerformanceMetric>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 添加一条记录，保留最近 [_maxRecords] 条
  Future<void> addMetric(PerformanceMetric metric) async {
    if (!enabled) return;
    final list = getMetrics()..insert(0, metric);
    if (list.length > _maxRecords) {
      list.removeRange(_maxRecords, list.length);
    }
    final json = jsonEncode(list.map((m) => m.toJson()).toList());
    await _prefs.setString(_metricsKey, json);
  }

  /// 清除所有记录
  Future<void> clear() async {
    await _prefs.remove(_metricsKey);
  }
}
