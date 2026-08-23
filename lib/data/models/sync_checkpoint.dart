import 'dart:convert';

/// 同步方向
enum SyncDirection { push, pull, both }

/// 同步 checkpoint 阶段
///
/// 用于描述当前同步进行到的阶段，便于中断后恢复时知道从哪里继续。
enum SyncStage {
  /// 尚未开始
  idle,

  /// 拉取远程笔记列表
  pullingList,

  /// 拉取单条远程笔记内容
  pullingContent,

  /// 检测冲突
  detectingConflicts,

  /// 等待用户解决冲突
  awaitingResolution,

  /// 推送本地笔记
  pushing,

  /// 同步完成
  done,
}

/// 同步断点 checkpoint
///
/// 在每次同步过程中持久化当前进度，进程崩溃、网络中断或应用退出后
/// 可以基于 checkpoint 恢复同步，避免重新拉取 / 推送全部笔记。
///
/// 字段说明：
/// - [id] 唯一标识一个同步会话（每次启动新同步生成新 id）
/// - [direction] 本次同步的方向
/// - [stage] 当前阶段
/// - [lastSyncedAt] 进入本次同步时的基线时间
/// - [owner]/[repo] 同步目标仓库
/// - [pendingPushIds] 待推送的笔记 ID 列表（顺序敏感，未推送的排在前面）
/// - [pendingPullPaths] 待拉取的远程文件路径列表
/// - [pulledRemoteNotes] 已经拉取下来的远程笔记（按 ID 索引）
/// - [completedPushIds] 已经成功推送的笔记 ID 集合
/// - [completedPullPaths] 已经成功拉取的远程文件路径集合
/// - [updatedAt] checkpoint 自身的最近写入时间
class SyncCheckpoint {
  SyncCheckpoint({
    required this.id,
    required this.direction,
    required this.stage,
    required this.owner,
    required this.repo,
    required this.lastSyncedAt,
    required this.pendingPushIds,
    required this.pendingPullPaths,
    required this.pulledRemoteNotes,
    required this.completedPushIds,
    required this.completedPullPaths,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 唯一会话 ID（UUID 字符串）
  final String id;

  /// 本次同步方向
  final SyncDirection direction;

  /// 当前阶段
  final SyncStage stage;

  /// 仓库 owner
  final String owner;

  /// 仓库名称
  final String repo;

  /// 进入本次同步时的基线时间（用于增量判断）
  final DateTime lastSyncedAt;

  /// 待推送的笔记 ID 列表（顺序敏感）
  final List<String> pendingPushIds;

  /// 待拉取的远程文件路径列表
  final List<String> pendingPullPaths;

  /// 已拉取下来的远程笔记（按 ID 索引）
  final Map<String, Map<String, dynamic>> pulledRemoteNotes;

  /// 已成功推送的笔记 ID 集合
  final Set<String> completedPushIds;

  /// 已成功拉取的远程文件路径集合
  final Set<String> completedPullPaths;

  /// checkpoint 创建时间
  final DateTime createdAt;

  /// checkpoint 最近一次写入时间
  final DateTime updatedAt;

  /// 复制并修改指定字段
  SyncCheckpoint copyWith({
    SyncDirection? direction,
    SyncStage? stage,
    String? owner,
    String? repo,
    DateTime? lastSyncedAt,
    List<String>? pendingPushIds,
    List<String>? pendingPullPaths,
    Map<String, Map<String, dynamic>>? pulledRemoteNotes,
    Set<String>? completedPushIds,
    Set<String>? completedPullPaths,
    DateTime? updatedAt,
  }) {
    return SyncCheckpoint(
      id: id,
      direction: direction ?? this.direction,
      stage: stage ?? this.stage,
      owner: owner ?? this.owner,
      repo: repo ?? this.repo,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingPushIds: pendingPushIds ?? this.pendingPushIds,
      pendingPullPaths: pendingPullPaths ?? this.pendingPullPaths,
      pulledRemoteNotes: pulledRemoteNotes ?? this.pulledRemoteNotes,
      completedPushIds: completedPushIds ?? this.completedPushIds,
      completedPullPaths: completedPullPaths ?? this.completedPullPaths,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 转为 JSON 字符串
  String toJsonString() => jsonEncode(toJsonMap());

  /// 转为 JSON map
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'direction': direction.name,
      'stage': stage.name,
      'owner': owner,
      'repo': repo,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
      'pendingPushIds': pendingPushIds,
      'pendingPullPaths': pendingPullPaths,
      'pulledRemoteNotes': pulledRemoteNotes,
      'completedPushIds': completedPushIds.toList(),
      'completedPullPaths': completedPullPaths.toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从 JSON map 构造
  factory SyncCheckpoint.fromJsonMap(Map<String, dynamic> json) {
    return SyncCheckpoint(
      id: json['id'] as String,
      direction: SyncDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => SyncDirection.both,
      ),
      stage: SyncStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => SyncStage.idle,
      ),
      owner: json['owner'] as String? ?? '',
      repo: json['repo'] as String? ?? '',
      lastSyncedAt: DateTime.tryParse(json['lastSyncedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      pendingPushIds: (json['pendingPushIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      pendingPullPaths: (json['pendingPullPaths'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      pulledRemoteNotes: <String, Map<String, dynamic>>{
        for (final entry in (json['pulledRemoteNotes'] as Map<String, dynamic>? ?? {})
            .entries)
          entry.key: (entry.value as Map).cast<String, dynamic>(),
      },
      completedPushIds: ((json['completedPushIds'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toSet()),
      completedPullPaths: ((json['completedPullPaths'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toSet()),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// 从 JSON 字符串构造
  factory SyncCheckpoint.fromJsonString(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return SyncCheckpoint.fromJsonMap(map);
  }

  /// 当前是否还有未完成的工作
  bool get hasPendingWork =>
      pendingPushIds.isNotEmpty || pendingPullPaths.isNotEmpty;

  /// 整体进度（0.0 ~ 1.0）
  double get progress {
    final total = pendingPushIds.length +
        pendingPullPaths.length +
        completedPushIds.length +
        completedPullPaths.length;
    if (total == 0) return 1.0;
    final done = completedPushIds.length + completedPullPaths.length;
    return done / total;
  }
}
