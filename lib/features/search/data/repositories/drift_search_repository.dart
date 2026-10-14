import '../../../../core/database/app_database.dart';
import '../../domain/models/search_result_item.dart';
import '../../domain/repositories/search_repository.dart';

class DriftSearchRepository implements SearchRepository {
  final AppDatabase _db;

  DriftSearchRepository(this._db);

  String? _extractSnippet(String source, String query, {int radius = 45}) {
    if (source.isEmpty || query.isEmpty) return null;
    final idx = source.toLowerCase().indexOf(query.toLowerCase());
    if (idx == -1) return null;
    final start = (idx - radius).clamp(0, source.length);
    final end = (idx + query.length + radius).clamp(0, source.length);
    final prefix = start > 0 ? '…' : '';
    final suffix = end < source.length ? '…' : '';
    final chunk = source
        .substring(start, end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '$prefix$chunk$suffix';
  }

  @override
  Future<List<SearchResultItem>> search({
    required String query,
    SearchResultType typeFilter = SearchResultType.all,
    String? novelId,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];
    final lowerQ = cleanQuery.toLowerCase();

    // 1. Fetch novels to map novelId -> novelTitle and search novels themselves
    final novelsQuery = _db.select(_db.novels)
      ..where((tbl) => tbl.deletedAt.isNull());
    if (novelId != null) {
      novelsQuery.where((tbl) => tbl.id.equals(novelId));
    }
    final novelRows = await novelsQuery.get();
    final novelMap = {for (final n in novelRows) n.id: n};

    final results = <SearchResultItem>[];

    // Search Novels
    if (typeFilter == SearchResultType.all ||
        typeFilter == SearchResultType.novel) {
      for (final n in novelRows) {
        final titleMatch = n.title.toLowerCase().contains(lowerQ);
        final genreMatch = n.genre?.toLowerCase().contains(lowerQ) ?? false;
        final subMatch = n.subtitle?.toLowerCase().contains(lowerQ) ?? false;
        final descMatch = n.description?.toLowerCase().contains(lowerQ) ?? false;
        final authorMatch = n.author?.toLowerCase().contains(lowerQ) ?? false;

        if (titleMatch || genreMatch || subMatch || descMatch || authorMatch) {
          String? snippet;
          if (descMatch && n.description != null) {
            snippet = _extractSnippet(n.description!, cleanQuery);
          } else if (subMatch && n.subtitle != null) {
            snippet = n.subtitle;
          }

          results.add(
            SearchResultItem(
              id: n.id,
              type: SearchResultType.novel,
              title: n.title,
              subtitle: '${n.genre ?? 'Novel'} · ${n.chapterCount} chapters · ${n.totalWordCount} words',
              snippet: snippet,
              novelId: n.id,
              novelTitle: n.title,
              tag: n.genre,
              coverPath: n.coverPath,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(n.updatedAt, isUtc: true),
            ),
          );
        }
      }
    }

    // Search Chapters
    if (typeFilter == SearchResultType.all ||
        typeFilter == SearchResultType.chapter) {
      final chaptersQuery = _db.select(_db.chapters)
        ..where((tbl) => tbl.deletedAt.isNull());
      if (novelId != null) {
        chaptersQuery.where((tbl) => tbl.novelId.equals(novelId));
      }
      final chapterRows = await chaptersQuery.get();

      // Check contents if needed
      final contentRows = await (_db.select(_db.chapterContents)).get();
      final contentMap = {for (final c in contentRows) c.chapterId: c.plainText};

      for (final ch in chapterRows) {
        final parentNovel = novelMap[ch.novelId];
        final titleMatch = ch.title.toLowerCase().contains(lowerQ);
        final summaryMatch = ch.summary?.toLowerCase().contains(lowerQ) ?? false;
        final noteMatch = ch.authorNote?.toLowerCase().contains(lowerQ) ?? false;
        final chNoteMatch = ch.chapterNote?.toLowerCase().contains(lowerQ) ?? false;

        final bodyText = contentMap[ch.id] ?? '';
        final bodyMatch = bodyText.toLowerCase().contains(lowerQ);

        if (titleMatch || summaryMatch || noteMatch || chNoteMatch || bodyMatch) {
          String? snippet;
          if (titleMatch) {
            snippet = ch.summary;
          } else if (summaryMatch && ch.summary != null) {
            snippet = _extractSnippet(ch.summary!, cleanQuery);
          } else if (bodyMatch && bodyText.isNotEmpty) {
            snippet = _extractSnippet(bodyText, cleanQuery);
          } else if (noteMatch && ch.authorNote != null) {
            snippet = _extractSnippet(ch.authorNote!, cleanQuery);
          }

          final chapterDisplayTitle = ch.title.isNotEmpty
              ? (ch.sequenceNumber > 0
                  ? 'Chapter ${ch.sequenceNumber}: ${ch.title}'
                  : ch.title)
              : 'Chapter ${ch.sequenceNumber > 0 ? ch.sequenceNumber : ''}';

          results.add(
            SearchResultItem(
              id: ch.id,
              type: SearchResultType.chapter,
              title: chapterDisplayTitle,
              subtitle: parentNovel != null
                  ? 'in ${parentNovel.title} · ${ch.wordCount} words'
                  : '${ch.wordCount} words',
              snippet: snippet,
              novelId: ch.novelId,
              novelTitle: parentNovel?.title,
              tag: ch.status,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(ch.updatedAt, isUtc: true),
            ),
          );
        }
      }
    }

    // Search Characters
    if (typeFilter == SearchResultType.all ||
        typeFilter == SearchResultType.character) {
      final charactersQuery = _db.select(_db.characters)
        ..where((tbl) => tbl.deletedAt.isNull());
      if (novelId != null) {
        charactersQuery.where((tbl) => tbl.novelId.equals(novelId));
      }
      final characterRows = await charactersQuery.get();

      for (final c in characterRows) {
        final parentNovel = novelMap[c.novelId];
        final nameMatch = c.name.toLowerCase().contains(lowerQ);
        final nickMatch = c.nickname?.toLowerCase().contains(lowerQ) ?? false;
        final roleMatch = c.role.toLowerCase().contains(lowerQ);
        final appMatch = c.appearance?.toLowerCase().contains(lowerQ) ?? false;
        final persMatch = c.personality?.toLowerCase().contains(lowerQ) ?? false;
        final goalMatch = c.goal?.toLowerCase().contains(lowerQ) ?? false;
        final backMatch = c.backstory?.toLowerCase().contains(lowerQ) ?? false;
        final notesMatch = c.notes?.toLowerCase().contains(lowerQ) ?? false;
        final flawMatch = c.flaw?.toLowerCase().contains(lowerQ) ?? false;

        if (nameMatch ||
            nickMatch ||
            roleMatch ||
            appMatch ||
            persMatch ||
            goalMatch ||
            backMatch ||
            notesMatch ||
            flawMatch) {
          String? snippet;
          if (backMatch && c.backstory != null) {
            snippet = _extractSnippet(c.backstory!, cleanQuery);
          } else if (goalMatch && c.goal != null) {
            snippet = 'Goal: ${_extractSnippet(c.goal!, cleanQuery) ?? c.goal}';
          } else if (appMatch && c.appearance != null) {
            snippet = 'Appearance: ${_extractSnippet(c.appearance!, cleanQuery) ?? c.appearance}';
          } else if (persMatch && c.personality != null) {
            snippet = 'Personality: ${_extractSnippet(c.personality!, cleanQuery) ?? c.personality}';
          } else if (notesMatch && c.notes != null) {
            snippet = _extractSnippet(c.notes!, cleanQuery);
          } else if (c.goal != null && c.goal!.isNotEmpty) {
            snippet = c.goal;
          }

          final charName = c.nickname != null && c.nickname!.isNotEmpty
              ? '${c.name} ("${c.nickname}")'
              : c.name;

          results.add(
            SearchResultItem(
              id: c.id,
              type: SearchResultType.character,
              title: charName,
              subtitle: parentNovel != null
                  ? 'in ${parentNovel.title} · ${c.role}'
                  : c.role,
              snippet: snippet,
              novelId: c.novelId,
              novelTitle: parentNovel?.title,
              tag: c.role,
              coverPath: c.portraitPath,
              updatedAt: c.updatedAt > 0
                  ? DateTime.fromMillisecondsSinceEpoch(c.updatedAt, isUtc: true)
                  : null,
            ),
          );
        }
      }
    }

    // Search Lore / World Entries
    if (typeFilter == SearchResultType.all ||
        typeFilter == SearchResultType.lore) {
      final entriesQuery = _db.select(_db.worldEntries)
        ..where((tbl) => tbl.deletedAt.isNull());
      if (novelId != null) {
        entriesQuery.where((tbl) => tbl.novelId.equals(novelId));
      }
      final entryRows = await entriesQuery.get();

      // Categories map for category names
      final categoryRows = await (_db.select(_db.worldCategories)).get();
      final categoryMap = {for (final cat in categoryRows) cat.id: cat.name};

      // Also search section content
      final sectionRows = await (_db.select(_db.worldEntrySections)).get();
      final sectionMap = <String, List<WorldEntrySection>>{};
      for (final s in sectionRows) {
        sectionMap.putIfAbsent(s.entryId, () => []).add(s);
      }

      for (final e in entryRows) {
        final parentNovel = novelMap[e.novelId];
        final catName = categoryMap[e.categoryId] ?? 'World';

        final nameMatch = e.name.toLowerCase().contains(lowerQ);
        final subMatch = e.subtitle?.toLowerCase().contains(lowerQ) ?? false;
        final sumMatch = e.summary?.toLowerCase().contains(lowerQ) ?? false;

        String? matchedSectionText;
        final sections = sectionMap[e.id] ?? const [];
        for (final sec in sections) {
          if (sec.heading.toLowerCase().contains(lowerQ) ||
              (sec.body?.toLowerCase().contains(lowerQ) ?? false)) {
            matchedSectionText = sec.body ?? sec.heading;
            break;
          }
        }

        if (nameMatch || subMatch || sumMatch || matchedSectionText != null) {
          String? snippet;
          if (sumMatch && e.summary != null) {
            snippet = _extractSnippet(e.summary!, cleanQuery);
          } else if (matchedSectionText != null) {
            snippet = _extractSnippet(matchedSectionText, cleanQuery);
          } else if (subMatch && e.subtitle != null) {
            snippet = e.subtitle;
          } else if (e.summary != null) {
            snippet = e.summary;
          }

          results.add(
            SearchResultItem(
              id: e.id,
              type: SearchResultType.lore,
              title: e.name,
              subtitle: parentNovel != null
                  ? 'in ${parentNovel.title} · $catName'
                  : catName,
              snippet: snippet,
              novelId: e.novelId,
              novelTitle: parentNovel?.title,
              tag: catName,
              coverPath: e.coverPath,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt, isUtc: true),
            ),
          );
        }
      }
    }

    // Search Timeline Events
    if (typeFilter == SearchResultType.all ||
        typeFilter == SearchResultType.event) {
      final eventsQuery = _db.select(_db.events)
        ..where((tbl) => tbl.deletedAt.isNull());
      if (novelId != null) {
        eventsQuery.where((tbl) => tbl.novelId.equals(novelId));
      }
      final eventRows = await eventsQuery.get();

      for (final ev in eventRows) {
        final parentNovel = novelMap[ev.novelId];
        final titleMatch = ev.title.toLowerCase().contains(lowerQ);
        final descMatch = ev.description?.toLowerCase().contains(lowerQ) ?? false;
        final notesMatch = ev.notes?.toLowerCase().contains(lowerQ) ?? false;
        final dateMatch = ev.dateText?.toLowerCase().contains(lowerQ) ?? false;

        if (titleMatch || descMatch || notesMatch || dateMatch) {
          String? snippet;
          if (descMatch && ev.description != null) {
            snippet = _extractSnippet(ev.description!, cleanQuery);
          } else if (notesMatch && ev.notes != null) {
            snippet = _extractSnippet(ev.notes!, cleanQuery);
          } else if (ev.description != null) {
            snippet = ev.description;
          }

          results.add(
            SearchResultItem(
              id: ev.id,
              type: SearchResultType.event,
              title: ev.title,
              subtitle: parentNovel != null
                  ? 'in ${parentNovel.title}${ev.dateText != null ? ' · ${ev.dateText}' : ''}'
                  : ev.dateText,
              snippet: snippet,
              novelId: ev.novelId,
              novelTitle: parentNovel?.title,
              tag: 'Timeline',
              updatedAt: DateTime.fromMillisecondsSinceEpoch(ev.updatedAt, isUtc: true),
            ),
          );
        }
      }
    }

    // Search Scenes
    if (typeFilter == SearchResultType.all ||
        typeFilter == SearchResultType.scene) {
      final scenesQuery = _db.select(_db.scenes)
        ..where((tbl) => tbl.deletedAt.isNull());
      if (novelId != null) {
        scenesQuery.where((tbl) => tbl.novelId.equals(novelId));
      }
      final sceneRows = await scenesQuery.get();

      for (final sc in sceneRows) {
        final parentNovel = novelMap[sc.novelId];
        final titleMatch = sc.title.toLowerCase().contains(lowerQ);
        final purpMatch = sc.purpose?.toLowerCase().contains(lowerQ) ?? false;
        final dqMatch = sc.dramaticQuestion?.toLowerCase().contains(lowerQ) ?? false;
        final notesMatch = sc.notes?.toLowerCase().contains(lowerQ) ?? false;

        if (titleMatch || purpMatch || dqMatch || notesMatch) {
          String? snippet;
          if (dqMatch && sc.dramaticQuestion != null) {
            snippet = 'Dramatic Question: ${_extractSnippet(sc.dramaticQuestion!, cleanQuery) ?? sc.dramaticQuestion}';
          } else if (purpMatch && sc.purpose != null) {
            snippet = 'Purpose: ${_extractSnippet(sc.purpose!, cleanQuery) ?? sc.purpose}';
          } else if (notesMatch && sc.notes != null) {
            snippet = _extractSnippet(sc.notes!, cleanQuery);
          } else if (sc.purpose != null) {
            snippet = sc.purpose;
          }

          results.add(
            SearchResultItem(
              id: sc.id,
              type: SearchResultType.scene,
              title: sc.title,
              subtitle: parentNovel != null
                  ? 'in ${parentNovel.title} · Scene'
                  : 'Scene',
              snippet: snippet,
              novelId: sc.novelId,
              novelTitle: parentNovel?.title,
              tag: 'Scene',
              updatedAt: DateTime.fromMillisecondsSinceEpoch(sc.updatedAt, isUtc: true),
            ),
          );
        }
      }
    }

    return results;
  }

  @override
  Future<Set<String>> searchMatchingNovelIds(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const {};
    final lowerQ = cleanQuery.toLowerCase();
    final matchedNovelIds = <String>{};

    // 1. Check novels
    final novels = await (_db.select(_db.novels)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    for (final n in novels) {
      if (n.title.toLowerCase().contains(lowerQ) ||
          (n.genre?.toLowerCase().contains(lowerQ) ?? false) ||
          (n.subtitle?.toLowerCase().contains(lowerQ) ?? false) ||
          (n.description?.toLowerCase().contains(lowerQ) ?? false)) {
        matchedNovelIds.add(n.id);
      }
    }

    // 2. Check chapters
    final chapters = await (_db.select(_db.chapters)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    for (final c in chapters) {
      if (c.title.toLowerCase().contains(lowerQ) ||
          (c.summary?.toLowerCase().contains(lowerQ) ?? false)) {
        matchedNovelIds.add(c.novelId);
      }
    }

    // 3. Check characters
    final characters = await (_db.select(_db.characters)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    for (final ch in characters) {
      if (ch.name.toLowerCase().contains(lowerQ) ||
          (ch.nickname?.toLowerCase().contains(lowerQ) ?? false) ||
          ch.role.toLowerCase().contains(lowerQ)) {
        matchedNovelIds.add(ch.novelId);
      }
    }

    // 4. Check world entries
    final entries = await (_db.select(_db.worldEntries)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    for (final e in entries) {
      if (e.name.toLowerCase().contains(lowerQ) ||
          (e.summary?.toLowerCase().contains(lowerQ) ?? false)) {
        matchedNovelIds.add(e.novelId);
      }
    }

    return matchedNovelIds;
  }
}
