import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/tmdb_models.dart';
import '../../library/data/library_dao.dart';
import '../../library/domain/watch_status.dart';

typedef EpisodeRef = (int season, int episode);

class EpisodeDao {
  EpisodeDao(this._db, this._library);

  final AppDatabase _db;
  final LibraryDao _library;

  Stream<List<TvSeason>> watchSeasons(int itemId) => (_db.select(_db.tvSeasons)
        ..where((t) => t.itemId.equals(itemId))
        ..orderBy([(t) => OrderingTerm.asc(t.seasonNumber)]))
      .watch();

  Stream<Set<EpisodeRef>> watchWatched(int itemId) =>
      (_db.select(_db.watchedEpisodes)..where((t) => t.itemId.equals(itemId)))
          .watch()
          .map((rows) => {
                for (final r in rows) (r.seasonNumber, r.episodeNumber),
              });

  /// Upserts seasons from TMDB and drops seasons TMDB no longer lists.
  /// Watched-episode history is intentionally kept.
  Future<void> replaceSeasons(int itemId, List<SeasonInfo> seasons) =>
      _db.transaction(() async {
        final numbers = seasons.map((s) => s.number).toList();
        await (_db.delete(_db.tvSeasons)
              ..where((t) =>
                  t.itemId.equals(itemId) & t.seasonNumber.isNotIn(numbers)))
            .go();
        await _db.batch((b) => b.insertAllOnConflictUpdate(_db.tvSeasons, [
              for (final s in seasons)
                TvSeasonsCompanion.insert(
                  itemId: itemId,
                  seasonNumber: s.number,
                  episodeCount: s.episodeCount,
                  name: Value(s.name),
                ),
            ]));
      });

  Future<void> setEpisode(int itemId, EpisodeRef ep, {required bool watched}) =>
      _db.transaction(() async {
        if (watched) {
          await _insertEpisodes(itemId, [ep]);
        } else {
          await (_db.delete(_db.watchedEpisodes)
                ..where((t) =>
                    t.itemId.equals(itemId) &
                    t.seasonNumber.equals(ep.$1) &
                    t.episodeNumber.equals(ep.$2)))
              .go();
        }
        await _syncStatus(itemId, unmarked: !watched);
      });

  Future<void> setSeason(int itemId, int season, {required bool watched}) =>
      _db.transaction(() async {
        if (watched) {
          final seasons = await _seasons(itemId);
          final info = seasons.where((s) => s.seasonNumber == season);
          if (info.isEmpty) return;
          await _insertEpisodes(itemId, [
            for (var e = 1; e <= info.first.episodeCount; e++) (season, e),
          ]);
        } else {
          await (_db.delete(_db.watchedEpisodes)
                ..where((t) =>
                    t.itemId.equals(itemId) & t.seasonNumber.equals(season)))
              .go();
        }
        await _syncStatus(itemId, unmarked: !watched);
      });

  /// Marks every episode up to and including [until] as watched.
  Future<void> markUpTo(int itemId, EpisodeRef until) =>
      _db.transaction(() async {
        final seasons = await _seasons(itemId);
        await _insertEpisodes(itemId, [
          for (final s in seasons)
            if (s.seasonNumber < until.$1)
              for (var e = 1; e <= s.episodeCount; e++) (s.seasonNumber, e)
            else if (s.seasonNumber == until.$1)
              for (var e = 1; e <= until.$2 && e <= s.episodeCount; e++)
                (s.seasonNumber, e),
        ]);
        await _syncStatus(itemId, unmarked: false);
      });

  Future<void> markAll(int itemId) => _db.transaction(() async {
        final seasons = await _seasons(itemId);
        await _insertEpisodes(itemId, [
          for (final s in seasons)
            for (var e = 1; e <= s.episodeCount; e++) (s.seasonNumber, e),
        ]);
        await _syncStatus(itemId, unmarked: false);
      });

  Future<List<TvSeason>> _seasons(int itemId) =>
      (_db.select(_db.tvSeasons)..where((t) => t.itemId.equals(itemId))).get();

  Future<void> _insertEpisodes(int itemId, List<EpisodeRef> episodes) {
    if (episodes.isEmpty) return Future.value();
    final now = DateTime.now();
    return _db.batch((b) => b.insertAll(
          _db.watchedEpisodes,
          [
            for (final (s, e) in episodes)
              WatchedEpisodesCompanion.insert(
                itemId: itemId,
                seasonNumber: s,
                episodeNumber: e,
                watchedAt: now,
              ),
          ],
          mode: InsertMode.insertOrIgnore,
        ));
  }

  /// - All episodes watched → "watched".
  /// - First episode marked on a planned title → "watching".
  /// - Episode unmarked on a watched title → "watching".
  Future<void> _syncStatus(int itemId, {required bool unmarked}) async {
    final item = await _library.findById(itemId);
    if (item == null) return;
    final row = await _db.customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM watched_episodes WHERE item_id = ?1) AS watched, '
      '(SELECT COALESCE(SUM(episode_count), 0) FROM tv_seasons '
      'WHERE item_id = ?1) AS total',
      variables: [Variable.withInt(itemId)],
    ).getSingle();
    final watched = row.read<int>('watched');
    final total = row.read<int>('total');

    WatchStatus? next;
    if (total > 0 && watched >= total) {
      next = WatchStatus.watched;
    } else if (!unmarked && watched > 0 && item.status == WatchStatus.planned) {
      next = WatchStatus.watching;
    } else if (unmarked && item.status == WatchStatus.watched) {
      next = WatchStatus.watching;
    }
    if (next != null) await _library.setStatus(itemId, next);
  }
}
