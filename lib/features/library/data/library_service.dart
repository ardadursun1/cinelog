import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/settings_dao.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../episodes/data/episode_dao.dart';
import '../domain/watch_status.dart';
import 'library_dao.dart';

class AddResult {
  const AddResult(this.itemId, {this.seasonError});

  final int itemId;

  /// Set when the title was saved but TV season info could not be fetched.
  final TmdbException? seasonError;
}

class RemovedLibrarySnapshot {
  const RemovedLibrarySnapshot({
    required this.item,
    required this.genres,
    required this.seasons,
    required this.episodes,
    required this.wasFavorite,
  });

  final LibraryItem item;
  final List<ItemGenre> genres;
  final List<TvSeason> seasons;
  final List<WatchedEpisode> episodes;
  final bool wasFavorite;
}

enum QuickStatusOutcome { added, updated, removed }

class QuickStatusResult {
  const QuickStatusResult({
    required this.outcome,
    this.removedSnapshot,
    this.seasonError,
  });

  final QuickStatusOutcome outcome;
  final RemovedLibrarySnapshot? removedSnapshot;
  final TmdbException? seasonError;
}

/// Coordinates library writes that also need TMDB (e.g. TV seasons) or
/// multi-table snapshots.
class LibraryService {
  LibraryService(this._db, this._library, this._episodes, this._client);

  final AppDatabase _db;
  final LibraryDao _library;
  final EpisodeDao _episodes;
  final TmdbClient? Function() _client;

  Future<AddResult> add(TitleSummary summary, WatchStatus status) async {
    final id = await _library.add(summary, status);
    if (summary.mediaType != MediaType.tv) return AddResult(id);
    try {
      await refreshSeasons(id, summary.tmdbId);
      if (status == WatchStatus.watched) {
        await _episodes.markAll(id);
      }
      return AddResult(id);
    } on TmdbException catch (e) {
      return AddResult(id, seasonError: e);
    }
  }

  Future<AddResult> setOrAddStatus(
    TitleSummary summary,
    WatchStatus status,
  ) async {
    final existing = await _library.findByKey(summary.key);
    if (existing != null) {
      await _library.setStatus(existing.id, status);
      return AddResult(existing.id);
    }
    return add(summary, status);
  }

  /// Adds the title if absent, switches its status if different, or removes it
  /// (returning a full undo snapshot) when [targetStatus] is clicked a second time.
  Future<QuickStatusResult> toggleQuickStatus(
    TitleSummary summary,
    WatchStatus targetStatus,
  ) async {
    final existing = await _library.findByKey(summary.key);
    if (existing == null) {
      final res = await add(summary, targetStatus);
      return QuickStatusResult(
        outcome: QuickStatusOutcome.added,
        seasonError: res.seasonError,
      );
    }
    if (existing.status != targetStatus) {
      await _library.setStatus(existing.id, targetStatus);
      return const QuickStatusResult(outcome: QuickStatusOutcome.updated);
    }
    final snapshot = await removeWithSnapshot(existing.id);
    return QuickStatusResult(
      outcome: QuickStatusOutcome.removed,
      removedSnapshot: snapshot,
    );
  }

  /// Atomically removes an item (and its favorite flag, if set) while returning
  /// a complete snapshot so the action can be undone without data loss.
  Future<RemovedLibrarySnapshot?> removeWithSnapshot(int itemId) =>
      _db.transaction(() async {
        final item = await _library.findById(itemId);
        if (item == null) return null;

        final genres = await (_db.select(_db.itemGenres)
              ..where((t) => t.itemId.equals(itemId)))
            .get();
        final seasons = await (_db.select(_db.tvSeasons)
              ..where((t) => t.itemId.equals(itemId)))
            .get();
        final episodes = await (_db.select(_db.watchedEpisodes)
              ..where((t) => t.itemId.equals(itemId)))
            .get();

        final key = (tmdbId: item.tmdbId, mediaType: item.mediaType);
        final favRow = await (_db.select(_db.appSettings)
              ..where((t) => t.name.equals(SettingKeys.favoriteTitles)))
            .getSingleOrNull();
        final favorites =
            Set<TitleKey>.of(parseFavoriteTitleKeys(favRow?.value));
        final wasFavorite = favorites.remove(key);

        await _library.remove(itemId);
        if (wasFavorite) {
          await _writeFavorites(favorites);
        }

        return RemovedLibrarySnapshot(
          item: item,
          genres: genres,
          seasons: seasons,
          episodes: episodes,
          wasFavorite: wasFavorite,
        );
      });

  Future<void> restoreRemoved(RemovedLibrarySnapshot snapshot) =>
      _db.transaction(() async {
        final src = snapshot.item;
        final key = (tmdbId: src.tmdbId, mediaType: src.mediaType);
        final existing = await _library.findByKey(key);

        final int targetId;
        if (existing != null) {
          targetId = existing.id;
          await (_db.update(_db.libraryItems)
                ..where((t) => t.id.equals(targetId)))
              .write(
            LibraryItemsCompanion(
              title: Value(src.title),
              originalTitle: Value(src.originalTitle),
              posterPath: Value(src.posterPath),
              overview: Value(src.overview),
              releaseYear: Value(src.releaseYear),
              runtimeMinutes: Value(src.runtimeMinutes),
              status: Value(src.status),
              userRating: Value(src.userRating),
              note: Value(src.note),
              addedAt: Value(src.addedAt),
              updatedAt: Value(DateTime.now()),
              watchedAt: Value(src.watchedAt),
            ),
          );
        } else {
          targetId = await _db.into(_db.libraryItems).insert(
                LibraryItemsCompanion.insert(
                  tmdbId: src.tmdbId,
                  mediaType: src.mediaType,
                  title: src.title,
                  originalTitle: Value(src.originalTitle),
                  posterPath: Value(src.posterPath),
                  overview: Value(src.overview),
                  releaseYear: Value(src.releaseYear),
                  runtimeMinutes: Value(src.runtimeMinutes),
                  status: src.status,
                  userRating: Value(src.userRating),
                  note: Value(src.note),
                  addedAt: src.addedAt,
                  updatedAt: src.updatedAt,
                  watchedAt: Value(src.watchedAt),
                ),
              );
        }

        await _db.batch((b) {
          if (snapshot.genres.isNotEmpty) {
            b.insertAll(
              _db.itemGenres,
              [
                for (final g in snapshot.genres)
                  ItemGenresCompanion.insert(
                    itemId: targetId,
                    genreId: g.genreId,
                    genreName: g.genreName,
                  ),
              ],
              mode: InsertMode.insertOrReplace,
            );
          }
          if (snapshot.seasons.isNotEmpty) {
            b.insertAllOnConflictUpdate(_db.tvSeasons, [
              for (final s in snapshot.seasons)
                TvSeasonsCompanion.insert(
                  itemId: targetId,
                  seasonNumber: s.seasonNumber,
                  episodeCount: s.episodeCount,
                  name: Value(s.name),
                ),
            ]);
          }
          if (snapshot.episodes.isNotEmpty) {
            b.insertAll(
              _db.watchedEpisodes,
              [
                for (final e in snapshot.episodes)
                  WatchedEpisodesCompanion.insert(
                    itemId: targetId,
                    seasonNumber: e.seasonNumber,
                    episodeNumber: e.episodeNumber,
                    watchedAt: e.watchedAt,
                  ),
              ],
              mode: InsertMode.insertOrIgnore,
            );
          }
        });

        if (snapshot.wasFavorite) {
          final favRow = await (_db.select(_db.appSettings)
                ..where((t) => t.name.equals(SettingKeys.favoriteTitles)))
              .getSingleOrNull();
          final favorites =
              Set<TitleKey>.of(parseFavoriteTitleKeys(favRow?.value));
          if (favorites.add(key)) {
            await _writeFavorites(favorites);
          }
        }
      });

  Future<void> _writeFavorites(Set<TitleKey> favorites) async {
    if (favorites.isEmpty) {
      await (_db.delete(_db.appSettings)
            ..where((t) => t.name.equals(SettingKeys.favoriteTitles)))
          .go();
      return;
    }
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            name: SettingKeys.favoriteTitles,
            value: serializeFavoriteTitleKeys(favorites),
          ),
        );
  }

  /// Silently removes an auto-created `planned` entry when the user un-favorites
  /// a title right after favoriting it, provided no rating/note/episodes exist.
  Future<void> removeIfUnmodifiedPlanned(TitleKey key) =>
      _db.transaction(() async {
        final item = await _library.findByKey(key);
        if (item == null ||
            item.status != WatchStatus.planned ||
            item.userRating != null ||
            (item.note != null && item.note!.isNotEmpty)) {
          return;
        }
        final hasEpisodes = await (_db.select(_db.watchedEpisodes)
              ..where((t) => t.itemId.equals(item.id))
              ..limit(1))
            .getSingleOrNull();
        if (hasEpisodes != null) return;
        await _library.remove(item.id);
      });

  Future<void> refreshSeasons(int itemId, int tmdbId) async {
    final client = _client();
    if (client == null) {
      throw const TmdbException(TmdbErrorKind.missingKey);
    }
    final seasons = await client.fetchTvSeasons(tmdbId);
    await _episodes.replaceSeasons(itemId, seasons);
  }
}
