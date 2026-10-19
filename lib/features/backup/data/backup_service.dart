import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/settings_dao.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_models.dart';
import '../../../core/settings/app_settings_providers.dart';
import 'backup_codec.dart';

class ImportResult {
  const ImportResult({
    required this.inserted,
    required this.updated,
    required this.errors,
  });

  final int inserted;
  final int updated;
  final List<String> errors;
}

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<Set<TitleKey>> _readFavorites() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.name.equals(SettingKeys.favoriteTitles)))
        .getSingleOrNull();
    return parseFavoriteTitleKeys(row?.value);
  }

  Future<List<BackupItem>> _readAll() async {
    final items = await _db.select(_db.libraryItems).get();
    final genres = await _db.select(_db.itemGenres).get();
    final seasons = await _db.select(_db.tvSeasons).get();
    final episodes = await _db.select(_db.watchedEpisodes).get();
    final favorites = await _readFavorites();

    final genresBy = <int, List<Genre>>{};
    for (final g in genres) {
      (genresBy[g.itemId] ??= []).add(Genre(g.genreId, g.genreName));
    }
    final seasonsBy = <int, List<SeasonInfo>>{};
    for (final s in seasons) {
      (seasonsBy[s.itemId] ??= []).add(SeasonInfo(
        number: s.seasonNumber,
        episodeCount: s.episodeCount,
        name: s.name,
      ));
    }
    final episodesBy = <int, List<BackupEpisode>>{};
    for (final e in episodes) {
      (episodesBy[e.itemId] ??= [])
          .add(BackupEpisode(e.seasonNumber, e.episodeNumber, e.watchedAt));
    }

    return [
      for (final i in items)
        BackupItem(
          tmdbId: i.tmdbId,
          mediaType: i.mediaType,
          title: i.title,
          originalTitle: i.originalTitle,
          posterPath: i.posterPath,
          overview: i.overview,
          releaseYear: i.releaseYear,
          status: i.status,
          userRating: i.userRating,
          note: i.note,
          isFavorite: favorites.contains(
            (tmdbId: i.tmdbId, mediaType: i.mediaType),
          ),
          addedAt: i.addedAt,
          updatedAt: i.updatedAt,
          watchedAt: i.watchedAt,
          genres: genresBy[i.id] ?? const [],
          seasons: seasonsBy[i.id] ?? const [],
          episodes: episodesBy[i.id] ?? const [],
        ),
    ];
  }

  Future<String> exportJson() async => BackupCodec.encode(await _readAll());

  /// Writes to a temp file first and renames, so an interrupted export never
  /// leaves a truncated backup at [path]. Returns the item count.
  Future<int> exportToFile(String path) async {
    final items = await _readAll();
    final json = BackupCodec.encode(items);
    final tmp = File('$path.tmp');
    try {
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(path);
    } catch (_) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }
    return items.length;
  }

  /// Merges a backup into the library inside one transaction: titles already
  /// present are overwritten with backup values, watched episodes are unioned.
  /// Throws [BackupFormatException] for unusable files.
  Future<ImportResult> importJson(String source) async {
    final decoded = BackupCodec.decode(source);
    var inserted = 0;
    var updated = 0;

    await _db.transaction(() async {
      final existing = <TitleKey, int>{
        for (final row in await _db.select(_db.libraryItems).get())
          (tmdbId: row.tmdbId, mediaType: row.mediaType): row.id,
      };
      final favorites = Set<TitleKey>.of(await _readFavorites());
      var favoritesChanged = false;

      for (final item in decoded.items) {
        final key = (tmdbId: item.tmdbId, mediaType: item.mediaType);
        if (item.isFavorite && favorites.add(key)) {
          favoritesChanged = true;
        }
        final companion = _toCompanion(item);
        final existingId = existing[key];
        final int id;
        if (existingId != null) {
          id = existingId;
          await (_db.update(_db.libraryItems)..where((t) => t.id.equals(id)))
              .write(companion);
          updated++;
        } else {
          id = await _db.into(_db.libraryItems).insert(companion);
          existing[key] = id;
          inserted++;
        }

        await (_db.delete(_db.itemGenres)..where((t) => t.itemId.equals(id)))
            .go();
        await _db.batch((b) {
          b.insertAll(
            _db.itemGenres,
            [
              for (final g in item.genres)
                ItemGenresCompanion.insert(
                    itemId: id, genreId: g.id, genreName: g.name),
            ],
            mode: InsertMode.insertOrReplace,
          );
          if (item.mediaType == MediaType.tv) {
            b.insertAllOnConflictUpdate(_db.tvSeasons, [
              for (final s in item.seasons)
                TvSeasonsCompanion.insert(
                  itemId: id,
                  seasonNumber: s.number,
                  episodeCount: s.episodeCount,
                  name: Value(s.name),
                ),
            ]);
            b.insertAll(
              _db.watchedEpisodes,
              [
                for (final e in item.episodes)
                  WatchedEpisodesCompanion.insert(
                    itemId: id,
                    seasonNumber: e.season,
                    episodeNumber: e.episode,
                    watchedAt: e.watchedAt,
                  ),
              ],
              mode: InsertMode.insertOrIgnore,
            );
          }
        });
      }

      if (favoritesChanged) {
        await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                name: SettingKeys.favoriteTitles,
                value: serializeFavoriteTitleKeys(favorites),
              ),
            );
      }
    });

    return ImportResult(
      inserted: inserted,
      updated: updated,
      errors: decoded.errors,
    );
  }

  static LibraryItemsCompanion _toCompanion(BackupItem i) =>
      LibraryItemsCompanion.insert(
        tmdbId: i.tmdbId,
        mediaType: i.mediaType,
        title: i.title,
        originalTitle: Value(i.originalTitle),
        posterPath: Value(i.posterPath),
        overview: Value(i.overview),
        releaseYear: Value(i.releaseYear),
        status: i.status,
        userRating: Value(i.userRating),
        note: Value(i.note),
        addedAt: i.addedAt,
        updatedAt: i.updatedAt,
        watchedAt: Value(i.watchedAt),
      );
}

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref.watch(appDatabaseProvider)));
