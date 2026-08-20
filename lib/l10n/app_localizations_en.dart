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
}
