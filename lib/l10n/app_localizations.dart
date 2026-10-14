import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('id')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Novellie'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navNovels.
  ///
  /// In en, this message translates to:
  /// **'Novels'**
  String get navNovels;

  /// No description provided for @navPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get navPlanning;

  /// No description provided for @navTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// No description provided for @navAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get navAi;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'Misc'**
  String get navMore;

  /// No description provided for @createNovel.
  ///
  /// In en, this message translates to:
  /// **'Create Novel'**
  String get createNovel;

  /// No description provided for @createFirstNovel.
  ///
  /// In en, this message translates to:
  /// **'Create your first novel'**
  String get createFirstNovel;

  /// No description provided for @importDraft.
  ///
  /// In en, this message translates to:
  /// **'Import draft'**
  String get importDraft;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @savedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Saved just now'**
  String get savedJustNow;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @notSavedRetrying.
  ///
  /// In en, this message translates to:
  /// **'Not saved — retrying'**
  String get notSavedRetrying;

  /// No description provided for @emptyActiveNovelTitle.
  ///
  /// In en, this message translates to:
  /// **'No active novel'**
  String get emptyActiveNovelTitle;

  /// No description provided for @emptyActiveNovelBody.
  ///
  /// In en, this message translates to:
  /// **'Create a novel or open one from your library to start writing.'**
  String get emptyActiveNovelBody;

  /// No description provided for @emptyActiveNovelAction.
  ///
  /// In en, this message translates to:
  /// **'Create novel'**
  String get emptyActiveNovelAction;

  /// No description provided for @emptyRecentNovelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your novels will appear here'**
  String get emptyRecentNovelsTitle;

  /// No description provided for @emptyRecentNovelsBody.
  ///
  /// In en, this message translates to:
  /// **'Recently opened novels show up as soon as you create one.'**
  String get emptyRecentNovelsBody;

  /// No description provided for @emptyRecentNovelsAction.
  ///
  /// In en, this message translates to:
  /// **'Create a novel'**
  String get emptyRecentNovelsAction;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'No novels yet'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Create a novel or import a draft to start writing.'**
  String get emptyLibraryBody;

  /// No description provided for @emptyLibraryAction.
  ///
  /// In en, this message translates to:
  /// **'Create novel'**
  String get emptyLibraryAction;

  /// No description provided for @emptyWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'No chapters yet'**
  String get emptyWorkspaceTitle;

  /// No description provided for @emptyWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'Structure your novel into volumes, arcs, and chapters.'**
  String get emptyWorkspaceBody;

  /// No description provided for @emptyWorkspaceAction.
  ///
  /// In en, this message translates to:
  /// **'Add chapter 1'**
  String get emptyWorkspaceAction;

  /// No description provided for @emptyEditorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Start writing…'**
  String get emptyEditorPlaceholder;

  /// No description provided for @emptyVersionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No snapshots yet'**
  String get emptyVersionHistoryTitle;

  /// No description provided for @emptyVersionHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Snapshots are created while you write and before any restore or AI replace.'**
  String get emptyVersionHistoryBody;

  /// No description provided for @emptyVersionHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Create snapshot'**
  String get emptyVersionHistoryAction;

  /// No description provided for @emptyVersionCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to compare'**
  String get emptyVersionCompareTitle;

  /// No description provided for @emptyVersionCompareBody.
  ///
  /// In en, this message translates to:
  /// **'Choose two versions to see what changed.'**
  String get emptyVersionCompareBody;

  /// No description provided for @emptyVersionCompareAction.
  ///
  /// In en, this message translates to:
  /// **'Choose versions'**
  String get emptyVersionCompareAction;

  /// No description provided for @emptySceneCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'No scene cards yet'**
  String get emptySceneCardsTitle;

  /// No description provided for @emptySceneCardsBody.
  ///
  /// In en, this message translates to:
  /// **'Outline your story scene by scene with a goal, conflict, point of view, and outcome.'**
  String get emptySceneCardsBody;

  /// No description provided for @emptySceneCardsAction.
  ///
  /// In en, this message translates to:
  /// **'Add scene card'**
  String get emptySceneCardsAction;

  /// No description provided for @emptyOutlineTitle.
  ///
  /// In en, this message translates to:
  /// **'No outline yet'**
  String get emptyOutlineTitle;

  /// No description provided for @emptyOutlineBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a structure to add its beats, or start from a blank outline.'**
  String get emptyOutlineBody;

  /// No description provided for @emptyOutlineAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a structure'**
  String get emptyOutlineAction;

  /// No description provided for @emptyTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get emptyTimelineTitle;

  /// No description provided for @emptyTimelineBody.
  ///
  /// In en, this message translates to:
  /// **'Record what happens and when, then link events to characters, places, and chapters.'**
  String get emptyTimelineBody;

  /// No description provided for @emptyTimelineAction.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get emptyTimelineAction;

  /// No description provided for @emptyCharactersTitle.
  ///
  /// In en, this message translates to:
  /// **'No characters yet'**
  String get emptyCharactersTitle;

  /// No description provided for @emptyCharactersBody.
  ///
  /// In en, this message translates to:
  /// **'Add protagonists, antagonists, and supporting cast to build your roster.'**
  String get emptyCharactersBody;

  /// No description provided for @emptyCharactersAction.
  ///
  /// In en, this message translates to:
  /// **'Create character'**
  String get emptyCharactersAction;

  /// No description provided for @emptyRelationshipsTitle.
  ///
  /// In en, this message translates to:
  /// **'No relationships yet'**
  String get emptyRelationshipsTitle;

  /// No description provided for @emptyRelationshipsBody.
  ///
  /// In en, this message translates to:
  /// **'Add two characters and describe how they relate.'**
  String get emptyRelationshipsBody;

  /// No description provided for @emptyRelationshipsAction.
  ///
  /// In en, this message translates to:
  /// **'Add relationship'**
  String get emptyRelationshipsAction;

  /// No description provided for @emptyFamilyTreesTitle.
  ///
  /// In en, this message translates to:
  /// **'No family trees yet'**
  String get emptyFamilyTreesTitle;

  /// No description provided for @emptyFamilyTreesBody.
  ///
  /// In en, this message translates to:
  /// **'Create a tree for a house or family, then add members.'**
  String get emptyFamilyTreesBody;

  /// No description provided for @emptyFamilyTreesAction.
  ///
  /// In en, this message translates to:
  /// **'Create family tree'**
  String get emptyFamilyTreesAction;

  /// No description provided for @emptyWorldTitle.
  ///
  /// In en, this message translates to:
  /// **'No world entries yet'**
  String get emptyWorldTitle;

  /// No description provided for @emptyWorldBody.
  ///
  /// In en, this message translates to:
  /// **'Catalog places, factions, magic, and history so your story stays consistent.'**
  String get emptyWorldBody;

  /// No description provided for @emptyWorldAction.
  ///
  /// In en, this message translates to:
  /// **'Create entry'**
  String get emptyWorldAction;

  /// No description provided for @emptyWorldMapTitle.
  ///
  /// In en, this message translates to:
  /// **'No map yet'**
  String get emptyWorldMapTitle;

  /// No description provided for @emptyWorldMapBody.
  ///
  /// In en, this message translates to:
  /// **'Add an image of your world to place locations on it.'**
  String get emptyWorldMapBody;

  /// No description provided for @emptyWorldMapAction.
  ///
  /// In en, this message translates to:
  /// **'Add map image'**
  String get emptyWorldMapAction;

  /// No description provided for @emptyMindMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Blank mind map'**
  String get emptyMindMapTitle;

  /// No description provided for @emptyMindMapBody.
  ///
  /// In en, this message translates to:
  /// **'Add a central idea to start branching.'**
  String get emptyMindMapBody;

  /// No description provided for @emptyMindMapAction.
  ///
  /// In en, this message translates to:
  /// **'Add first node'**
  String get emptyMindMapAction;

  /// No description provided for @emptyGraphTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to graph yet'**
  String get emptyGraphTitle;

  /// No description provided for @emptyGraphBody.
  ///
  /// In en, this message translates to:
  /// **'Add characters, locations, and chapters, then link them.'**
  String get emptyGraphBody;

  /// No description provided for @emptyGraphAction.
  ///
  /// In en, this message translates to:
  /// **'Add character'**
  String get emptyGraphAction;

  /// No description provided for @emptyNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get emptyNotesTitle;

  /// No description provided for @emptyNotesBody.
  ///
  /// In en, this message translates to:
  /// **'Add notes to chapters, characters, and world entries, and mark them resolved later.'**
  String get emptyNotesBody;

  /// No description provided for @emptyNotesAction.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get emptyNotesAction;

  /// No description provided for @emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your novel'**
  String get emptySearchTitle;

  /// No description provided for @emptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Find words in chapters, characters, world entries, and notes.'**
  String get emptySearchBody;

  /// No description provided for @emptyAiChatConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about your story'**
  String get emptyAiChatConfiguredTitle;

  /// No description provided for @emptyAiChatConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what the assistant can see, then ask. Nothing is sent until you do.'**
  String get emptyAiChatConfiguredBody;

  /// No description provided for @emptyAiChatNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'AI is off'**
  String get emptyAiChatNotConfiguredTitle;

  /// No description provided for @emptyAiChatNotConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'Add your own API key to use the assistant.'**
  String get emptyAiChatNotConfiguredBody;

  /// No description provided for @emptyAiChatNotConfiguredAction.
  ///
  /// In en, this message translates to:
  /// **'Set up AI'**
  String get emptyAiChatNotConfiguredAction;

  /// No description provided for @emptyConsistencyAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'No scan yet'**
  String get emptyConsistencyAuditTitle;

  /// No description provided for @emptyConsistencyAuditBody.
  ///
  /// In en, this message translates to:
  /// **'Run a scan to look for potential issues in the scope you choose.'**
  String get emptyConsistencyAuditBody;

  /// No description provided for @emptyConsistencyAuditAction.
  ///
  /// In en, this message translates to:
  /// **'Run scan'**
  String get emptyConsistencyAuditAction;

  /// No description provided for @emptyConsistencyAuditCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'No potential issues found in the scanned scope'**
  String get emptyConsistencyAuditCleanTitle;

  /// No description provided for @emptyConsistencyAuditCleanBody.
  ///
  /// In en, this message translates to:
  /// **'Scanned scope has no potential issues.'**
  String get emptyConsistencyAuditCleanBody;

  /// No description provided for @emptyConsistencyAuditCleanAction.
  ///
  /// In en, this message translates to:
  /// **'Run scan again'**
  String get emptyConsistencyAuditCleanAction;

  /// No description provided for @emptyGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No daily goal set'**
  String get emptyGoalsTitle;

  /// No description provided for @emptyGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'Set a daily word target to track your progress.'**
  String get emptyGoalsBody;

  /// No description provided for @emptyGoalsAction.
  ///
  /// In en, this message translates to:
  /// **'Set a goal'**
  String get emptyGoalsAction;

  /// No description provided for @emptyBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get emptyBackupTitle;

  /// No description provided for @emptyBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Create a backup to keep a copy of your novels outside the app.'**
  String get emptyBackupBody;

  /// No description provided for @emptyBackupAction.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get emptyBackupAction;

  /// No description provided for @emptyExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export'**
  String get emptyExportTitle;

  /// No description provided for @emptyExportBody.
  ///
  /// In en, this message translates to:
  /// **'Add a chapter first.'**
  String get emptyExportBody;

  /// No description provided for @emptyExportAction.
  ///
  /// In en, this message translates to:
  /// **'Add chapter'**
  String get emptyExportAction;

  /// No description provided for @emptyNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get emptyNoMatchesTitle;

  /// No description provided for @emptyNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search or filters.'**
  String get emptyNoMatchesBody;

  /// No description provided for @emptyNoMatchesAction.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get emptyNoMatchesAction;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how Novellie looks on your device'**
  String get settingsThemeModeDesc;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsColorTheme.
  ///
  /// In en, this message translates to:
  /// **'Primary Color Theme'**
  String get settingsColorTheme;

  /// No description provided for @settingsColorThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose an accent color to customize buttons, tags, and highlights.'**
  String get settingsColorThemeDesc;

  /// No description provided for @settingsEditorTypography.
  ///
  /// In en, this message translates to:
  /// **'Editor Typography'**
  String get settingsEditorTypography;

  /// No description provided for @settingsEditorFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get settingsEditorFontSize;

  /// No description provided for @settingsEditorTypeface.
  ///
  /// In en, this message translates to:
  /// **'Editor Typeface'**
  String get settingsEditorTypeface;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred application language'**
  String get settingsLanguageDesc;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystem;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @newChapter.
  ///
  /// In en, this message translates to:
  /// **'New chapter'**
  String get newChapter;

  /// No description provided for @newCharacter.
  ///
  /// In en, this message translates to:
  /// **'New character'**
  String get newCharacter;

  /// No description provided for @newWorldEntry.
  ///
  /// In en, this message translates to:
  /// **'New world entry'**
  String get newWorldEntry;

  /// No description provided for @newTimelineEvent.
  ///
  /// In en, this message translates to:
  /// **'New timeline event'**
  String get newTimelineEvent;

  /// No description provided for @openNovelFirst.
  ///
  /// In en, this message translates to:
  /// **'Open a novel first'**
  String get openNovelFirst;

  /// No description provided for @recentNovels.
  ///
  /// In en, this message translates to:
  /// **'Recent novels'**
  String get recentNovels;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search novels, chapters, lore, characters...'**
  String get searchHint;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNovels.
  ///
  /// In en, this message translates to:
  /// **'Novels'**
  String get filterNovels;

  /// No description provided for @filterChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get filterChapters;

  /// No description provided for @filterCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get filterCharacters;

  /// No description provided for @filterLore.
  ///
  /// In en, this message translates to:
  /// **'World Lore'**
  String get filterLore;

  /// No description provided for @filterTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get filterTimeline;

  /// No description provided for @filterScenes.
  ///
  /// In en, this message translates to:
  /// **'Scene Cards'**
  String get filterScenes;

  /// No description provided for @wordsWritten.
  ///
  /// In en, this message translates to:
  /// **'Words written'**
  String get wordsWritten;

  /// No description provided for @dailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get dailyTarget;

  /// No description provided for @newNovel.
  ///
  /// In en, this message translates to:
  /// **'New Novel'**
  String get newNovel;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @deleteNovel.
  ///
  /// In en, this message translates to:
  /// **'Delete Novel'**
  String get deleteNovel;

  /// No description provided for @deleteNovelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this novel? This cannot be undone.'**
  String get deleteNovelConfirm;

  /// No description provided for @writing.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get writing;

  /// No description provided for @statisticsAndGoals.
  ///
  /// In en, this message translates to:
  /// **'Statistics and goals'**
  String get statisticsAndGoals;

  /// No description provided for @statisticsAndGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track word counts, progress, and streaks'**
  String get statisticsAndGoalsDesc;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manuscript annotations and research'**
  String get notesDesc;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportDesc.
  ///
  /// In en, this message translates to:
  /// **'Export novel to PDF, TXT, Markdown, HTML'**
  String get exportDesc;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupAndRestore;

  /// No description provided for @backupAndRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage local project archives'**
  String get backupAndRestoreDesc;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @settingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Editor, AI providers, and theme preferences'**
  String get settingsDesc;

  /// No description provided for @aboutAndDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'About and diagnostics'**
  String get aboutAndDiagnostics;

  /// No description provided for @aboutAndDiagnosticsDesc.
  ///
  /// In en, this message translates to:
  /// **'App version, schema version, integrity tools'**
  String get aboutAndDiagnosticsDesc;

  /// No description provided for @appTourWalkthrough.
  ///
  /// In en, this message translates to:
  /// **'App Tour Walkthrough'**
  String get appTourWalkthrough;

  /// No description provided for @appTourWalkthroughDesc.
  ///
  /// In en, this message translates to:
  /// **'Replay the first-time feature guide & BYOK setup'**
  String get appTourWalkthroughDesc;

  /// No description provided for @supportAndCommunity.
  ///
  /// In en, this message translates to:
  /// **'Support & Community'**
  String get supportAndCommunity;

  /// No description provided for @supportUs.
  ///
  /// In en, this message translates to:
  /// **'Support Us'**
  String get supportUs;

  /// No description provided for @supportUsDesc.
  ///
  /// In en, this message translates to:
  /// **'Donate via Saweria, SociaBuzz, or Buy Me a Coffee'**
  String get supportUsDesc;

  /// No description provided for @githubRepository.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepository;

  /// No description provided for @githubRepositoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Star the project, report bugs, or view source code'**
  String get githubRepositoryDesc;

  /// No description provided for @activePreview.
  ///
  /// In en, this message translates to:
  /// **'Active Preview'**
  String get activePreview;

  /// No description provided for @writingEditor.
  ///
  /// In en, this message translates to:
  /// **'Writing Editor'**
  String get writingEditor;

  /// No description provided for @editorFontSizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust the text size in the writing workspace and reading mode'**
  String get editorFontSizeDesc;

  /// No description provided for @editorTypefaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred typography family for drafting'**
  String get editorTypefaceDesc;

  /// No description provided for @liveManuscriptPreview.
  ///
  /// In en, this message translates to:
  /// **'Live Manuscript Preview'**
  String get liveManuscriptPreview;

  /// No description provided for @aiAssistantByok.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant (BYOK)'**
  String get aiAssistantByok;

  /// No description provided for @configureProvider.
  ///
  /// In en, this message translates to:
  /// **'Configure Provider'**
  String get configureProvider;

  /// No description provided for @configureProviderDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up Gemini, OpenAI, Claude, or local Ollama API keys'**
  String get configureProviderDesc;

  /// No description provided for @projectBackups.
  ///
  /// In en, this message translates to:
  /// **'Project Backups'**
  String get projectBackups;

  /// No description provided for @createBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Create Backup Now'**
  String get createBackupNow;

  /// No description provided for @importExternalBackup.
  ///
  /// In en, this message translates to:
  /// **'Import External Backup'**
  String get importExternalBackup;

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backup History'**
  String get backupHistory;

  /// No description provided for @runIntegrityCheck.
  ///
  /// In en, this message translates to:
  /// **'Run Check'**
  String get runIntegrityCheck;

  /// No description provided for @databaseHealth.
  ///
  /// In en, this message translates to:
  /// **'Database Health'**
  String get databaseHealth;

  /// No description provided for @databaseIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Database Integrity'**
  String get databaseIntegrity;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @schemaVersion.
  ///
  /// In en, this message translates to:
  /// **'Schema Version'**
  String get schemaVersion;

  /// No description provided for @databaseSize.
  ///
  /// In en, this message translates to:
  /// **'Database Size'**
  String get databaseSize;

  /// No description provided for @activeNovels.
  ///
  /// In en, this message translates to:
  /// **'Active Novels'**
  String get activeNovels;

  /// No description provided for @totalChapters.
  ///
  /// In en, this message translates to:
  /// **'Total Chapters'**
  String get totalChapters;

  /// No description provided for @totalWords.
  ///
  /// In en, this message translates to:
  /// **'Total Words'**
  String get totalWords;

  /// No description provided for @exportManuscript.
  ///
  /// In en, this message translates to:
  /// **'Export Manuscript'**
  String get exportManuscript;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @extension.
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get extension;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @saveFile.
  ///
  /// In en, this message translates to:
  /// **'Save File'**
  String get saveFile;

  /// No description provided for @tourMode.
  ///
  /// In en, this message translates to:
  /// **'Tour Mode'**
  String get tourMode;

  /// No description provided for @skipTour.
  ///
  /// In en, this message translates to:
  /// **'Skip Tour'**
  String get skipTour;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @selectApplicationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Application Language'**
  String get selectApplicationLanguage;

  /// No description provided for @writersWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Writer’s Workshop'**
  String get writersWorkshop;

  /// No description provided for @writersWorkshopDesc.
  ///
  /// In en, this message translates to:
  /// **'Specialized worldbuilding instruments, plot generators, and utilities.'**
  String get writersWorkshopDesc;

  /// No description provided for @namesGenerator.
  ///
  /// In en, this message translates to:
  /// **'Names Generator'**
  String get namesGenerator;

  /// No description provided for @namesGeneratorDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate authentic character names across 14 cultural & fantasy origins, or craft deep mythic lore with AI (BYOK).'**
  String get namesGeneratorDesc;

  /// No description provided for @familyTree.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTree;

  /// No description provided for @familyTreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Create and visualize distinct multi-generational family trees, royal dynasties, and character lineages.'**
  String get familyTreeDesc;

  /// No description provided for @mindMap.
  ///
  /// In en, this message translates to:
  /// **'Mind Map'**
  String get mindMap;

  /// No description provided for @mindMapDesc.
  ///
  /// In en, this message translates to:
  /// **'Brainstorm ideas, sequence narrative chapter progressions, plot story arcs, and link dramatic beats.'**
  String get mindMapDesc;

  /// No description provided for @worldAtlas.
  ///
  /// In en, this message translates to:
  /// **'World Atlas'**
  String get worldAtlas;

  /// No description provided for @writersNotes.
  ///
  /// In en, this message translates to:
  /// **'Writer’s Notes'**
  String get writersNotes;

  /// No description provided for @manuscript.
  ///
  /// In en, this message translates to:
  /// **'Manuscript'**
  String get manuscript;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @world.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get world;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get planning;

  /// No description provided for @worldEncyclopedia.
  ///
  /// In en, this message translates to:
  /// **'World Encyclopedia'**
  String get worldEncyclopedia;

  /// No description provided for @statusIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get statusIdea;

  /// No description provided for @statusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get statusPlanning;

  /// No description provided for @statusDrafting.
  ///
  /// In en, this message translates to:
  /// **'Drafting'**
  String get statusDrafting;

  /// No description provided for @statusRevising.
  ///
  /// In en, this message translates to:
  /// **'Revising'**
  String get statusRevising;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get statusOnHold;

  /// No description provided for @roleProtagonist.
  ///
  /// In en, this message translates to:
  /// **'Protagonist'**
  String get roleProtagonist;

  /// No description provided for @roleAntagonist.
  ///
  /// In en, this message translates to:
  /// **'Antagonist'**
  String get roleAntagonist;

  /// No description provided for @roleSupporting.
  ///
  /// In en, this message translates to:
  /// **'Supporting'**
  String get roleSupporting;

  /// No description provided for @roleMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get roleMinor;

  /// No description provided for @primaryTarget.
  ///
  /// In en, this message translates to:
  /// **'Primary Target'**
  String get primaryTarget;

  /// No description provided for @writingTotals.
  ///
  /// In en, this message translates to:
  /// **'Writing Totals'**
  String get writingTotals;

  /// No description provided for @chaptersDrafted.
  ///
  /// In en, this message translates to:
  /// **'Chapters Drafted'**
  String get chaptersDrafted;

  /// No description provided for @novelsInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Novels in Library'**
  String get novelsInLibrary;

  /// No description provided for @avgWordsPerChapter.
  ///
  /// In en, this message translates to:
  /// **'Avg Words / Chapter'**
  String get avgWordsPerChapter;

  /// No description provided for @novelsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Novels Breakdown'**
  String get novelsBreakdown;

  /// No description provided for @currentProject.
  ///
  /// In en, this message translates to:
  /// **'Current Project'**
  String get currentProject;

  /// No description provided for @premiseAndGoals.
  ///
  /// In en, this message translates to:
  /// **'Premise & Goals'**
  String get premiseAndGoals;

  /// No description provided for @openGenerator.
  ///
  /// In en, this message translates to:
  /// **'Open Generator'**
  String get openGenerator;

  /// No description provided for @openTool.
  ///
  /// In en, this message translates to:
  /// **'Open Tool'**
  String get openTool;

  /// No description provided for @coreStudioCapability.
  ///
  /// In en, this message translates to:
  /// **'Core Studio Capability'**
  String get coreStudioCapability;

  /// No description provided for @proTipLabel.
  ///
  /// In en, this message translates to:
  /// **'Pro Tip'**
  String get proTipLabel;

  /// No description provided for @aiKeyActiveReady.
  ///
  /// In en, this message translates to:
  /// **'AI Key Active & Ready'**
  String get aiKeyActiveReady;

  /// No description provided for @aiKeyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI Provider Key not yet configured'**
  String get aiKeyNotConfigured;

  /// No description provided for @aiKeyConfiguredDesc.
  ///
  /// In en, this message translates to:
  /// **'Free Gemini / OpenAI / Claude keys power worldbuilding & drafting'**
  String get aiKeyConfiguredDesc;

  /// No description provided for @aiKeyRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Free Gemini 1.5 Flash keys or OpenAI/Claude required for AI tools'**
  String get aiKeyRequiredDesc;

  /// No description provided for @changeKey.
  ///
  /// In en, this message translates to:
  /// **'Change Key'**
  String get changeKey;

  /// No description provided for @configureKey.
  ///
  /// In en, this message translates to:
  /// **'Configure Key'**
  String get configureKey;

  /// No description provided for @projectArchives.
  ///
  /// In en, this message translates to:
  /// **'Project Archives'**
  String get projectArchives;

  /// No description provided for @projectArchivesDesc.
  ///
  /// In en, this message translates to:
  /// **'Save or restore complete snapshots of novels, chapters, lore, characters, and outlines.'**
  String get projectArchivesDesc;

  /// No description provided for @restoreArchive.
  ///
  /// In en, this message translates to:
  /// **'Restore Archive?'**
  String get restoreArchive;

  /// No description provided for @restoreArchiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Restoring from this archive will replace all current manuscripts, chapters, lore entries, characters, and outlines.'**
  String get restoreArchiveDesc;

  /// No description provided for @importAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Import & Restore'**
  String get importAndRestore;

  /// No description provided for @importAndRestoreArchive.
  ///
  /// In en, this message translates to:
  /// **'Import & Restore Archive?'**
  String get importAndRestoreArchive;

  /// No description provided for @importAndRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Restoring this file will import the archive into your backup history and overwrite current manuscripts and lore.'**
  String get importAndRestoreDesc;

  /// No description provided for @deleteBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup?'**
  String get deleteBackupTitle;

  /// No description provided for @deleteBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this backup file from your device.'**
  String get deleteBackupConfirm;

  /// No description provided for @deleteNovelQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Novel?'**
  String get deleteNovelQuestion;

  /// No description provided for @deleteNovelWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this novel? All chapters and world data will be moved to trash.'**
  String get deleteNovelWarning;

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get words;

  /// No description provided for @chaptersCount.
  ///
  /// In en, this message translates to:
  /// **'chapters'**
  String get chaptersCount;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @aiIndexScanner.
  ///
  /// In en, this message translates to:
  /// **'AI Index Scanner'**
  String get aiIndexScanner;

  /// No description provided for @backToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Back to Library'**
  String get backToLibrary;

  /// No description provided for @novelWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Novel Workspace'**
  String get novelWorkspace;

  /// No description provided for @systemInformation.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInformation;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get application;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @databaseSchema.
  ///
  /// In en, this message translates to:
  /// **'Database Schema'**
  String get databaseSchema;

  /// No description provided for @journalMode.
  ///
  /// In en, this message translates to:
  /// **'Journal Mode'**
  String get journalMode;

  /// No description provided for @autosaveCadence.
  ///
  /// In en, this message translates to:
  /// **'Autosave Cadence'**
  String get autosaveCadence;

  /// No description provided for @sqliteIntegrityCheck.
  ///
  /// In en, this message translates to:
  /// **'SQLite Integrity Check'**
  String get sqliteIntegrityCheck;

  /// No description provided for @sqliteIntegrityDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify B-tree structure, index alignment, and table sanity'**
  String get sqliteIntegrityDesc;

  /// No description provided for @integrityPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get integrityPassed;

  /// No description provided for @integrityAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get integrityAlert;

  /// No description provided for @reverifyDatabase.
  ///
  /// In en, this message translates to:
  /// **'Re-verify Database'**
  String get reverifyDatabase;

  /// No description provided for @storedRecords.
  ///
  /// In en, this message translates to:
  /// **'Stored Records'**
  String get storedRecords;

  /// No description provided for @recordNovels.
  ///
  /// In en, this message translates to:
  /// **'Novels'**
  String get recordNovels;

  /// No description provided for @recordChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get recordChapters;

  /// No description provided for @recordCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get recordCharacters;

  /// No description provided for @recordWorldLore.
  ///
  /// In en, this message translates to:
  /// **'World Lore'**
  String get recordWorldLore;

  /// No description provided for @recordTimelineEvents.
  ///
  /// In en, this message translates to:
  /// **'Timeline Events'**
  String get recordTimelineEvents;

  /// No description provided for @recordVersionSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Version Snapshots'**
  String get recordVersionSnapshots;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @openWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open Workspace'**
  String get openWorkspace;

  /// No description provided for @failedToLoadSearch.
  ///
  /// In en, this message translates to:
  /// **'Failed to load search results.'**
  String get failedToLoadSearch;

  /// No description provided for @noMatchingNovels.
  ///
  /// In en, this message translates to:
  /// **'No matching novels'**
  String get noMatchingNovels;

  /// No description provided for @failedToLoadLibrary.
  ///
  /// In en, this message translates to:
  /// **'Failed to load novel library'**
  String get failedToLoadLibrary;

  /// No description provided for @failedToLoadLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading your library.'**
  String get failedToLoadLibraryDesc;

  /// No description provided for @identityAndDetails.
  ///
  /// In en, this message translates to:
  /// **'Identity & Details'**
  String get identityAndDetails;

  /// No description provided for @identityAndDetailsDesc.
  ///
  /// In en, this message translates to:
  /// **'Give your novel a name, cover, subtitle, and genre.'**
  String get identityAndDetailsDesc;

  /// No description provided for @addCover.
  ///
  /// In en, this message translates to:
  /// **'Add Cover'**
  String get addCover;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @changeCover.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get changeCover;

  /// No description provided for @chooseCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Cover Image'**
  String get chooseCoverImage;

  /// No description provided for @novelTitle.
  ///
  /// In en, this message translates to:
  /// **'Novel Title'**
  String get novelTitle;

  /// No description provided for @enterNovelTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter novel title'**
  String get enterNovelTitle;

  /// No description provided for @subtitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Subtitle / Series Name (Optional)'**
  String get subtitleOptional;

  /// No description provided for @authorOptional.
  ///
  /// In en, this message translates to:
  /// **'Author / Pen Name (Optional)'**
  String get authorOptional;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @addGenre.
  ///
  /// In en, this message translates to:
  /// **'Add Genre'**
  String get addGenre;

  /// No description provided for @customGenre.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customGenre;

  /// No description provided for @addCustomGenre.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Genre'**
  String get addCustomGenre;

  /// No description provided for @nextPremiseAndGoals.
  ///
  /// In en, this message translates to:
  /// **'Next: Premise & Goals'**
  String get nextPremiseAndGoals;

  /// No description provided for @pleaseEnterNovelTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a novel title'**
  String get pleaseEnterNovelTitle;

  /// No description provided for @premiseAndGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Describe the core conflict and define your writing targets.'**
  String get premiseAndGoalsDesc;

  /// No description provided for @synopsisPremise.
  ///
  /// In en, this message translates to:
  /// **'Synopsis / Premise'**
  String get synopsisPremise;

  /// No description provided for @synopsisHint.
  ///
  /// In en, this message translates to:
  /// **'What is this story about? What is the main conflict?'**
  String get synopsisHint;

  /// No description provided for @initialStatus.
  ///
  /// In en, this message translates to:
  /// **'Initial Status'**
  String get initialStatus;

  /// No description provided for @novelTargetWords.
  ///
  /// In en, this message translates to:
  /// **'Novel Target (Words)'**
  String get novelTargetWords;

  /// No description provided for @chapterTargetWords.
  ///
  /// In en, this message translates to:
  /// **'Chapter Target (Words)'**
  String get chapterTargetWords;

  /// No description provided for @editNovelDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Novel Details'**
  String get editNovelDetails;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @planningHub.
  ///
  /// In en, this message translates to:
  /// **'Planning Hub'**
  String get planningHub;

  /// No description provided for @chooseNovel.
  ///
  /// In en, this message translates to:
  /// **'Choose Novel'**
  String get chooseNovel;

  /// No description provided for @chooseNovelDesc.
  ///
  /// In en, this message translates to:
  /// **'Select which novel to plan and outline'**
  String get chooseNovelDesc;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @sceneCards.
  ///
  /// In en, this message translates to:
  /// **'Scene Cards'**
  String get sceneCards;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// No description provided for @newScene.
  ///
  /// In en, this message translates to:
  /// **'New Scene'**
  String get newScene;

  /// No description provided for @selectNovelToPlan.
  ///
  /// In en, this message translates to:
  /// **'Select a Novel to Plan'**
  String get selectNovelToPlan;

  /// No description provided for @selectNovelToPlanDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose one of your novels to view and organize its timeline and scene cards.'**
  String get selectNovelToPlanDesc;

  /// No description provided for @failedToLoadEvents.
  ///
  /// In en, this message translates to:
  /// **'Failed to load timeline events'**
  String get failedToLoadEvents;

  /// No description provided for @failedToLoadScenes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load scene cards'**
  String get failedToLoadScenes;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No timeline events yet'**
  String get noEventsYet;

  /// No description provided for @noEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track story chronology, historical milestones, and character arcs.'**
  String get noEventsDesc;

  /// No description provided for @noScenesYet.
  ///
  /// In en, this message translates to:
  /// **'No scene cards yet'**
  String get noScenesYet;

  /// No description provided for @noScenesDesc.
  ///
  /// In en, this message translates to:
  /// **'Outline chapters into distinct dramatic beats and conflict scenes.'**
  String get noScenesDesc;

  /// No description provided for @addCharacter.
  ///
  /// In en, this message translates to:
  /// **'Add Character'**
  String get addCharacter;

  /// No description provided for @noCharactersYet.
  ///
  /// In en, this message translates to:
  /// **'No characters yet'**
  String get noCharactersYet;

  /// No description provided for @noCharactersBody.
  ///
  /// In en, this message translates to:
  /// **'Introduce protagonists, antagonists, and supporting cast for your novel.'**
  String get noCharactersBody;

  /// No description provided for @createCharacter.
  ///
  /// In en, this message translates to:
  /// **'Create Character'**
  String get createCharacter;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @noWorldLoreYet.
  ///
  /// In en, this message translates to:
  /// **'No world lore yet'**
  String get noWorldLoreYet;

  /// No description provided for @noWorldLoreBody.
  ///
  /// In en, this message translates to:
  /// **'Document magic systems, factions, geography, history, and artefacts.'**
  String get noWorldLoreBody;

  /// No description provided for @addFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Add First Entry'**
  String get addFirstEntry;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// No description provided for @backToChat.
  ///
  /// In en, this message translates to:
  /// **'Back to Chat'**
  String get backToChat;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @contextPreferences.
  ///
  /// In en, this message translates to:
  /// **'Context Preferences'**
  String get contextPreferences;

  /// No description provided for @aiProviderSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Provider Settings'**
  String get aiProviderSettings;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @closeAiPanel.
  ///
  /// In en, this message translates to:
  /// **'Close AI Panel'**
  String get closeAiPanel;

  /// No description provided for @selectAiNovelContext.
  ///
  /// In en, this message translates to:
  /// **'Select AI Novel Context'**
  String get selectAiNovelContext;

  /// No description provided for @selectAiNovelContextDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which novel\'s lore, characters, and chapters provide context for AI responses.'**
  String get selectAiNovelContextDesc;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get copiedToClipboard;

  /// No description provided for @insertIntoEditor.
  ///
  /// In en, this message translates to:
  /// **'Insert into Editor'**
  String get insertIntoEditor;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
