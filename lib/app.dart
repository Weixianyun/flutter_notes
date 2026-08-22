import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/performance_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'services/performance_service.dart';
import 'services/service_providers.dart';

/// Flutter Notes 应用根组件
///
/// 集成 Material 3 主题系统（浅色 / 深色 / AMOLED 真黑 / 跟随系统四档）、
/// go_router 声明式路由以及 i18n 国际化（中英双语）。
/// 所有偏好通过 Riverpod Provider 注入。
///
/// 启动时间监控：[initState] 中通过 `addPostFrameCallback` 测量
/// 从进程启动到首帧绘制完成的总耗时，启用时记录到 [performanceMetricsProvider]。
class FlutterNotesApp extends ConsumerStatefulWidget {
  const FlutterNotesApp({super.key});

  @override
  ConsumerState<FlutterNotesApp> createState() => _FlutterNotesAppState();
}

class _FlutterNotesAppState extends ConsumerState<FlutterNotesApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordStartupIfEnabled();
    });
  }

  void _recordStartupIfEnabled() {
    final service = ref.read(performanceServiceProvider);
    if (!service.enabled) return;
    final startMs = PerformanceService.processStartMs;
    if (startMs == 0) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
    if (elapsed < 0 || elapsed > 60000) return;
    ref.read(performanceMetricsProvider.notifier).add(
          PerformanceMetric(
            kind: PerformanceMetricKind.startup,
            valueMs: elapsed.toDouble(),
            recordedAt: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final appThemeMode = ref.watch(themeModeProvider);
    final seedColor = ref.watch(seedColorProvider);
    final locale = ref.watch(appLocaleProvider);

    // 根据 AppThemeMode 决定 Material theme / darkTheme
    // - AMOLED 复用 dark 分支（与 Material 切换逻辑一致），但通过 builder 提供 AMOLED ThemeData
    // - light 显式指定
    // - system 让 MaterialApp 根据 platformBrightness 自行选择
    final light = AppTheme.light(seedColor: seedColor);
    final dark = appThemeMode == AppThemeMode.amoled
        ? AppTheme.amoled(seedColor: seedColor)
        : AppTheme.dark(seedColor: seedColor);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: appThemeMode.toMaterialThemeMode(),
      // 主题切换动画：AnimatedTheme 让 ThemeData 变更时所有依赖主题色的控件平滑过渡
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: child ?? const SizedBox.shrink(),
        );
      },
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
    );
  }
}
