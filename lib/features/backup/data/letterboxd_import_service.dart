import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/settings_dao.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/network/tmdb_models.dart';
import '../../../core/network/tmdb_providers.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../library/domain/watch_status.dart';
import 'letterboxd_codec.dart';

typedef LetterboxdProgressCallback = void Function(
  int processed,
  int total,
  String currentTitle,
);

class LetterboxdImportResult {
  const LetterboxdImportResult({
    required this.inserted,
    required this.updated,
    required this.unchanged,
    required this.unmatchedTitles,
    required this.skippedRows,
  });

  final int inserted;
  final int updated;
  final int unchanged;
  final List<String> unmatchedTitles;
  final int skippedRows;
}

class LetterboxdImportService {
  LetterboxdImportService(
    this._db,
    this._clientFactory, {
    this.concurrency = 5,
  }) : assert(concurrency >= 1 && concurrency <= 12);

  final AppDatabase _db;
  final TmdbClient? Function() _clientFactory;
  final int concurrency;

  Future<LetterboxdImportResult> importZipBytes(
    Uint8List archiveBytes, {
    CancelToken? cancelToken,
    LetterboxdProgressCallback? onProgress,
  }) {
    final parsed = LetterboxdCodec.decodeZipArchive(archiveBytes);
    return _importParsed(
      parsed,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }

  Future<LetterboxdImportResult> importCsvFiles(
    List<({String fileName, String content})> files, {
    CancelToken? cancelToken,
    LetterboxdProgressCallback? onProgress,
  }) {
    final parsed = LetterboxdCodec.decodeCsvFiles(files);
    return _importParsed(
      parsed,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }

  Future<LetterboxdImportResult> _importParsed(
    LetterboxdParseResult parsed, {
    CancelToken? cancelToken,
    LetterboxdProgressCallback? onProgress,
  }) async {
    final client = _clientFactory();
    if (client == null) {
      throw const TmdbException(TmdbErrorKind.missingKey);
    }

    final existingRows = await _db.select(_db.libraryItems).get();
    final existingByKey = <TitleKey, LibraryItem>{
      for (final row in existingRows)
        (tmdbId: row.tmdbId, mediaType: row.mediaType): row,
    };
    final localLookup = _buildLocalTitleLookup(existingRows);

    final genreMap = await _fetchGenreMapBestEffort(client);
    if (cancelToken?.isCancelled ?? false) {
      throw const TmdbException(TmdbErrorKind.cancelled);
    }

    final entries = parsed.entries;
    final total = entries.length;
    final resolvedSlots = List<_ResolvedImportItem?>.filled(total, null);
    final unmatchedSlots = List<String?>.filled(total, null);

    var nextIndex = 0;
    var processed = 0;
    TmdbException? fatalError;

    Future<void> worker() async {
      while (fatalError == null && !(cancelToken?.isCancelled ?? false)) {
        final idx = nextIndex++;
        if (idx >= total) break;
        final entry = entries[idx];

        try {
          // Fast path: match against existing local library without hitting TMDB
          // when title + year unambiguously match a single existing entry.
          final localMatch = _findLocalMatch(entry, existingByKey, localLookup);
          if (localMatch != null) {
            resolvedSlots[idx] = _ResolvedImportItem(
              entry: entry,
              summary: TitleSummary(
                tmdbId: localMatch.tmdbId,
                mediaType: localMatch.mediaType,
                title: localMatch.title,
                originalTitle: localMatch.originalTitle,
                posterPath: localMatch.posterPath,
                overview: localMatch.overview,
                releaseYear: localMatch.releaseYear,
              ),
              seasons: const [],
            );
          } else {
            final match = await _resolveOnTmdb(
              client,
              entry,
              genreMap: genreMap,
              cancelToken: cancelToken,
            );
            if (match == null) {
              unmatchedSlots[idx] = entry.displayLabel;
            } else {
              var seasons = const <SeasonInfo>[];
              if (match.mediaType == MediaType.tv &&
                  !existingByKey.containsKey(match.key)) {
                seasons = await _fetchSeasonsBestEffort(
                  client,
                  match.tmdbId,
                  cancelToken: cancelToken,
                );
              }
              resolvedSlots[idx] = _ResolvedImportItem(
                entry: entry,
                summary: match,
                seasons: seasons,
              );
            }
          }
        } on TmdbException catch (e) {
          if (e.kind == TmdbErrorKind.cancelled) {
            fatalError ??= e;
            break;
          }
          if (e.kind == TmdbErrorKind.unauthorized ||
              e.kind == TmdbErrorKind.missingKey) {
            fatalError ??= e;
            cancelToken?.cancel();
            break;
          }
          if (e.kind == TmdbErrorKind.network ||
              e.kind == TmdbErrorKind.timeout) {
            fatalError ??= e;
            cancelToken?.cancel();
            break;
          }
          unmatchedSlots[idx] = entry.displayLabel;
        }

        processed++;
        onProgress?.call(processed, total, entry.displayLabel);
      }
    }

    final workerCount = total < concurrency ? total : concurrency;
    await Future.wait([
      for (var w = 0; w < workerCount; w++) worker(),
    ]);

    if (fatalError != null) throw fatalError!;
    if (cancelToken?.isCancelled ?? false) {
      throw const TmdbException(TmdbErrorKind.cancelled);
    }

    // Deduplicate resolved items in case two distinct Letterboxd rows mapped
    // to the same TMDB ID.
    final mergedByTmdbKey = <TitleKey, _ResolvedImportItem>{};
    for (final item in resolvedSlots.nonNulls) {
      final key = item.summary.key;
      final prev = mergedByTmdbKey[key];
      if (prev == null) {
        mergedByTmdbKey[key] = item;
      } else {
        mergedByTmdbKey[key] = _mergeDuplicateResolved(prev, item);
      }
    }

    final unmatched = unmatchedSlots.nonNulls.toList();
    final counts = await _persistResolvedItems(mergedByTmdbKey.values.toList());

    return LetterboxdImportResult(
      inserted: counts.inserted,
      updated: counts.updated,
      unchanged: counts.unchanged,
      unmatchedTitles: unmatched,
      skippedRows: parsed.skippedRows,
    );
  }

  static Map<String, List<LibraryItem>> _buildLocalTitleLookup(
    List<LibraryItem> items,
  ) {
    final map = <String, List<LibraryItem>>{};
    for (final item in items) {
      final yearPart = item.releaseYear?.toString() ?? '';
      final normTitle = LetterboxdCodec.normalizeLookupTitle(item.title);
      if (normTitle.isNotEmpty) {
        (map['$normTitle|$yearPart'] ??= []).add(item);
      }
      final normOrig = LetterboxdCodec.normalizeLookupTitle(item.originalTitle);
      if (normOrig.isNotEmpty && normOrig != normTitle) {
        (map['$normOrig|$yearPart'] ??= []).add(item);
      }
    }
    return map;
  }

  static LibraryItem? _findLocalMatch(
    LetterboxdFilmEntry entry,
    Map<TitleKey, LibraryItem> existingByKey,
    Map<String, List<LibraryItem>> localLookup,
  ) {
    if (entry.tmdbId != null) {
      final direct =
          existingByKey[(tmdbId: entry.tmdbId!, mediaType: MediaType.movie)];
      if (direct != null) return direct;
    }
    if (entry.year == null) return null;
    final key =
        '${LetterboxdCodec.normalizeLookupTitle(entry.name)}|${entry.year}';
    final matches = localLookup[key];
    if (matches != null && matches.length == 1) {
      return matches.single;
    }
    return null;
  }

  Future<Map<MediaType, Map<int, String>>> _fetchGenreMapBestEffort(
    TmdbClient client,
  ) async {
    try {
      final results = await Future.wait([
        client.fetchGenres(MediaType.movie),
        client.fetchGenres(MediaType.tv),
      ]);
      return {
        MediaType.movie: {for (final g in results[0]) g.id: g.name},
        MediaType.tv: {for (final g in results[1]) g.id: g.name},
      };
    } on TmdbException catch (e) {
      if (e.kind == TmdbErrorKind.unauthorized ||
          e.kind == TmdbErrorKind.missingKey) {
        rethrow;
      }
      return const {};
    }
  }

  Future<List<SeasonInfo>> _fetchSeasonsBestEffort(
    TmdbClient client,
    int tvId, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await _withRateLimitRetry(
        () => client.fetchTvSeasons(tvId),
        cancelToken: cancelToken,
      );
    } on TmdbException {
      return const [];
    }
  }

  Future<TitleSummary?> _resolveOnTmdb(
    TmdbClient client,
    LetterboxdFilmEntry entry, {
    required Map<MediaType, Map<int, String>> genreMap,
    CancelToken? cancelToken,
  }) async {
    if (entry.tmdbId != null) {
      try {
        final direct = await _withRateLimitRetry(
          () => client.fetchMovieById(
            entry.tmdbId!,
            cancelToken: cancelToken,
          ),
          cancelToken: cancelToken,
        );
        if (direct != null) {
          return direct.toSummary(genreMap[direct.mediaType] ?? const {});
        }
      } on TmdbException catch (e) {
        if (e.kind != TmdbErrorKind.notFound) rethrow;
      }
    }

    TmdbSearchItem? best;

    // Step 1: Year-scoped movie search handles non-English titles (e.g. Japanese/Korean
    // films logged under their international English title on Letterboxd) accurately.
    if (entry.year != null) {
      final moviePage = await _withRateLimitRetry(
        () => client.searchMovies(
          entry.name,
          year: entry.year,
          cancelToken: cancelToken,
        ),
        cancelToken: cancelToken,
      );
      best = _pickBestCandidate(entry, moviePage.results);
    }

    // Step 2: Fallback to multi-search when release year differs by ±1–2 years
    // (festival vs theatrical release) or when the entry is a TV miniseries.
    if (best == null) {
      final multiPage = await _withRateLimitRetry(
        () => client.searchMulti(entry.name, cancelToken: cancelToken),
        cancelToken: cancelToken,
      );
      best = _pickBestCandidate(entry, multiPage.results);
    }

    if (best == null) return null;
    return best.toSummary(genreMap[best.mediaType] ?? const {});
  }

  static TmdbSearchItem? _pickBestCandidate(
    LetterboxdFilmEntry entry,
    List<TmdbSearchItem> candidates,
  ) {
    if (candidates.isEmpty) return null;
    final targetNorm = LetterboxdCodec.normalizeLookupTitle(entry.name);

    TmdbSearchItem? bestItem;
    var bestScore = -100000;

    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      var score = 0;

      // Preserve TMDB's own relevance order (crucial when localized title differs
      // from Letterboxd's English title, e.g. "Spirited Away" -> "Ruhların Kaçışı").
      if (i == 0) {
        score += 45;
      } else if (i == 1) {
        score += 25;
      } else if (i < 5) {
        score += 10;
      }

      // Letterboxd is overwhelmingly movies; prefer movies over TV on ties.
      if (c.mediaType == MediaType.movie) {
        score += 15;
      }

      final candTitle = LetterboxdCodec.normalizeLookupTitle(c.title);
      final candOrig = LetterboxdCodec.normalizeLookupTitle(c.originalTitle);
      if (targetNorm.isNotEmpty) {
        if (candTitle == targetNorm || candOrig == targetNorm) {
          score += 90;
        } else if (candTitle.startsWith(targetNorm) ||
            candOrig.startsWith(targetNorm) ||
            targetNorm.startsWith(candTitle) && candTitle.length >= 4) {
          score += 35;
        }
      }

      if (entry.year != null) {
        if (c.year == null) {
          score -= 25;
        } else {
          final diff = (c.year! - entry.year!).abs();
          if (diff == 0) {
            score += 85;
          } else if (diff == 1) {
            score += 45;
          } else if (diff == 2) {
            score += 15;
          } else {
            score -= 75;
          }
        }
      }

      // Tie-break remakes or obscure shorts with popularity/vote confidence.
      if (c.voteCount >= 1000) {
        score += 12;
      } else if (c.voteCount >= 100) {
        score += 6;
      } else if (c.voteCount >= 10) {
        score += 2;
      }

      if (score > bestScore) {
        bestScore = score;
        bestItem = c;
      }
    }

    // Reject completely mismatched results (e.g. wrong decade when year was given).
    if (bestScore < 10) return null;
    return bestItem;
  }

  Future<T> _withRateLimitRetry<T>(
    Future<T> Function() action, {
    CancelToken? cancelToken,
  }) async {
    const delays = [
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2500),
    ];
    for (var attempt = 0;; attempt++) {
      try {
        return await action();
      } on TmdbException catch (e) {
        if (e.kind == TmdbErrorKind.rateLimited && attempt < delays.length) {
          await Future<void>.delayed(delays[attempt]);
          if (cancelToken?.isCancelled ?? false) {
            throw const TmdbException(TmdbErrorKind.cancelled);
          }
          continue;
        }
        rethrow;
      }
    }
  }

  static _ResolvedImportItem _mergeDuplicateResolved(
    _ResolvedImportItem a,
    _ResolvedImportItem b,
  ) {
    final x = a.entry;
    final y = b.entry;
    final status =
        (x.status == WatchStatus.watched || y.status == WatchStatus.watched)
            ? WatchStatus.watched
            : WatchStatus.planned;
    return _ResolvedImportItem(
      summary: a.summary,
      seasons: a.seasons.isNotEmpty ? a.seasons : b.seasons,
      entry: LetterboxdFilmEntry(
        name: x.name,
        year: x.year ?? y.year,
        tmdbId: x.tmdbId ?? y.tmdbId,
        letterboxdUri: x.letterboxdUri ?? y.letterboxdUri,
        status: status,
        userRating: y.userRating ?? x.userRating,
        note: y.note ?? x.note,
        isFavorite: x.isFavorite || y.isFavorite,
        addedAt: _earlierDate(x.addedAt, y.addedAt),
        watchedAt: _laterDate(x.watchedAt, y.watchedAt),
      ),
    );
  }

  static DateTime? _earlierDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  static DateTime? _laterDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  Future<({int inserted, int updated, int unchanged})> _persistResolvedItems(
    List<_ResolvedImportItem> items,
  ) async {
    var inserted = 0;
    var updated = 0;
    var unchanged = 0;

    await _db.transaction(() async {
      final existingRows = await _db.select(_db.libraryItems).get();
      final existingByKey = <TitleKey, LibraryItem>{
        for (final row in existingRows)
          (tmdbId: row.tmdbId, mediaType: row.mediaType): row,
      };

      final favRow = await (_db.select(_db.appSettings)
            ..where((t) => t.name.equals(SettingKeys.favoriteTitles)))
          .getSingleOrNull();
      final favorites = Set<TitleKey>.of(parseFavoriteTitleKeys(favRow?.value));
      var favoritesChanged = false;

      final now = DateTime.now();

      for (final resolved in items) {
        final summary = resolved.summary;
        final entry = resolved.entry;
        final key = summary.key;

        var favAddedForThis = false;
        if (entry.isFavorite && favorites.add(key)) {
          favoritesChanged = true;
          favAddedForThis = true;
        }

        final existing = existingByKey[key];
        if (existing == null) {
          final addedAt = entry.addedAt ?? entry.watchedAt ?? now;
          final watchedAt = entry.status == WatchStatus.watched
              ? (entry.watchedAt ?? addedAt)
              : null;

          final newId = await _db.into(_db.libraryItems).insert(
                LibraryItemsCompanion.insert(
                  tmdbId: summary.tmdbId,
                  mediaType: summary.mediaType,
                  title: summary.title,
                  originalTitle: Value(summary.originalTitle),
                  posterPath: Value(summary.posterPath),
                  overview: Value(summary.overview),
                  releaseYear: Value(summary.releaseYear),
                  status: entry.status,
                  userRating: Value(entry.userRating),
                  note: Value(entry.note),
                  addedAt: addedAt,
                  updatedAt: now,
                  watchedAt: Value(watchedAt),
                ),
              );

          await _db.batch((b) {
            if (summary.genres.isNotEmpty) {
              b.insertAll(
                _db.itemGenres,
                [
                  for (final g in summary.genres)
                    ItemGenresCompanion.insert(
                      itemId: newId,
                      genreId: g.id,
                      genreName: g.name,
                    ),
                ],
                mode: InsertMode.insertOrIgnore,
              );
            }
            if (summary.mediaType == MediaType.tv &&
                resolved.seasons.isNotEmpty) {
              b.insertAllOnConflictUpdate(_db.tvSeasons, [
                for (final s in resolved.seasons)
                  TvSeasonsCompanion.insert(
                    itemId: newId,
                    seasonNumber: s.number,
                    episodeCount: s.episodeCount,
                    name: Value(s.name),
                  ),
              ]);
              if (entry.status == WatchStatus.watched) {
                final epWatchedAt = watchedAt ?? now;
                b.insertAll(
                  _db.watchedEpisodes,
                  [
                    for (final s in resolved.seasons)
                      for (var ep = 1; ep <= s.episodeCount; ep++)
                        WatchedEpisodesCompanion.insert(
                          itemId: newId,
                          seasonNumber: s.number,
                          episodeNumber: ep,
                          watchedAt: epWatchedAt,
                        ),
                  ],
                  mode: InsertMode.insertOrIgnore,
                );
              }
            }
          });
          inserted++;
        } else {
          // Non-destructive merge: never downgrade watched -> planned or erase
          // existing ratings/notes when the Letterboxd entry omits them.
          final mergedStatus = (existing.status == WatchStatus.watched ||
                  entry.status == WatchStatus.watched)
              ? WatchStatus.watched
              : existing.status;

          final mergedRating = entry.userRating ?? existing.userRating;
          final mergedNote = entry.note ?? existing.note;
          final mergedWatchedAt = mergedStatus == WatchStatus.watched
              ? (entry.watchedAt ?? existing.watchedAt ?? now)
              : existing.watchedAt;

          final hasChanges = mergedStatus != existing.status ||
              mergedRating != existing.userRating ||
              mergedNote != existing.note ||
              mergedWatchedAt != existing.watchedAt;

          if (hasChanges) {
            await (_db.update(_db.libraryItems)
                  ..where((t) => t.id.equals(existing.id)))
                .write(
              LibraryItemsCompanion(
                status: Value(mergedStatus),
                userRating: Value(mergedRating),
                note: Value(mergedNote),
                watchedAt: Value(mergedWatchedAt),
                updatedAt: Value(now),
              ),
            );
            updated++;
          } else if (favAddedForThis) {
            updated++;
          } else {
            unchanged++;
          }
        }
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

    return (inserted: inserted, updated: updated, unchanged: unchanged);
  }
}

class _ResolvedImportItem {
  const _ResolvedImportItem({
    required this.entry,
    required this.summary,
    required this.seasons,
  });

  final LetterboxdFilmEntry entry;
  final TitleSummary summary;
  final List<SeasonInfo> seasons;
}

final letterboxdImportServiceProvider =
    Provider<LetterboxdImportService>((ref) {
  return LetterboxdImportService(
    ref.watch(appDatabaseProvider),
    () => ref.read(tmdbClientProvider),
  );
});
