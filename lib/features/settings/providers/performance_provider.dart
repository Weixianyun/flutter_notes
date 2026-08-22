import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/performance_service.dart';
import '../../../services/service_providers.dart';

/// 性能监控开关 Notifier
class PerformanceEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(performanceServiceProvider).enabled;
  }

  Future<void> setEnabled(bool value) async {
    await ref.read(performanceServiceProvider).setEnabled(value);
    state = value;
  }
}

final performanceEnabledProvider =
    NotifierProvider<PerformanceEnabledNotifier, bool>(
  PerformanceEnabledNotifier.new,
);

/// 性能指标列表 Notifier
///
/// 任何写入操作（采集新指标 / 清空 / 切换开关）后通过 `refresh()` 重新加载。
class PerformanceMetricsNotifier extends Notifier<List<PerformanceMetric>> {
  @override
  List<PerformanceMetric> build() {
    return ref.read(performanceServiceProvider).getMetrics();
  }

  /// 重新从 SharedPreferences 加载
  void refresh() {
    state = ref.read(performanceServiceProvider).getMetrics();
  }

  /// 添加一条记录
  Future<void> add(PerformanceMetric metric) async {
    await ref.read(performanceServiceProvider).addMetric(metric);
    refresh();
  }

  /// 清除所有记录
  Future<void> clear() async {
    await ref.read(performanceServiceProvider).clear();
    state = const [];
  }
}

final performanceMetricsProvider =
    NotifierProvider<PerformanceMetricsNotifier, List<PerformanceMetric>>(
  PerformanceMetricsNotifier.new,
);
