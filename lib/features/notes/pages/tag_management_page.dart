import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final tagsAsync = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tagManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.tagCreateButton,
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.loadErrorTitle}: $error')),
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.label_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tagManagementEmptyTitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tagManagementEmptySubtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                subtitle: Text(l10n.tagCount(tag.count)),
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
                          SnackBar(content: Text(l10n.tagColorReset)),
                        );
                        break;
                      case 'delete':
                        _showDeleteDialog(context, ref, tag.name, tag.count);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined),
                          const SizedBox(width: 8),
                          Text(l10n.tagActionRename),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'color',
                      child: Row(
                        children: [
                          const Icon(Icons.color_lens_outlined),
                          const SizedBox(width: 8),
                          Text(l10n.tagActionChangeColor),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          const Icon(Icons.refresh),
                          const SizedBox(width: 8),
                          Text(l10n.tagActionResetColor),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            l10n.tagActionDelete,
                            style: const TextStyle(color: Colors.red),
                          ),
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
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    Color selectedColor = TagMetadataService.presetColors.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.tagCreateDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.tagNameLabel,
                      hintText: l10n.tagNameHint,
                    ),
                    maxLength: 20,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tagColorLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
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
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.tagActionCreate),
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
            SnackBar(content: Text(l10n.tagCreateSuccess(name))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.createFailed}: $e')),
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
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: oldName);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tagRenameDialogTitle),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.newName,
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tagActionRename),
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
            SnackBar(content: Text(l10n.tagRenameSuccess(count))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.renameFailed}: $e')),
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
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<Color>(
      context: context,
      builder: (context) {
        Color selected = currentColor ?? TagMetadataService.presetColors.first;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.tagColorDialogTitle(tagName)),
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
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(l10n.confirm),
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
          SnackBar(content: Text(l10n.tagColorUpdated)),
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tagDeleteDialogTitle),
        content: Text(l10n.tagDeleteConfirm(tagName, noteCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.tagActionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await ref.read(tagsManagerProvider.notifier).deleteTag(tagName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tagDeleteSuccess(count))),
        );
      }
    }
  }
}
