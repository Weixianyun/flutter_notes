import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 标签元数据（颜色）
class TagMetadata {
  const TagMetadata({required this.name, required this.color});

  final String name;
  final Color color;

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color.toARGB32(),
      };

  factory TagMetadata.fromJson(Map<String, dynamic> json) {
    return TagMetadata(
      name: json['name'] as String,
      color: Color(json['color'] as int),
    );
  }
}

/// 标签元数据服务
///
/// 管理标签的颜色配置，持久化到 SharedPreferences。
/// 颜色为标签的可选装饰属性，不影响笔记的核心数据。
class TagMetadataService {
  TagMetadataService(this._prefs);

  final SharedPreferences _prefs;

  static const _tagColorsKey = 'tag_colors';

  /// 8 种预设标签颜色（与主题色协调的柔和色系）
  static const List<Color> presetColors = [
    Color(0xFF6750A4), // 紫色（默认）
    Color(0xFF1976D2), // 蓝色
    Color(0xFF388E3C), // 绿色
    Color(0xFFE64A19), // 橙色
    Color(0xFFC2185B), // 粉色
    Color(0xFF0097A7), // 青色
    Color(0xFF455A64), // 靛蓝
    Color(0xFFD32F2F), // 红色
  ];

  /// 获取所有标签颜色配置
  Map<String, Color> getAllTagColors() {
    final raw = _prefs.getStringList(_tagColorsKey) ?? [];
    final result = <String, Color>{};
    for (final entry in raw) {
      try {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final name = parts[0];
          final argb = int.parse(parts[1]);
          result[name] = Color(argb);
        }
      } catch (_) {
        // 忽略格式错误的数据
      }
    }
    return result;
  }

  /// 获取指定标签的颜色（无配置则返回默认紫色）
  Color getTagColor(String tagName) {
    final colors = getAllTagColors();
    return colors[tagName] ?? presetColors[0];
  }

  /// 设置标签颜色
  Future<void> setTagColor(String tagName, Color color) {
    final colors = getAllTagColors();
    colors[tagName] = color;
    return _save(colors);
  }

  /// 删除标签颜色配置（恢复默认）
  Future<void> removeTagColor(String tagName) {
    final colors = getAllTagColors();
    colors.remove(tagName);
    return _save(colors);
  }

  /// 持久化颜色映射到 SharedPreferences
  Future<void> _save(Map<String, Color> colors) {
    final entries = colors.entries
        .map((e) => '${e.key}|${e.value.toARGB32()}')
        .toList();
    return _prefs.setStringList(_tagColorsKey, entries);
  }
}
