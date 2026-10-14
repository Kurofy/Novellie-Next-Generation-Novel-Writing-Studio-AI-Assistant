// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Novellie';

  @override
  String get navHome => 'Home';

  @override
  String get navNovels => 'Novels';

  @override
  String get navPlanning => 'Planning';

  @override
  String get navTools => 'Tools';

  @override
  String get navAi => 'AI';

  @override
  String get navMore => 'Misc';

  @override
  String get createNovel => 'Create Novel';

  @override
  String get createFirstNovel => 'Create your first novel';

  @override
  String get importDraft => 'Import draft';

  @override
  String get search => 'Search';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get restore => 'Restore';

  @override
  String get delete => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get savedJustNow => 'Saved just now';

  @override
  String get saving => 'Saving…';

  @override
  String get notSavedRetrying => 'Not saved — retrying';

  @override
  String get emptyActiveNovelTitle => 'No active novel';

  @override
  String get emptyActiveNovelBody =>
      'Create a novel or open one from your library to start writing.';

  @override
  String get emptyActiveNovelAction => 'Create novel';

  @override
  String get emptyRecentNovelsTitle => 'Your novels will appear here';

  @override
  String get emptyRecentNovelsBody =>
      'Recently opened novels show up as soon as you create one.';

  @override
  String get emptyRecentNovelsAction => 'Create a novel';

  @override
  String get emptyLibraryTitle => 'No novels yet';

  @override
  String get emptyLibraryBody =>
      'Create a novel or import a draft to start writing.';

  @override
  String get emptyLibraryAction => 'Create novel';

  @override
  String get emptyWorkspaceTitle => 'No chapters yet';

  @override
  String get emptyWorkspaceBody =>
      'Structure your novel into volumes, arcs, and chapters.';

  @override
  String get emptyWorkspaceAction => 'Add chapter 1';

  @override
  String get emptyEditorPlaceholder => 'Start writing…';

  @override
  String get emptyVersionHistoryTitle => 'No snapshots yet';

  @override
  String get emptyVersionHistoryBody =>
      'Snapshots are created while you write and before any restore or AI replace.';

  @override
  String get emptyVersionHistoryAction => 'Create snapshot';

  @override
  String get emptyVersionCompareTitle => 'Nothing to compare';

  @override
  String get emptyVersionCompareBody =>
      'Choose two versions to see what changed.';

  @override
  String get emptyVersionCompareAction => 'Choose versions';

  @override
  String get emptySceneCardsTitle => 'No scene cards yet';

  @override
  String get emptySceneCardsBody =>
      'Outline your story scene by scene with a goal, conflict, point of view, and outcome.';

  @override
  String get emptySceneCardsAction => 'Add scene card';

  @override
  String get emptyOutlineTitle => 'No outline yet';

  @override
  String get emptyOutlineBody =>
      'Choose a structure to add its beats, or start from a blank outline.';

  @override
  String get emptyOutlineAction => 'Choose a structure';

  @override
  String get emptyTimelineTitle => 'No events yet';

  @override
  String get emptyTimelineBody =>
      'Record what happens and when, then link events to characters, places, and chapters.';

  @override
  String get emptyTimelineAction => 'Add event';

  @override
  String get emptyCharactersTitle => 'No characters yet';

  @override
  String get emptyCharactersBody =>
      'Add protagonists, antagonists, and supporting cast to build your roster.';

  @override
  String get emptyCharactersAction => 'Create character';

  @override
  String get emptyRelationshipsTitle => 'No relationships yet';

  @override
  String get emptyRelationshipsBody =>
      'Add two characters and describe how they relate.';

  @override
  String get emptyRelationshipsAction => 'Add relationship';

  @override
  String get emptyFamilyTreesTitle => 'No family trees yet';

  @override
  String get emptyFamilyTreesBody =>
      'Create a tree for a house or family, then add members.';

  @override
  String get emptyFamilyTreesAction => 'Create family tree';

  @override
  String get emptyWorldTitle => 'No world entries yet';

  @override
  String get emptyWorldBody =>
      'Catalog places, factions, magic, and history so your story stays consistent.';

  @override
  String get emptyWorldAction => 'Create entry';

  @override
  String get emptyWorldMapTitle => 'No map yet';

  @override
  String get emptyWorldMapBody =>
      'Add an image of your world to place locations on it.';

  @override
  String get emptyWorldMapAction => 'Add map image';

  @override
  String get emptyMindMapTitle => 'Blank mind map';

  @override
  String get emptyMindMapBody => 'Add a central idea to start branching.';

  @override
  String get emptyMindMapAction => 'Add first node';

  @override
  String get emptyGraphTitle => 'Nothing to graph yet';

  @override
  String get emptyGraphBody =>
      'Add characters, locations, and chapters, then link them.';

  @override
  String get emptyGraphAction => 'Add character';

  @override
  String get emptyNotesTitle => 'No notes yet';

  @override
  String get emptyNotesBody =>
      'Add notes to chapters, characters, and world entries, and mark them resolved later.';

  @override
  String get emptyNotesAction => 'Add note';

  @override
  String get emptySearchTitle => 'Search your novel';

  @override
  String get emptySearchBody =>
      'Find words in chapters, characters, world entries, and notes.';

  @override
  String get emptyAiChatConfiguredTitle => 'Ask about your story';

  @override
  String get emptyAiChatConfiguredBody =>
      'Choose what the assistant can see, then ask. Nothing is sent until you do.';

  @override
  String get emptyAiChatNotConfiguredTitle => 'AI is off';

  @override
  String get emptyAiChatNotConfiguredBody =>
      'Add your own API key to use the assistant.';

  @override
  String get emptyAiChatNotConfiguredAction => 'Set up AI';

  @override
  String get emptyConsistencyAuditTitle => 'No scan yet';

  @override
  String get emptyConsistencyAuditBody =>
      'Run a scan to look for potential issues in the scope you choose.';

  @override
  String get emptyConsistencyAuditAction => 'Run scan';

  @override
  String get emptyConsistencyAuditCleanTitle =>
      'No potential issues found in the scanned scope';

  @override
  String get emptyConsistencyAuditCleanBody =>
      'Scanned scope has no potential issues.';

  @override
  String get emptyConsistencyAuditCleanAction => 'Run scan again';

  @override
  String get emptyGoalsTitle => 'No daily goal set';

  @override
  String get emptyGoalsBody =>
      'Set a daily word target to track your progress.';

  @override
  String get emptyGoalsAction => 'Set a goal';

  @override
  String get emptyBackupTitle => 'No backups yet';

  @override
  String get emptyBackupBody =>
      'Create a backup to keep a copy of your novels outside the app.';

  @override
  String get emptyBackupAction => 'Back up now';

  @override
  String get emptyExportTitle => 'Nothing to export';

  @override
  String get emptyExportBody => 'Add a chapter first.';

  @override
  String get emptyExportAction => 'Add chapter';

  @override
  String get emptyNoMatchesTitle => 'No results';

  @override
  String get emptyNoMatchesBody => 'Nothing matches your search or filters.';

  @override
  String get emptyNoMatchesAction => 'Clear filters';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get settingsThemeModeDesc =>
      'Choose how Novellie looks on your device';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsColorTheme => 'Primary Color Theme';

  @override
  String get settingsColorThemeDesc =>
      'Choose an accent color to customize buttons, tags, and highlights.';

  @override
  String get settingsEditorTypography => 'Editor Typography';

  @override
  String get settingsEditorFontSize => 'Editor Font Size';

  @override
  String get settingsEditorTypeface => 'Editor Typeface';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDesc =>
      'Choose your preferred application language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageSystem => 'System Default';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get newChapter => 'New chapter';

  @override
  String get newCharacter => 'New character';

  @override
  String get newWorldEntry => 'New world entry';

  @override
  String get newTimelineEvent => 'New timeline event';

  @override
  String get openNovelFirst => 'Open a novel first';

  @override
  String get recentNovels => 'Recent novels';

  @override
  String get viewAll => 'View all';

  @override
  String get searchHint => 'Search novels, chapters, lore, characters...';

  @override
  String get searchResults => 'Search Results';

  @override
  String get clear => 'Clear';

  @override
  String get filterAll => 'All';

  @override
  String get filterNovels => 'Novels';

  @override
  String get filterChapters => 'Chapters';

  @override
  String get filterCharacters => 'Characters';

  @override
  String get filterLore => 'World Lore';

  @override
  String get filterTimeline => 'Timeline';

  @override
  String get filterScenes => 'Scene Cards';

  @override
  String get wordsWritten => 'Words written';

  @override
  String get dailyTarget => 'Daily target';

  @override
  String get newNovel => 'New Novel';

  @override
  String get editDetails => 'Edit Details';

  @override
  String get deleteNovel => 'Delete Novel';

  @override
  String get deleteNovelConfirm =>
      'Are you sure you want to delete this novel? This cannot be undone.';

  @override
  String get writing => 'Writing';

  @override
  String get statisticsAndGoals => 'Statistics and goals';

  @override
  String get statisticsAndGoalsDesc =>
      'Track word counts, progress, and streaks';

  @override
  String get notes => 'Notes';

  @override
  String get notesDesc => 'Manuscript annotations and research';

  @override
  String get dataSection => 'Data';

  @override
  String get export => 'Export';

  @override
  String get exportDesc => 'Export novel to PDF, TXT, Markdown, HTML';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get backupAndRestoreDesc => 'Manage local project archives';

  @override
  String get appSection => 'App';

  @override
  String get settingsDesc => 'Editor, AI providers, and theme preferences';

  @override
  String get aboutAndDiagnostics => 'About and diagnostics';

  @override
  String get aboutAndDiagnosticsDesc =>
      'App version, schema version, integrity tools';

  @override
  String get appTourWalkthrough => 'App Tour Walkthrough';

  @override
  String get appTourWalkthroughDesc =>
      'Replay the first-time feature guide & BYOK setup';

  @override
  String get supportAndCommunity => 'Support & Community';

  @override
  String get supportUs => 'Support Us';

  @override
  String get supportUsDesc =>
      'Donate via Saweria, SociaBuzz, or Buy Me a Coffee';

  @override
  String get githubRepository => 'GitHub Repository';

  @override
  String get githubRepositoryDesc =>
      'Star the project, report bugs, or view source code';

  @override
  String get activePreview => 'Active Preview';

  @override
  String get writingEditor => 'Writing Editor';

  @override
  String get editorFontSizeDesc =>
      'Adjust the text size in the writing workspace and reading mode';

  @override
  String get editorTypefaceDesc =>
      'Select your preferred typography family for drafting';

  @override
  String get liveManuscriptPreview => 'Live Manuscript Preview';

  @override
  String get aiAssistantByok => 'AI Assistant (BYOK)';

  @override
  String get configureProvider => 'Configure Provider';

  @override
  String get configureProviderDesc =>
      'Set up Gemini, OpenAI, Claude, or local Ollama API keys';

  @override
  String get projectBackups => 'Project Backups';

  @override
  String get createBackupNow => 'Create Backup Now';

  @override
  String get importExternalBackup => 'Import External Backup';

  @override
  String get backupHistory => 'Backup History';

  @override
  String get runIntegrityCheck => 'Run Check';

  @override
  String get databaseHealth => 'Database Health';

  @override
  String get databaseIntegrity => 'Database Integrity';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get appVersion => 'App Version';

  @override
  String get schemaVersion => 'Schema Version';

  @override
  String get databaseSize => 'Database Size';

  @override
  String get activeNovels => 'Active Novels';

  @override
  String get totalChapters => 'Total Chapters';

  @override
  String get totalWords => 'Total Words';

  @override
  String get exportManuscript => 'Export Manuscript';

  @override
  String get format => 'Format';

  @override
  String get chapters => 'Chapters';

  @override
  String get extension => 'Extension';

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get saveFile => 'Save File';

  @override
  String get tourMode => 'Tour Mode';

  @override
  String get skipTour => 'Skip Tour';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get selectApplicationLanguage => 'Select Application Language';

  @override
  String get writersWorkshop => 'Writer’s Workshop';

  @override
  String get writersWorkshopDesc =>
      'Specialized worldbuilding instruments, plot generators, and utilities.';

  @override
  String get namesGenerator => 'Names Generator';

  @override
  String get namesGeneratorDesc =>
      'Generate authentic character names across 14 cultural & fantasy origins, or craft deep mythic lore with AI (BYOK).';

  @override
  String get familyTree => 'Family Tree';

  @override
  String get familyTreeDesc =>
      'Create and visualize distinct multi-generational family trees, royal dynasties, and character lineages.';

  @override
  String get mindMap => 'Mind Map';

  @override
  String get mindMapDesc =>
      'Brainstorm ideas, sequence narrative chapter progressions, plot story arcs, and link dramatic beats.';

  @override
  String get worldAtlas => 'World Atlas';

  @override
  String get writersNotes => 'Writer Notes';

  @override
  String get manuscript => 'Manuscript';

  @override
  String get characters => 'Characters';

  @override
  String get world => 'World';

  @override
  String get planning => 'Planning';

  @override
  String get worldEncyclopedia => 'World Encyclopedia';

  @override
  String get statusIdea => 'Idea';

  @override
  String get statusPlanning => 'Planning';

  @override
  String get statusDrafting => 'Drafting';

  @override
  String get statusRevising => 'Revising';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusOnHold => 'On Hold';

  @override
  String get roleProtagonist => 'Protagonist';

  @override
  String get roleAntagonist => 'Antagonist';

  @override
  String get roleSupporting => 'Supporting';

  @override
  String get roleMinor => 'Minor';

  @override
  String get primaryTarget => 'Primary Target';

  @override
  String get writingTotals => 'Writing Totals';

  @override
  String get chaptersDrafted => 'Chapters Drafted';

  @override
  String get novelsInLibrary => 'Novels in Library';

  @override
  String get avgWordsPerChapter => 'Avg Words / Chapter';

  @override
  String get novelsBreakdown => 'Novels Breakdown';

  @override
  String get currentProject => 'Current Project';

  @override
  String get premiseAndGoals => 'Premise & Goals';

  @override
  String get openGenerator => 'Open Generator';

  @override
  String get openTool => 'Open Tool';

  @override
  String get coreStudioCapability => 'Core Studio Capability';

  @override
  String get proTipLabel => 'Pro Tip';

  @override
  String get aiKeyActiveReady => 'AI Key Active & Ready';

  @override
  String get aiKeyNotConfigured => 'AI Provider Key not yet configured';

  @override
  String get aiKeyConfiguredDesc =>
      'Free Gemini / OpenAI / Claude keys power worldbuilding & drafting';

  @override
  String get aiKeyRequiredDesc =>
      'Free Gemini 1.5 Flash keys or OpenAI/Claude required for AI tools';

  @override
  String get changeKey => 'Change Key';

  @override
  String get configureKey => 'Configure Key';

  @override
  String get projectArchives => 'Project Archives';

  @override
  String get projectArchivesDesc =>
      'Save or restore complete snapshots of novels, chapters, lore, characters, and outlines.';

  @override
  String get restoreArchive => 'Restore Archive?';

  @override
  String get restoreArchiveDesc =>
      'Restoring from this archive will replace all current manuscripts, chapters, lore entries, characters, and outlines.';

  @override
  String get importAndRestore => 'Import & Restore';

  @override
  String get importAndRestoreArchive => 'Import & Restore Archive?';

  @override
  String get importAndRestoreDesc =>
      'Restoring this file will import the archive into your backup history and overwrite current manuscripts and lore.';

  @override
  String get deleteBackupTitle => 'Delete Backup?';

  @override
  String get deleteBackupConfirm =>
      'This will permanently delete this backup file from your device.';

  @override
  String get deleteNovelQuestion => 'Delete Novel?';

  @override
  String get deleteNovelWarning =>
      'Are you sure you want to delete this novel? All chapters and world data will be moved to trash.';

  @override
  String get words => 'words';

  @override
  String get chaptersCount => 'chapters';

  @override
  String get close => 'Close';

  @override
  String get aiIndexScanner => 'AI Index Scanner';

  @override
  String get backToLibrary => 'Back to Library';

  @override
  String get novelWorkspace => 'Novel Workspace';

  @override
  String get systemInformation => 'System Information';

  @override
  String get application => 'Application';

  @override
  String get version => 'Version';

  @override
  String get databaseSchema => 'Database Schema';

  @override
  String get journalMode => 'Journal Mode';

  @override
  String get autosaveCadence => 'Autosave Cadence';

  @override
  String get sqliteIntegrityCheck => 'SQLite Integrity Check';

  @override
  String get sqliteIntegrityDesc =>
      'Verify B-tree structure, index alignment, and table sanity';

  @override
  String get integrityPassed => 'Passed';

  @override
  String get integrityAlert => 'Alert';

  @override
  String get reverifyDatabase => 'Re-verify Database';

  @override
  String get storedRecords => 'Stored Records';

  @override
  String get recordNovels => 'Novels';

  @override
  String get recordChapters => 'Chapters';

  @override
  String get recordCharacters => 'Characters';

  @override
  String get recordWorldLore => 'World Lore';

  @override
  String get recordTimelineEvents => 'Timeline Events';

  @override
  String get recordVersionSnapshots => 'Version Snapshots';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get openWorkspace => 'Open Workspace';

  @override
  String get failedToLoadSearch => 'Failed to load search results.';

  @override
  String get noMatchingNovels => 'No matching novels';

  @override
  String get failedToLoadLibrary => 'Failed to load novel library';

  @override
  String get failedToLoadLibraryDesc =>
      'An error occurred while loading your library.';

  @override
  String get identityAndDetails => 'Identity & Details';

  @override
  String get identityAndDetailsDesc =>
      'Give your novel a name, cover, subtitle, and genre.';

  @override
  String get addCover => 'Add Cover';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get changeCover => 'Change Cover';

  @override
  String get chooseCoverImage => 'Choose Cover Image';

  @override
  String get novelTitle => 'Novel Title';

  @override
  String get enterNovelTitle => 'Enter novel title';

  @override
  String get subtitleOptional => 'Subtitle / Series Name (Optional)';

  @override
  String get authorOptional => 'Author / Pen Name (Optional)';

  @override
  String get genre => 'Genre';

  @override
  String get addGenre => 'Add Genre';

  @override
  String get customGenre => 'Custom';

  @override
  String get addCustomGenre => 'Add Custom Genre';

  @override
  String get nextPremiseAndGoals => 'Next: Premise & Goals';

  @override
  String get pleaseEnterNovelTitle => 'Please enter a novel title';

  @override
  String get premiseAndGoalsDesc =>
      'Describe the core conflict and define your writing targets.';

  @override
  String get synopsisPremise => 'Synopsis / Premise';

  @override
  String get synopsisHint =>
      'What is this story about? What is the main conflict?';

  @override
  String get initialStatus => 'Initial Status';

  @override
  String get novelTargetWords => 'Novel Target (Words)';

  @override
  String get chapterTargetWords => 'Chapter Target (Words)';

  @override
  String get editNovelDetails => 'Edit Novel Details';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get planningHub => 'Planning Hub';

  @override
  String get chooseNovel => 'Choose Novel';

  @override
  String get chooseNovelDesc => 'Select which novel to plan and outline';

  @override
  String get active => 'Active';

  @override
  String get timeline => 'Timeline';

  @override
  String get sceneCards => 'Scene Cards';

  @override
  String get newEvent => 'New Event';

  @override
  String get newScene => 'New Scene';

  @override
  String get selectNovelToPlan => 'Select a Novel to Plan';

  @override
  String get selectNovelToPlanDesc =>
      'Choose one of your novels to view and organize its timeline and scene cards.';

  @override
  String get failedToLoadEvents => 'Failed to load timeline events';

  @override
  String get failedToLoadScenes => 'Failed to load scene cards';

  @override
  String get noEventsYet => 'No timeline events yet';

  @override
  String get noEventsDesc =>
      'Track story chronology, historical milestones, and character arcs.';

  @override
  String get noScenesYet => 'No scene cards yet';

  @override
  String get noScenesDesc =>
      'Outline chapters into distinct dramatic beats and conflict scenes.';

  @override
  String get addCharacter => 'Add Character';

  @override
  String get noCharactersYet => 'No characters yet';

  @override
  String get noCharactersBody =>
      'Introduce protagonists, antagonists, and supporting cast for your novel.';

  @override
  String get createCharacter => 'Create Character';

  @override
  String get allRoles => 'All Roles';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get noWorldLoreYet => 'No world lore yet';

  @override
  String get noWorldLoreBody =>
      'Document magic systems, factions, geography, history, and artefacts.';

  @override
  String get addFirstEntry => 'Add First Entry';

  @override
  String get allCategories => 'All Categories';

  @override
  String get newChat => 'New Chat';

  @override
  String get chatHistory => 'Chat History';

  @override
  String get backToChat => 'Back to Chat';

  @override
  String get moreOptions => 'More options';

  @override
  String get contextPreferences => 'Context Preferences';

  @override
  String get aiProviderSettings => 'AI Provider Settings';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get closeAiPanel => 'Close AI Panel';

  @override
  String get selectAiNovelContext => 'Select AI Novel Context';

  @override
  String get selectAiNovelContextDesc =>
      'Choose which novel\'s lore, characters, and chapters provide context for AI responses.';

  @override
  String get copiedToClipboard => 'Copied to clipboard!';

  @override
  String get insertIntoEditor => 'Insert into Editor';
}
