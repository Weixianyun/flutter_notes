import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter Notes'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeLabel;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @seedColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed color'**
  String get seedColorLabel;

  /// No description provided for @syncSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get syncSection;

  /// No description provided for @githubSync.
  ///
  /// In en, this message translates to:
  /// **'GitHub Sync'**
  String get githubSync;

  /// No description provided for @githubSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync notes to a GitHub repository'**
  String get githubSyncSubtitle;

  /// No description provided for @encryptionSettings.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get encryptionSettings;

  /// No description provided for @encryptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'AES-256 encryption enabled'**
  String get encryptionEnabled;

  /// No description provided for @encryptionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Encryption not enabled'**
  String get encryptionDisabled;

  /// No description provided for @dataManagementSection.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get dataManagementSection;

  /// No description provided for @tagManagement.
  ///
  /// In en, this message translates to:
  /// **'Tag management'**
  String get tagManagement;

  /// No description provided for @tagManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, rename, delete and recolor tags'**
  String get tagManagementSubtitle;

  /// No description provided for @recycleBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get recycleBin;

  /// No description provided for @recycleBinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and restore deleted notes'**
  String get recycleBinSubtitle;

  /// No description provided for @exportNotes.
  ///
  /// In en, this message translates to:
  /// **'Export notes'**
  String get exportNotes;

  /// No description provided for @exportNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown files'**
  String get exportNotesSubtitle;

  /// No description provided for @importNotes.
  ///
  /// In en, this message translates to:
  /// **'Import notes'**
  String get importNotes;

  /// No description provided for @importNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Markdown files'**
  String get importNotesSubtitle;

  /// No description provided for @clearAllNotes.
  ///
  /// In en, this message translates to:
  /// **'Clear all notes'**
  String get clearAllNotes;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @githubRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub repository'**
  String get githubRepo;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageFollowSystem;

  /// No description provided for @tagCreateButton.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagCreateButton;

  /// No description provided for @tagCreateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get tagCreateDialogTitle;

  /// No description provided for @tagNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameLabel;

  /// No description provided for @tagNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. flutter'**
  String get tagNameHint;

  /// No description provided for @tagColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a color'**
  String get tagColorLabel;

  /// No description provided for @tagColorDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Color of \"{name}\"'**
  String tagColorDialogTitle(String name);

  /// No description provided for @tagActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tagActionCreate;

  /// No description provided for @tagActionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get tagActionRename;

  /// No description provided for @tagActionChangeColor.
  ///
  /// In en, this message translates to:
  /// **'Change color'**
  String get tagActionChangeColor;

  /// No description provided for @tagActionResetColor.
  ///
  /// In en, this message translates to:
  /// **'Reset color'**
  String get tagActionResetColor;

  /// No description provided for @tagActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tagActionDelete;

  /// No description provided for @tagRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get tagRenameDialogTitle;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newName;

  /// No description provided for @tagDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tag?'**
  String get tagDeleteDialogTitle;

  /// No description provided for @tagDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Will remove the tag \"{name}\" from {count} notes. This action cannot be undone.'**
  String tagDeleteConfirm(String name, int count);

  /// No description provided for @tagCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tag \"{name}\" created'**
  String tagCreateSuccess(String name);

  /// No description provided for @tagRenameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Renamed, affects {count} notes'**
  String tagRenameSuccess(int count);

  /// No description provided for @tagDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tag deleted, affects {count} notes'**
  String tagDeleteSuccess(int count);

  /// No description provided for @tagColorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Color updated'**
  String get tagColorUpdated;

  /// No description provided for @tagColorReset.
  ///
  /// In en, this message translates to:
  /// **'Color reset'**
  String get tagColorReset;

  /// No description provided for @tagCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No notes} =1{1 note} other{{count} notes}}'**
  String tagCount(int count);

  /// No description provided for @tagManagementEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagManagementEmptyTitle;

  /// No description provided for @tagManagementEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add tags to your notes, then manage them here'**
  String get tagManagementEmptySubtitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @createFailed.
  ///
  /// In en, this message translates to:
  /// **'Create failed'**
  String get createFailed;

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get renameFailed;

  /// No description provided for @sortUpdatedAtDesc.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get sortUpdatedAtDesc;

  /// No description provided for @sortCreatedAtDesc.
  ///
  /// In en, this message translates to:
  /// **'Newest created'**
  String get sortCreatedAtDesc;

  /// No description provided for @sortCreatedAtAsc.
  ///
  /// In en, this message translates to:
  /// **'Oldest created'**
  String get sortCreatedAtAsc;

  /// No description provided for @sortTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title A→Z'**
  String get sortTitleAsc;

  /// No description provided for @sortPriorityDesc.
  ///
  /// In en, this message translates to:
  /// **'Priority high→low'**
  String get sortPriorityDesc;

  /// No description provided for @sortMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortMenuTooltip;

  /// No description provided for @emptyNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get emptyNotesTitle;

  /// No description provided for @emptyNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to create your first note'**
  String get emptyNotesSubtitle;

  /// No description provided for @emptyNotesAction.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get emptyNotesAction;

  /// No description provided for @noFilteredNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching notes'**
  String get noFilteredNotesTitle;

  /// No description provided for @noFilteredNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No notes match the current tag filter'**
  String get noFilteredNotesSubtitle;

  /// No description provided for @noFilteredNotesAction.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get noFilteredNotesAction;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading failed'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get loadErrorAction;

  /// No description provided for @allTagsChip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTagsChip;

  /// No description provided for @selectedNotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String selectedNotesCount(int count);

  /// No description provided for @exitSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitSelectionTooltip;

  /// No description provided for @selectAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAllTooltip;

  /// No description provided for @exportSelectedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export selected'**
  String get exportSelectedTooltip;

  /// No description provided for @deleteSelectedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelectedTooltip;

  /// No description provided for @knowledgeGraphTooltip.
  ///
  /// In en, this message translates to:
  /// **'Knowledge graph'**
  String get knowledgeGraphTooltip;

  /// No description provided for @searchNotesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get searchNotesTooltip;

  /// No description provided for @moreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTooltip;

  /// No description provided for @deleteSelectedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected notes?'**
  String get deleteSelectedDialogTitle;

  /// No description provided for @deleteSelectedDialogContent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Will move 1 note to the recycle bin.} other{Will move {count} notes to the recycle bin.}}'**
  String deleteSelectedDialogContent(int count);

  /// No description provided for @movedToTrashCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 note to the recycle bin} other{Moved {count} notes to the recycle bin}}'**
  String movedToTrashCount(int count);

  /// No description provided for @movedNoteToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved \"{title}\" to the recycle bin'**
  String movedNoteToTrash(String title);

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @exportingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exportingInProgress;

  /// No description provided for @exportComplete.
  ///
  /// In en, this message translates to:
  /// **'Export complete'**
  String get exportComplete;

  /// No description provided for @exportSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Exported {success} of {total} notes'**
  String exportSuccessCount(int success, int total);

  /// No description provided for @exportFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String exportFailedCount(int count);

  /// No description provided for @exportPath.
  ///
  /// In en, this message translates to:
  /// **'Export path:'**
  String get exportPath;

  /// No description provided for @exportPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied to clipboard'**
  String get exportPathCopied;

  /// No description provided for @copyPathAction.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPathAction;

  /// No description provided for @doneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneAction;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @noNotesToExport.
  ///
  /// In en, this message translates to:
  /// **'No notes to export'**
  String get noNotesToExport;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'coming soon'**
  String get comingSoon;

  /// No description provided for @clearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all notes?'**
  String get clearAllConfirmTitle;

  /// No description provided for @clearAllConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All notes will be permanently deleted.'**
  String get clearAllConfirmContent;

  /// No description provided for @clearAllConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm clear'**
  String get clearAllConfirmAction;

  /// No description provided for @clearAllNotesSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notes cleared'**
  String get clearAllNotesSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
