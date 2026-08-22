// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Notes';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get editorBehaviorSection => 'Editor';

  @override
  String get themeModeLabel => 'Theme mode';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'System';

  @override
  String get seedColorLabel => 'Seed color';

  @override
  String get syncSection => 'Cloud sync';

  @override
  String get githubSync => 'GitHub Sync';

  @override
  String get githubSyncSubtitle => 'Sync notes to a GitHub repository';

  @override
  String get encryptionSettings => 'Encryption';

  @override
  String get encryptionEnabled => 'AES-256 encryption enabled';

  @override
  String get encryptionDisabled => 'Encryption not enabled';

  @override
  String get dataManagementSection => 'Data management';

  @override
  String get tagManagement => 'Tag management';

  @override
  String get tagManagementSubtitle => 'Create, rename, delete and recolor tags';

  @override
  String get recycleBin => 'Recycle bin';

  @override
  String get recycleBinSubtitle => 'View and restore deleted notes';

  @override
  String get exportNotes => 'Export notes';

  @override
  String get exportNotesSubtitle => 'Export as Markdown files';

  @override
  String get importNotes => 'Import notes';

  @override
  String get importNotesSubtitle => 'Import from Markdown files';

  @override
  String get clearAllNotes => 'Clear all notes';

  @override
  String get aboutSection => 'About';

  @override
  String get version => 'Version';

  @override
  String get githubRepo => 'GitHub repository';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get languageSection => 'Language';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String get tagCreateButton => 'New tag';

  @override
  String get tagCreateDialogTitle => 'Create tag';

  @override
  String get tagNameLabel => 'Tag name';

  @override
  String get tagNameHint => 'e.g. flutter';

  @override
  String get tagColorLabel => 'Choose a color';

  @override
  String tagColorDialogTitle(String name) {
    return 'Color of \"$name\"';
  }

  @override
  String get tagActionCreate => 'Create';

  @override
  String get tagActionRename => 'Rename';

  @override
  String get tagActionChangeColor => 'Change color';

  @override
  String get tagActionResetColor => 'Reset color';

  @override
  String get tagActionDelete => 'Delete';

  @override
  String get tagRenameDialogTitle => 'Rename tag';

  @override
  String get newName => 'New name';

  @override
  String get tagDeleteDialogTitle => 'Delete tag?';

  @override
  String tagDeleteConfirm(String name, int count) {
    return 'Will remove the tag \"$name\" from $count notes. This action cannot be undone.';
  }

  @override
  String tagCreateSuccess(String name) {
    return 'Tag \"$name\" created';
  }

  @override
  String tagRenameSuccess(int count) {
    return 'Renamed, affects $count notes';
  }

  @override
  String tagDeleteSuccess(int count) {
    return 'Tag deleted, affects $count notes';
  }

  @override
  String get tagColorUpdated => 'Color updated';

  @override
  String get tagColorReset => 'Color reset';

  @override
  String tagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
      zero: 'No notes',
    );
    return '$_temp0';
  }

  @override
  String get tagManagementEmptyTitle => 'No tags yet';

  @override
  String get tagManagementEmptySubtitle =>
      'Add tags to your notes, then manage them here';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get createFailed => 'Create failed';

  @override
  String get renameFailed => 'Rename failed';

  @override
  String get sortUpdatedAtDesc => 'Recently updated';

  @override
  String get sortCreatedAtDesc => 'Newest created';

  @override
  String get sortCreatedAtAsc => 'Oldest created';

  @override
  String get sortTitleAsc => 'Title A→Z';

  @override
  String get sortPriorityDesc => 'Priority high→low';

  @override
  String get sortMenuTooltip => 'Sort by';

  @override
  String get emptyNotesTitle => 'No notes yet';

  @override
  String get emptyNotesSubtitle =>
      'Tap the button below to create your first note';

  @override
  String get emptyNotesAction => 'New note';

  @override
  String get noFilteredNotesTitle => 'No matching notes';

  @override
  String get noFilteredNotesSubtitle => 'No notes match the current tag filter';

  @override
  String get noFilteredNotesAction => 'Clear filter';

  @override
  String get loadErrorTitle => 'Loading failed';

  @override
  String get loadErrorAction => 'Retry';

  @override
  String get allTagsChip => 'All';

  @override
  String selectedNotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get exitSelectionTooltip => 'Exit';

  @override
  String get selectAllTooltip => 'Select all';

  @override
  String get exportSelectedTooltip => 'Export selected';

  @override
  String get deleteSelectedTooltip => 'Delete selected';

  @override
  String get knowledgeGraphTooltip => 'Knowledge graph';

  @override
  String get searchNotesTooltip => 'Search notes';

  @override
  String get moreTooltip => 'More';

  @override
  String get deleteSelectedDialogTitle => 'Delete selected notes?';

  @override
  String deleteSelectedDialogContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Will move $count notes to the recycle bin.',
      one: 'Will move 1 note to the recycle bin.',
    );
    return '$_temp0';
  }

  @override
  String movedToTrashCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count notes to the recycle bin',
      one: 'Moved 1 note to the recycle bin',
    );
    return '$_temp0';
  }

  @override
  String movedNoteToTrash(String title) {
    return 'Moved \"$title\" to the recycle bin';
  }

  @override
  String get undoAction => 'Undo';

  @override
  String get exportingInProgress => 'Exporting...';

  @override
  String get exportComplete => 'Export complete';

  @override
  String exportSuccessCount(int success, int total) {
    return 'Exported $success of $total notes';
  }

  @override
  String exportFailedCount(int count) {
    return '$count failed';
  }

  @override
  String get exportPath => 'Export path:';

  @override
  String get exportPathCopied => 'Path copied to clipboard';

  @override
  String get copyPathAction => 'Copy path';

  @override
  String get doneAction => 'Done';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get noNotesToExport => 'No notes to export';

  @override
  String get comingSoon => 'coming soon';

  @override
  String get clearAllConfirmTitle => 'Clear all notes?';

  @override
  String get clearAllConfirmContent =>
      'This action cannot be undone. All notes will be permanently deleted.';

  @override
  String get clearAllConfirmAction => 'Confirm clear';

  @override
  String get clearAllNotesSuccess => 'All notes cleared';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
      zero: 'No words',
    );
    return '$_temp0';
  }

  @override
  String charCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chars',
      one: '1 char',
      zero: 'No chars',
    );
    return '$_temp0';
  }

  @override
  String get autosaveIdle => 'Idle';

  @override
  String get autosaveSaving => 'Saving...';

  @override
  String autosaveSavedAt(String time) {
    return 'Saved at $time';
  }

  @override
  String get autosaveError => 'Autosave failed';

  @override
  String get editorTitleNew => 'New note';

  @override
  String get editorTitleEdit => 'Edit note';

  @override
  String get editTooltip => 'Edit';

  @override
  String get previewTooltip => 'Preview';

  @override
  String get exportTooltip => 'Export';

  @override
  String get saveAction => 'Save';

  @override
  String get markdownAutoPreview => 'Markdown auto preview';

  @override
  String get markdownAutoPreviewSubtitle => 'Open new notes in preview mode';

  @override
  String get defaultNewNotePriority => 'Default priority for new notes';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get listDensity => 'List density';

  @override
  String get listDensityComfortable => 'Comfortable';

  @override
  String get listDensityCompact => 'Compact';

  @override
  String get performanceSection => 'Performance';

  @override
  String get performanceTitle => 'Performance monitor';

  @override
  String get performanceSubtitle => 'View startup time and scroll FPS history';

  @override
  String get performanceEnabled => 'Enable performance monitoring';

  @override
  String get performanceEnabledSubtitle =>
      'Record cold-start time and scroll frame metrics';

  @override
  String get performanceStartup => 'Cold start time';

  @override
  String get performanceScroll => 'Scroll FPS';

  @override
  String get performanceNoData => 'No records yet';

  @override
  String performanceFpsLine(String fps, String avgMs) {
    return '$fps FPS ($avgMs ms/frame)';
  }

  @override
  String get performanceHint =>
      'Tip: open the app again or scroll the notes list to collect fresh samples.';

  @override
  String get performanceClear => 'Clear all records';
}
