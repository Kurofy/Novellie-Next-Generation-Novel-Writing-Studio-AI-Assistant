import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_tables.dart';
import 'tables/character_tables.dart';
import 'tables/novel_tables.dart';
import 'tables/planning_tables.dart';
import 'tables/stats_and_ai_tables.dart';
import 'tables/timeline_tables.dart';
import 'tables/world_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppSettings,
    UserProfile,
    AiProviderSettings,
    Novels,
    Tags,
    EntityTags,
    Volumes,
    Arcs,
    Chapters,
    ChapterContents,
    ChapterVersions,
    Characters,
    CharacterAliases,
    CharacterRelationships,
    WorldCategories,
    WorldEntries,
    WorldEntrySections,
    Scenes,
    SceneCharacters,
    SceneBeats,
    TimelinePeriods,
    Events,
    EntityLinks,
    EntityMentions,
    WritingGoals,
    WritingSessions,
    DailyWritingStats,
    Backups,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');

          // Seamless schema resilience: Ensure any newly added columns exist in characters table
          try {
            final charInfo = await customSelect('PRAGMA table_info(characters);').get();
            final existingCharCols = charInfo.map((row) => row.read<String>('name')).toSet();
            if (existingCharCols.isNotEmpty) {
              final colDefs = {
                'nickname': 'TEXT',
                'age_text': 'TEXT',
                'age_years': 'INTEGER',
                'gender': 'TEXT',
                'pronouns': 'TEXT',
                'role': "TEXT NOT NULL DEFAULT 'supporting'",
                'moral_alignment': "TEXT NOT NULL DEFAULT 'unspecified'",
                'status': "TEXT NOT NULL DEFAULT 'alive'",
                'status_note': 'TEXT',
                'appearance': 'TEXT',
                'personality': 'TEXT',
                'motivation': 'TEXT',
                'goal': 'TEXT',
                'fear': 'TEXT',
                'secret': 'TEXT',
                'flaw': 'TEXT',
                'strengths': 'TEXT',
                'weaknesses': 'TEXT',
                'backstory': 'TEXT',
                'arc_type': 'TEXT',
                'arc_summary': 'TEXT',
                'first_appearance_chapter_id': 'TEXT',
                'last_appearance_chapter_id': 'TEXT',
                'portrait_path': 'TEXT',
                'notes': 'TEXT',
                'archived_at': 'INTEGER',
                'deleted_at': 'INTEGER',
              };
              for (final entry in colDefs.entries) {
                if (!existingCharCols.contains(entry.key)) {
                  await customStatement('ALTER TABLE characters ADD COLUMN ${entry.key} ${entry.value};');
                }
              }
            }
          } catch (_) {}
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'novellie_db');
  }
}
