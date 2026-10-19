import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/models/title_summary.dart';
import '../domain/library_entry.dart';
import '../domain/watch_status.dart';

class LibraryDao {
  LibraryDao(this._db);

  final AppDatabase _db;

  static const String _fieldSep = '\u001f';
  static const String _rowSep = '\u001e';

  static const String _entriesSql = '''
SELECT li.*,
  (SELECT group_concat(g.genre_id || char(31) || g.genre_name, char(30))
     FROM item_genres g WHERE g.item_id = li.id) AS genre_list,
  (SELECT COUNT(*) FROM watched_episodes w
     WHERE w.item_id = li.id) AS watched_episode_count,
  (SELECT COALESCE(SUM(s.episode_count), 0) FROM tv_seasons s
     WHERE s.item_id = li.id) AS total_episode_count,
  (SELECT w.season_number FROM watched_episodes w WHERE w.item_id = li.id
     ORDER BY w.season_number DESC, w.episode_number DESC LIMIT 1) AS last_season,
  (SELECT w.episode_number FROM watched_episodes w WHERE w.item_id = li.id
     ORDER BY w.season_number DESC, w.episode_number DESC LIMIT 1) AS last_episode
FROM library_items li
''';

  Stream<List<LibraryEntry>> watchEntries() => _db
      .customSelect(
        _entriesSql,
        readsFrom: {
          _db.libraryItems,
          _db.itemGenres,
          _db.watchedEpisodes,
          _db.tvSeasons,
        },
      )
      .watch()
      .map((rows) => rows.map(_mapEntry).toList());

  LibraryEntry _mapEntry(QueryRow row) => LibraryEntry(
        item: _db.libraryItems.map(row.data),
        genres: _parseGenres(row.readNullable<String>('genre_list')),
        watchedEpisodeCount: row.read<int>('watched_episode_count'),
        totalEpisodeCount: row.read<int>('total_episode_count'),
        lastSeason: row.readNullable<int>('last_season'),
        lastEpisode: row.readNullable<int>('last_episode'),
      );

  static List<Genre> _parseGenres(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final genres = <Genre>[];
    for (final part in raw.split(_rowSep)) {
      final idx = part.indexOf(_fieldSep);
      if (idx <= 0) continue;
      final id = int.tryParse(part.substring(0, idx));
      if (id != null) genres.add(Genre(id, part.substring(idx + 1)));
    }
    return genres;
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

  Future<void> remove(int id) =>
      (_db.delete(_db.libraryItems)..where((t) => t.id.equals(id))).go();

  Future<void> _update(int id, LibraryItemsCompanion companion) =>
      (_db.update(_db.libraryItems)..where((t) => t.id.equals(id)))
          .write(companion);
}
