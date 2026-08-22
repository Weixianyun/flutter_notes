import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/performance_service.dart';
import 'services/service_providers.dart';

void main() async {
  // 记录进程启动时刻（性能监控冷启动基准）
  PerformanceService.markProcessStart();

  // 确保 Flutter 绑定初始化（异步操作前置要求）
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FlutterNotesApp(),
    ),
  );
}
