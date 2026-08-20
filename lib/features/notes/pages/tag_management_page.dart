import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/tag_metadata_service.dart';
import '../providers/tags_provider.dart';

/// 标签管理页面
///
/// 列出所有标签（按使用频率降序），支持：
/// - 创建新标签（输入名称 + 选择颜色）
/// - 重命名标签
/// - 更改标签颜色
/// - 删除标签（从所有笔记中移除）
class TagsManagementPage extends ConsumerWidget {
  const TagsManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建标签',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有任何标签', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    '在笔记中添加标签后，可在此管理',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tags.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tag = tags[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: tag.color,
                  radius: 14,
                  child: const Icon(Icons.label, color: Colors.white, size: 14),
                ),
                title: Text('#${tag.name}'),
                subtitle: Text('${tag.count} 篇笔记'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _showRenameDialog(context, ref, tag.name);
                        break;
                      case 'color':
                        _showColorPicker(context, ref, tag.name, tag.color);
                        break;
                      case 'reset':
                        ref
                            .read(tagsManagerProvider.notifier)
                            .resetColor(tag.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已重置颜色')),
                        );
                        break;
                      case 'delete':
                        _showDeleteDialog(context, ref, tag.name, tag.count);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('重命名'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'color',
                      child: Row(
                        children: [
                          Icon(Icons.color_lens_outlined),
                          SizedBox(width: 8),
                          Text('更改颜色'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('重置颜色'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () => _showColorPicker(context, ref, tag.name, tag.color),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    Color selectedColor = TagMetadataService.presetColors.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新建标签'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '标签名称',
                      hintText: '例如：flutter',
                    ),
                    maxLength: 20,
                  ),
                  const SizedBox(height: 12),
                  const Text('选择颜色', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TagMetadataService.presetColors.map((color) {
                      final isSelected = color == selectedColor;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      if (name.isEmpty) return;
      try {
        await ref.read(tagsManagerProvider.notifier).createTag(
              name,
              color: selectedColor,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已创建标签「$name」')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String oldName,
  ) async {
    final nameController = TextEditingController(text: oldName);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名标签'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '新名称',
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重命名'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newName = nameController.text.trim();
      if (newName.isEmpty || newName == oldName) return;
      try {
        final count = await ref
            .read(tagsManagerProvider.notifier)
            .renameTag(oldName, newName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已重命名，影响 $count 篇笔记')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('重命名失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    String tagName,
    Color? currentColor,
  ) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) {
        Color selected = currentColor ?? TagMetadataService.presetColors.first;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('「$tagName」的颜色'),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TagMetadataService.presetColors.map((color) {
                  final isSelected = color == selected;
                  return GestureDetector(
                    onTap: () => setState(() => selected = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await ref.read(tagsManagerProvider.notifier).setColor(tagName, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已更新颜色')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String tagName,
    int noteCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签？'),
        content: Text(
          '将从 $noteCount 篇笔记中移除标签「$tagName」，此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await ref.read(tagsManagerProvider.notifier).deleteTag(tagName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除标签，影响 $count 篇笔记')),
        );
      }
    }
  }
}

/// 标签元数据服务（重新导出，方便在 UI 中引用预设颜色）
// TagMetadataService 由 services/tag_metadata_service.dart 提供

