import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../domain/models/manuscript_models.dart';
import '../../domain/repositories/manuscript_repository.dart';

class DriftManuscriptRepository implements ManuscriptRepository {
  final AppDatabase _db;

  DriftManuscriptRepository(this._db);

  VolumeModel _volumeToDomain(Volume row) {
    return VolumeModel(
      id: row.id,
      novelId: row.novelId,
      title: row.title,
      description: row.description,
      position: row.position,
      collapsed: row.collapsed,
    );
  }

  ArcModel _arcToDomain(Arc row) {
    return ArcModel(
      id: row.id,
      novelId: row.novelId,
      volumeId: row.volumeId,
      title: row.title,
      description: row.description,
      position: row.position,
      collapsed: row.collapsed,
    );
  }

  ChapterModel _chapterToDomain(Chapter row) {
    return ChapterModel(
      id: row.id,
      novelId: row.novelId,
      arcId: row.arcId,
      title: row.title,
      position: row.position,
      sequenceNumber: row.sequenceNumber,
      status: ChapterStatus.fromString(row.status),
      wordCount: row.wordCount,
      summary: row.summary,
      authorNote: row.authorNote,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  ChapterContentModel _contentToDomain(ChapterContent row) {
    return ChapterContentModel(
      chapterId: row.chapterId,
      deltaJson: row.deltaJson,
      plainText: row.plainText,
      wordCount: row.wordCount,
      charCount: row.charCount,
      formatVersion: row.formatVersion,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  @override
  Stream<List<VolumeModel>> watchVolumes(String novelId) {
    final query = _db.select(_db.volumes)
      ..where((tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]);
    return query.watch().map((rows) => rows.map(_volumeToDomain).toList());
  }

  @override
  Stream<List<ArcModel>> watchArcs(String novelId) {
    final query = _db.select(_db.arcs)
      ..where((tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]);
    return query.watch().map((rows) => rows.map(_arcToDomain).toList());
  }

  @override
  Stream<List<ChapterModel>> watchChapters(String novelId) {
    final query = _db.select(_db.chapters)
      ..where((tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull())
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sequenceNumber),
        (tbl) => OrderingTerm.asc(tbl.position),
      ]);
    return query.watch().map((rows) => rows.map(_chapterToDomain).toList());
  }

  @override
  Stream<ChapterModel?> watchChapter(String chapterId) {
    final query = _db.select(_db.chapters)
      ..where((tbl) => tbl.id.equals(chapterId) & tbl.deletedAt.isNull());
    return query
        .watchSingleOrNull()
        .map((row) => row != null ? _chapterToDomain(row) : null);
  }

  @override
  Future<ChapterModel?> getChapter(String chapterId) async {
    final query = _db.select(_db.chapters)
      ..where((tbl) => tbl.id.equals(chapterId) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _chapterToDomain(row) : null;
  }

  @override
  Future<VolumeModel> createVolume(String novelId, String title) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();
    final existingVolumes = await (_db.select(_db.volumes)
          ..where((tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull()))
        .get();

    final position = existingVolumes.length;

    await _db.into(_db.volumes).insert(
          VolumesCompanion(
            id: Value(id),
            novelId: Value(novelId),
            title: Value(title.trim()),
            position: Value(position),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final row = await (_db.select(_db.volumes)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    return _volumeToDomain(row);
  }

  @override
  Future<ArcModel> createArc(
    String novelId,
    String volumeId,
    String title,
  ) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = generateUuid();
    final existingArcs = await (_db.select(_db.arcs)
          ..where((tbl) => tbl.volumeId.equals(volumeId) & tbl.deletedAt.isNull()))
        .get();

    final position = existingArcs.length;

    await _db.into(_db.arcs).insert(
          ArcsCompanion(
            id: Value(id),
            novelId: Value(novelId),
            volumeId: Value(volumeId),
            title: Value(title.trim()),
            position: Value(position),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final row =
        await (_db.select(_db.arcs)..where((tbl) => tbl.id.equals(id)))
            .getSingle();
    return _arcToDomain(row);
  }

  @override
  Future<ChapterModel> createChapter(
    String novelId, {
    String? arcId,
    String? title,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final chapterId = generateUuid();

    return await _db.transaction(() async {
      String targetArcId;

      if (arcId != null) {
        targetArcId = arcId;
      } else {
        // Find or create default Volume and Arc
        final existingVolumes = await (_db.select(_db.volumes)
              ..where(
                (tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull(),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
            .get();

        String volumeId;
        if (existingVolumes.isEmpty) {
          final vol = await createVolume(novelId, 'Volume 1');
          volumeId = vol.id;
        } else {
          volumeId = existingVolumes.first.id;
        }

        final existingArcs = await (_db.select(_db.arcs)
              ..where(
                (tbl) => tbl.volumeId.equals(volumeId) & tbl.deletedAt.isNull(),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
            .get();

        if (existingArcs.isEmpty) {
          final arc = await createArc(novelId, volumeId, 'Arc 1');
          targetArcId = arc.id;
        } else {
          targetArcId = existingArcs.first.id;
        }
      }

      // Compute next sequence number for this novel
      final allChapters = await (_db.select(_db.chapters)
            ..where(
              (tbl) => tbl.novelId.equals(novelId) & tbl.deletedAt.isNull(),
            ))
          .get();

      final sequenceNumber = allChapters.length + 1;
      final position = sequenceNumber - 1;

      // Insert Chapter
      await _db.into(_db.chapters).insert(
            ChaptersCompanion(
              id: Value(chapterId),
              novelId: Value(novelId),
              arcId: Value(targetArcId),
              title: Value(title?.trim() ?? ''),
              position: Value(position),
              sequenceNumber: Value(sequenceNumber),
              status: const Value('planned'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // Insert Initial Content
      await _db.into(_db.chapterContents).insert(
            ChapterContentsCompanion(
              chapterId: Value(chapterId),
              deltaJson: const Value(ChapterContentModel.defaultDelta),
              plainText: const Value(''),
              wordCount: const Value(0),
              charCount: const Value(0),
              updatedAt: Value(now),
            ),
          );

      // Update Novel chapter count
      await (_db.update(_db.novels)..where((tbl) => tbl.id.equals(novelId)))
          .write(
        NovelsCompanion(
          chapterCount: Value(allChapters.length + 1),
          updatedAt: Value(now),
        ),
      );

      final created = await getChapter(chapterId);
      return created!;
    });
  }

  @override
  Future<void> updateChapter(ChapterModel chapter) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.chapters)..where((tbl) => tbl.id.equals(chapter.id)))
        .write(
      ChaptersCompanion(
        title: Value(chapter.title),
        status: Value(chapter.status.name),
        summary: Value(chapter.summary),
        authorNote: Value(chapter.authorNote),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteChapter(String chapterId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final chapter = await getChapter(chapterId);
    if (chapter == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.chapters)
            ..where((tbl) => tbl.id.equals(chapterId)))
          .write(
        ChaptersCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Recompute novel stats
      final remainingChapters = await (_db.select(_db.chapters)
            ..where(
              (tbl) =>
                  tbl.novelId.equals(chapter.novelId) & tbl.deletedAt.isNull(),
            ))
          .get();

      final totalWords =
          remainingChapters.fold<int>(0, (sum, c) => sum + c.wordCount);

      await (_db.update(_db.novels)
            ..where((tbl) => tbl.id.equals(chapter.novelId)))
          .write(
        NovelsCompanion(
          chapterCount: Value(remainingChapters.length),
          totalWordCount: Value(totalWords),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<ChapterContentModel> getChapterContent(String chapterId) async {
    final query = _db.select(_db.chapterContents)
      ..where((tbl) => tbl.chapterId.equals(chapterId));
    final row = await query.getSingleOrNull();
    if (row != null) {
      return _contentToDomain(row);
    }
    return ChapterContentModel(
      chapterId: chapterId,
      deltaJson: ChapterContentModel.defaultDelta,
      plainText: '',
      wordCount: 0,
      charCount: 0,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Stream<ChapterContentModel?> watchChapterContent(String chapterId) {
    final query = _db.select(_db.chapterContents)
      ..where((tbl) => tbl.chapterId.equals(chapterId));
    return query
        .watchSingleOrNull()
        .map((row) => row != null ? _contentToDomain(row) : null);
  }

  @override
  Future<void> saveChapterContent(
    String chapterId, {
    required String deltaJson,
    required String plainText,
    required int wordCount,
    required int charCount,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final chapter = await getChapter(chapterId);
    if (chapter == null) return;

    await _db.transaction(() async {
      // 1. Update ChapterContents
      await (_db.into(_db.chapterContents).insertOnConflictUpdate(
            ChapterContentsCompanion(
              chapterId: Value(chapterId),
              deltaJson: Value(deltaJson),
              plainText: Value(plainText),
              wordCount: Value(wordCount),
              charCount: Value(charCount),
              updatedAt: Value(now),
            ),
          ));

      // 2. Update Chapter word count
      await (_db.update(_db.chapters)
            ..where((tbl) => tbl.id.equals(chapterId)))
          .write(
        ChaptersCompanion(
          wordCount: Value(wordCount),
          updatedAt: Value(now),
        ),
      );

      // 3. Update Novel total word count
      final remainingChapters = await (_db.select(_db.chapters)
            ..where(
              (tbl) =>
                  tbl.novelId.equals(chapter.novelId) & tbl.deletedAt.isNull(),
            ))
          .get();

      final totalWords = remainingChapters.fold<int>(0, (sum, c) {
        if (c.id == chapterId) {
          return sum + wordCount;
        }
        return sum + c.wordCount;
      });

      await (_db.update(_db.novels)
            ..where((tbl) => tbl.id.equals(chapter.novelId)))
          .write(
        NovelsCompanion(
          totalWordCount: Value(totalWords),
          updatedAt: Value(now),
        ),
      );
    });
  }
}
