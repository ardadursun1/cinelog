import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';

class LibraryDao {
  LibraryDao(this._db);

  final AppDatabase _db;

  /// Streams all library entries using 4 flat queries merged in O(N) memory
  /// instead of N*6 correlated SQL subqueries.
  Stream<List<LibraryEntry>> watchEntries() async* {
    yield await _loadEntries();
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.libraryItems,
        _db.itemGenres,
        _db.tvSeasons,
        _db.watchedEpisodes,
      ]),
    );
    await for (final _ in updates) {
      yield await _loadEntries();
    }
  }

  Future<List<LibraryEntry>> _loadEntries() async {
    final items = await _db.select(_db.libraryItems).get();
    if (items.isEmpty) return const [];

    final results = await Future.wait([
      _db.select(_db.itemGenres).get(),
      (_db.select(_db.tvSeasons)
            ..orderBy([
              (t) => OrderingTerm.asc(t.itemId),
              (t) => OrderingTerm.asc(t.seasonNumber),
            ]))
          .get(),
      _db.select(_db.watchedEpisodes).get(),
    ]);

    final genreRows = results[0] as List<ItemGenre>;
    final seasonRows = results[1] as List<TvSeason>;
    final episodeRows = results[2] as List<WatchedEpisode>;

    final genresByItem = <int, List<Genre>>{};
    for (final g in genreRows) {
      (genresByItem[g.itemId] ??= []).add(Genre(g.genreId, g.genreName));
    }

    final seasonsByItem = <int, List<(int, int)>>{};
    final totalEpByItem = <int, int>{};
    for (final s in seasonRows) {
      if (s.seasonNumber > 0 && s.episodeCount > 0) {
        (seasonsByItem[s.itemId] ??= []).add((s.seasonNumber, s.episodeCount));
        totalEpByItem[s.itemId] =
            (totalEpByItem[s.itemId] ?? 0) + s.episodeCount;
      }
    }

    final watchedSetByItem = <int, Set<(int, int)>>{};
    final lastEpByItem = <int, (int, int)>{};
    for (final w in episodeRows) {
      final pair = (w.seasonNumber, w.episodeNumber);
      (watchedSetByItem[w.itemId] ??= {}).add(pair);
      final prev = lastEpByItem[w.itemId];
      if (prev == null ||
          pair.$1 > prev.$1 ||
          (pair.$1 == prev.$1 && pair.$2 > prev.$2)) {
        lastEpByItem[w.itemId] = pair;
      }
    }

    return [
      for (final item in items)
        LibraryEntry(
          item: item,
          genres: genresByItem[item.id] ?? const [],
          seasonCounts: seasonsByItem[item.id] ?? const [],
          watchedEpisodes: watchedSetByItem[item.id] ?? const {},
          watchedEpisodeCount: watchedSetByItem[item.id]?.length ?? 0,
          totalEpisodeCount: totalEpByItem[item.id] ?? 0,
          lastSeason: lastEpByItem[item.id]?.$1,
          lastEpisode: lastEpByItem[item.id]?.$2,
        ),
    ];
  }

  Stream<LibraryItem?> watchItem(TitleKey key) => (_db.select(_db.libraryItems)
        ..where((t) =>
            t.tmdbId.equals(key.tmdbId) &
            t.mediaType.equalsValue(key.mediaType)))
      .watchSingleOrNull();

  Future<LibraryItem?> findById(int id) =>
      (_db.select(_db.libraryItems)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<LibraryItem?> findByKey(TitleKey key) => (_db.select(_db.libraryItems)
        ..where((t) =>
            t.tmdbId.equals(key.tmdbId) &
            t.mediaType.equalsValue(key.mediaType)))
      .getSingleOrNull();

  /// Inserts the title with its genres. Returns the new item id.
  Future<int> add(TitleSummary summary, WatchStatus status) {
    final now = DateTime.now();
    return _db.transaction(() async {
      final id = await _db.into(_db.libraryItems).insert(
            LibraryItemsCompanion.insert(
              tmdbId: summary.tmdbId,
              mediaType: summary.mediaType,
              title: summary.title,
              originalTitle: Value(summary.originalTitle),
              posterPath: Value(summary.posterPath),
              overview: Value(summary.overview),
              releaseYear: Value(summary.releaseYear),
              runtimeMinutes: Value(summary.runtimeMinutes),
              status: status,
              addedAt: now,
              updatedAt: now,
              watchedAt: Value(status == WatchStatus.watched ? now : null),
            ),
          );
      await _db.batch((b) => b.insertAll(
            _db.itemGenres,
            [
              for (final g in summary.genres)
                ItemGenresCompanion.insert(
                  itemId: id,
                  genreId: g.id,
                  genreName: g.name,
                ),
            ],
            mode: InsertMode.insertOrIgnore,
          ));
      return id;
    });
  }

  Future<void> setStatus(int id, WatchStatus status) =>
      _db.transaction(() async {
        final item = await findById(id);
        if (item == null || item.status == status) return;
        final now = DateTime.now();
        await _update(
          id,
          LibraryItemsCompanion(
            status: Value(status),
            watchedAt: Value(
              status == WatchStatus.watched ? (item.watchedAt ?? now) : null,
            ),
            updatedAt: Value(now),
          ),
        );
        // Keep episode checkboxes consistent when a TV show is directly marked Watched.
        if (status == WatchStatus.watched && item.mediaType == MediaType.tv) {
          final seasons = await (_db.select(_db.tvSeasons)
                ..where((t) => t.itemId.equals(id)))
              .get();
          if (seasons.isNotEmpty) {
            await _db.batch(
              (b) => b.insertAll(
                _db.watchedEpisodes,
                [
                  for (final s in seasons)
                    for (var ep = 1; ep <= s.episodeCount; ep++)
                      WatchedEpisodesCompanion.insert(
                        itemId: id,
                        seasonNumber: s.seasonNumber,
                        episodeNumber: ep,
                        watchedAt: now,
                      ),
                ],
                mode: InsertMode.insertOrIgnore,
              ),
            );
          }
        }
      });

  Future<void> setRating(int id, int? rating) {
    if (rating != null && (rating < 1 || rating > 10)) {
      throw ArgumentError.value(rating, 'rating', 'must be between 1 and 10');
    }
    return _update(
      id,
      LibraryItemsCompanion(
        userRating: Value(rating),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setNote(int id, String? note) {
    final trimmed = note?.trim();
    if (trimmed != null && trimmed.length > kNoteMaxLength) {
      throw ArgumentError.value(note, 'note', 'too long');
    }
    return _update(
      id,
      LibraryItemsCompanion(
        note: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setRuntimeMinutes(int id, int? runtimeMinutes) {
    if (runtimeMinutes != null &&
        (runtimeMinutes <= 0 || runtimeMinutes > 1500)) {
      return Future.value();
    }
    return _update(
      id,
      LibraryItemsCompanion(
        runtimeMinutes: Value(runtimeMinutes),
      ),
    );
  }

  Future<void> remove(int id) =>
       (_db.delete(_db.libraryItems)..where((t) => t.id.equals(id))).go();

  Future<void> _update(int id, LibraryItemsCompanion companion) =>
      (_db.update(_db.libraryItems)..where((t) => t.id.equals(id)))
          .write(companion);
}
