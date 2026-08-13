import 'package:uuid/uuid.dart';

/// 笔记优先级枚举
enum NotePriority { low, medium, high }

/// 笔记状态枚举
enum NoteStatus { draft, published, archived }

/// 笔记数据模型
///
/// 纯数据类，后续 Week 2 会接入 drift 数据库时
/// 会生成对应的表结构。当前阶段作为 UI 原型的假数据载体。
class NoteModel {
  NoteModel({
    required this.title,
    required this.content,
    String? id,
    this.priority = NotePriority.medium,
    this.status = NoteStatus.draft,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 构造（用于后续同步功能）
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      priority: NotePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotePriority.medium,
      ),
      status: NoteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NoteStatus.draft,
      ),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  final String id;
  final String title;
  final String content;
  final NotePriority priority;
  final NoteStatus status;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 内容摘要（取前 80 个字符）
  String get excerpt {
    final plain = content.replaceAll(RegExp(r'[#*`>\-\[\]]'), '').trim();
    return plain.length > 80 ? '${plain.substring(0, 80)}...' : plain;
  }

  /// 是否为空笔记
  bool get isEmpty => title.isEmpty && content.isEmpty;

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'priority': priority.name,
        'status': status.name,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 复制并修改部分字段
  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    NotePriority? priority,
    NoteStatus? status,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() =>
      'NoteModel(id: $id, title: $title, priority: $priority)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoteModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
