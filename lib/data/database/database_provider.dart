import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// 应用数据库 Provider（单例）
///
/// 全局共享同一个 [AppDatabase] 实例，确保数据库连接复用。
/// 测试时可通过 override 替换为内存数据库。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
