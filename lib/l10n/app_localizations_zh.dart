// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flutter Notes';

  @override
  String get settingsTitle => '设置';

  @override
  String get appearanceSection => '外观';

  @override
  String get themeModeLabel => '主题模式';

  @override
  String get themeModeLight => '浅色模式';

  @override
  String get themeModeDark => '深色模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get seedColorLabel => '主题色';

  @override
  String get syncSection => '云同步';

  @override
  String get githubSync => 'GitHub 同步';

  @override
  String get githubSyncSubtitle => '将笔记同步到 GitHub 仓库';

  @override
  String get encryptionSettings => '加密设置';

  @override
  String get encryptionEnabled => 'AES-256 加密已启用';

  @override
  String get encryptionDisabled => '加密未启用';

  @override
  String get dataManagementSection => '数据管理';

  @override
  String get tagManagement => '标签管理';

  @override
  String get tagManagementSubtitle => '创建、重命名、删除和调整标签颜色';

  @override
  String get recycleBin => '回收站';

  @override
  String get recycleBinSubtitle => '查看和恢复已删除的笔记';

  @override
  String get exportNotes => '导出笔记';

  @override
  String get exportNotesSubtitle => '导出为 Markdown 文件';

  @override
  String get importNotes => '导入笔记';

  @override
  String get importNotesSubtitle => '从 Markdown 文件导入';

  @override
  String get clearAllNotes => '清空所有笔记';

  @override
  String get aboutSection => '关于';

  @override
  String get version => '版本';

  @override
  String get githubRepo => 'GitHub 仓库';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get languageSection => '语言';

  @override
  String get languageLabel => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String get tagCreateButton => '新建标签';

  @override
  String get tagCreateDialogTitle => '新建标签';

  @override
  String get tagNameLabel => '标签名称';

  @override
  String get tagNameHint => '例如：flutter';

  @override
  String get tagColorLabel => '选择颜色';

  @override
  String tagColorDialogTitle(String name) {
    return '「$name」的颜色';
  }

  @override
  String get tagActionCreate => '创建';

  @override
  String get tagActionRename => '重命名';

  @override
  String get tagActionChangeColor => '更改颜色';

  @override
  String get tagActionResetColor => '重置颜色';

  @override
  String get tagActionDelete => '删除';

  @override
  String get tagRenameDialogTitle => '重命名标签';

  @override
  String get newName => '新名称';

  @override
  String get tagDeleteDialogTitle => '删除标签？';

  @override
  String tagDeleteConfirm(String name, int count) {
    return '将从 $count 篇笔记中移除标签「$name」，此操作不可撤销。';
  }

  @override
  String tagCreateSuccess(String name) {
    return '已创建标签「$name」';
  }

  @override
  String tagRenameSuccess(int count) {
    return '已重命名，影响 $count 篇笔记';
  }

  @override
  String tagDeleteSuccess(int count) {
    return '已删除标签，影响 $count 篇笔记';
  }

  @override
  String get tagColorUpdated => '已更新颜色';

  @override
  String get tagColorReset => '已重置颜色';

  @override
  String tagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 篇笔记',
    );
    return '$_temp0';
  }

  @override
  String get tagManagementEmptyTitle => '还没有任何标签';

  @override
  String get tagManagementEmptySubtitle => '在笔记中添加标签后，可在此管理';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get createFailed => '创建失败';

  @override
  String get renameFailed => '重命名失败';

  @override
  String get sortUpdatedAtDesc => '最近修改';

  @override
  String get sortCreatedAtDesc => '最新创建';

  @override
  String get sortCreatedAtAsc => '最早创建';

  @override
  String get sortTitleAsc => '标题 A→Z';

  @override
  String get sortPriorityDesc => '优先级高→低';

  @override
  String get sortMenuTooltip => '排序方式';

  @override
  String get emptyNotesTitle => '还没有任何笔记';

  @override
  String get emptyNotesSubtitle => '点击右下角按钮创建你的第一条笔记';

  @override
  String get emptyNotesAction => '新建笔记';

  @override
  String get noFilteredNotesTitle => '没有匹配的笔记';

  @override
  String get noFilteredNotesSubtitle => '当前标签筛选下没有笔记，试试其他标签';

  @override
  String get noFilteredNotesAction => '清除筛选';

  @override
  String get loadErrorTitle => '加载失败';

  @override
  String get loadErrorAction => '重试';

  @override
  String get allTagsChip => '全部';

  @override
  String selectedNotesCount(int count) {
    return '已选 $count 篇';
  }

  @override
  String get exitSelectionTooltip => '退出';

  @override
  String get selectAllTooltip => '全选';

  @override
  String get exportSelectedTooltip => '导出选中';

  @override
  String get deleteSelectedTooltip => '删除选中';

  @override
  String get knowledgeGraphTooltip => '知识图谱';

  @override
  String get searchNotesTooltip => '搜索笔记';

  @override
  String get moreTooltip => '更多';

  @override
  String get deleteSelectedDialogTitle => '删除选中的笔记？';

  @override
  String deleteSelectedDialogContent(int count) {
    return '将移入回收站 $count 篇笔记。';
  }

  @override
  String movedToTrashCount(int count) {
    return '已移入回收站 $count 篇笔记';
  }

  @override
  String movedNoteToTrash(String title) {
    return '已移入回收站「$title」';
  }

  @override
  String get undoAction => '撤销';

  @override
  String get exportingInProgress => '正在导出...';

  @override
  String get exportComplete => '导出完成';

  @override
  String exportSuccessCount(int success, int total) {
    return '成功导出 $success/$total 篇笔记';
  }

  @override
  String exportFailedCount(int count) {
    return '失败 $count 篇';
  }

  @override
  String get exportPath => '导出路径：';

  @override
  String get exportPathCopied => '路径已复制到剪贴板';

  @override
  String get copyPathAction => '复制路径';

  @override
  String get doneAction => '完成';

  @override
  String exportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String get noNotesToExport => '没有笔记可导出';

  @override
  String get comingSoon => '即将推出';

  @override
  String get clearAllConfirmTitle => '清空所有笔记？';

  @override
  String get clearAllConfirmContent => '此操作不可撤销，所有笔记将被永久删除。';

  @override
  String get clearAllConfirmAction => '确认清空';

  @override
  String get clearAllNotesSuccess => '已清空所有笔记';
}
