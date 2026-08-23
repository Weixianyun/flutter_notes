import 'package:flutter/material.dart';

import '../services/backlink_index.dart';
import 'backlinks_panel.dart';
import 'outline_panel.dart';

/// 编辑器侧栏聚合面板
///
/// 同时承载：
/// - [OutlinePanel]：从当前笔记正文解析 heading 列表
/// - [BacklinksPanel]：通过 [BacklinkIndex] 反查引用了当前笔记的笔记
///
/// 通过顶部的 [TabBar] 切换；空状态由各子组件自行处理。
class EditorSidebar extends StatelessWidget {
  const EditorSidebar({
    super.key,
    required this.content,
    required this.targetTitle,
    required this.index,
    this.onJumpToOffset,
    this.onOpenSource,
  });

  /// 当前笔记正文（用于生成 outline）
  final String content;

  /// 当前笔记标题（用于反查 backlinks）
  final String targetTitle;

  /// 全局反向链接索引
  final BacklinkIndex index;

  /// 点击 outline 节点跳转
  final void Function(int offset)? onJumpToOffset;

  /// 点击 backlink 跳转到源笔记
  final void Function(BacklinkEntry entry)? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            left: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: colorScheme.surfaceContainerLow,
              child: TabBar(
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge,
                tabs: const [
                  Tab(icon: Icon(Icons.toc, size: 16), text: '大纲'),
                  Tab(icon: Icon(Icons.link, size: 16), text: '反向'),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 280,
              child: TabBarView(
                children: [
                  OutlinePanel(
                    content: content,
                    onJumpToOffset: onJumpToOffset,
                  ),
                  BacklinksPanel(
                    targetTitle: targetTitle,
                    index: index,
                    onOpenSource: onOpenSource,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
