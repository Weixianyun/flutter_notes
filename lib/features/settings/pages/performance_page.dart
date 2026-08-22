import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/performance_service.dart';
import '../providers/performance_provider.dart';

/// 性能监控页面
///
/// 展示：
/// - 启用开关
/// - 最近 20 条性能记录（启动时间 / 滚动 FPS），按类型分组
/// - 清除全部记录
class PerformancePage extends ConsumerWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(performanceEnabledProvider);
    final metrics = ref.watch(performanceMetricsProvider);
    final theme = Theme.of(context);

    final startups =
        metrics.where((m) => m.kind == PerformanceMetricKind.startup).toList();
    final scrolls =
        metrics.where((m) => m.kind == PerformanceMetricKind.scroll).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.performanceSection),
        actions: [
          IconButton(
            tooltip: l10n.performanceClear,
            icon: const Icon(Icons.delete_outline),
            onPressed: metrics.isEmpty
                ? null
                : () => ref.read(performanceMetricsProvider.notifier).clear(),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── 启用开关 ──
          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: Text(l10n.performanceEnabled),
            subtitle: Text(l10n.performanceEnabledSubtitle),
            value: enabled,
            onChanged: (v) =>
                ref.read(performanceEnabledProvider.notifier).setEnabled(v),
          ),
          const Divider(height: AppSpacing.xxl),

          // ── 冷启动记录 ──
          _SectionHeader(title: l10n.performanceStartup),
          if (startups.isEmpty)
            _EmptyHint(text: l10n.performanceNoData)
          else
            ...startups.map((m) => _StartupTile(metric: m, l10n: l10n)),

          const Divider(height: AppSpacing.xxl),

          // ── 滚动 FPS 记录 ──
          _SectionHeader(title: l10n.performanceScroll),
          if (scrolls.isEmpty)
            _EmptyHint(text: l10n.performanceNoData)
          else
            ...scrolls.map((m) => _ScrollTile(metric: m, l10n: l10n)),

          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.performanceHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _StartupTile extends StatelessWidget {
  const _StartupTile({required this.metric, required this.l10n});

  final PerformanceMetric metric;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = _performanceColor(metric.valueMs, thresholds: const [1500, 3000]);
    return ListTile(
      leading: Icon(Icons.rocket_launch_outlined, color: color),
      title: Text('${metric.valueMs.toStringAsFixed(0)} ms'),
      subtitle: Text(_formatTime(metric.recordedAt)),
    );
  }
}

class _ScrollTile extends StatelessWidget {
  const _ScrollTile({required this.metric, required this.l10n});

  final PerformanceMetric metric;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final fps = metric.fps ?? 0;
    final color = _performanceColor(metric.valueMs, thresholds: const [16.7, 33.3]);
    return ListTile(
      leading: Icon(Icons.swap_vert_outlined, color: color),
      title: Text(
        l10n.performanceFpsLine(fps.toStringAsFixed(1), metric.valueMs.toStringAsFixed(1)),
      ),
      subtitle: Text(_formatTime(metric.recordedAt)),
    );
  }
}

/// 根据耗时返回性能等级颜色
///
/// `thresholds[0]` = 优秀线（绿色），`thresholds[1]` = 警戒线（橙色），超过 = 红色
Color _performanceColor(double valueMs, {required List<double> thresholds}) {
  if (valueMs <= thresholds[0]) return Colors.green;
  if (valueMs <= thresholds[1]) return Colors.orange;
  return Colors.red;
}

String _formatTime(DateTime t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  final ss = t.second.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}
