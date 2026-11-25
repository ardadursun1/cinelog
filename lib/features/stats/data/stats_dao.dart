import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/tmdb_genres.dart';
import '../../library/domain/watch_status.dart';

class CountByLabel<T> {
  const CountByLabel(this.label, this.count);

  final T label;
  final int count;
}

class GenreCountRow {
  const GenreCountRow({
    required this.genreId,
    required this.fallbackName,
    required this.count,
  });

  final int genreId;
  final String fallbackName;
  final int count;
}

class LibraryStats {
  const LibraryStats({
    required this.counts,
    required this.watchedEpisodes,
    required this.estimatedWatchMinutes,
    required this.genreRows,
    required this.releaseYears,
  });

  static const int avgMovieMinutes = 115;
  static const int avgEpisodeMinutes = 42;

  final Map<(WatchStatus, MediaType), int> counts;
  final int watchedEpisodes;
  final int estimatedWatchMinutes;
  final List<GenreCountRow> genreRows;
  final List<CountByLabel<int>> releaseYears;

  List<CountByLabel<String>> get genres => genresFor(AppLanguage.tr);

  /// Merges genre counts using localized canonical names so titles added under
  /// different app languages never split into duplicate rows.
  List<CountByLabel<String>> genresFor(AppLanguage lang) {
    final merged = <String, int>{};
    for (final row in genreRows) {
      final name = localizedGenreName(row.genreId, row.fallbackName, lang);
      merged[name] = (merged[name] ?? 0) + row.count;
    }
    final list = [
      for (final e in merged.entries) CountByLabel(e.key, e.value),
    ]..sort((a, b) {
        final cmp = b.count.compareTo(a.count);
        return cmp != 0 ? cmp : a.label.compareTo(b.label);
      });
    return list;
  }

  int count(WatchStatus status, [MediaType? type]) => counts.entries
      .where((e) => e.key.$1 == status && (type == null || e.key.$2 == type))
      .fold(0, (sum, e) => sum + e.value);

  int get totalItems => counts.values.fold(0, (a, b) => a + b);

  String watchTimePrimaryLabelFor(AppLanguage lang) {
    final mins = estimatedWatchMinutes;
    if (mins == 0) return lang.pick('0 saat', '0 hrs');
    if (mins < 60) return lang.pick('$mins dk', '$mins min');
    final hrs = (mins / 60).round();
    return lang.pick('$hrs saat', '$hrs hrs');
  }

  String watchTimeSubtitleFor(AppLanguage lang) {
    final mins = estimatedWatchMinutes;
    if (mins >= 1440) {
      final days = mins ~/ 1440;
      final remHours = (mins % 1440) ~/ 60;
      return lang.pick(
        'Yaklaşık $days gün $remHours saat',
        'Approx. $days d $remHours h',
      );
    }
    return lang.pick(
      'Gerçek süreler (bilinmiyorsa ~115/42 dk)',
      'Actual runtimes (fallback ~115/42m)',
    );
  }
}

class StatsDao {
  StatsDao(this._db);

  final AppDatabase _db;

  Stream<LibraryStats> watchStats() async* {
    yield await _compute();
    final updates = _db.tableUpdates(TableUpdateQuery.onAllTables([
      _db.libraryItems,
      _db.itemGenres,
      _db.tvSeasons,
      _db.watchedEpisodes,
    ]));
    await for (final _ in updates) {
      yield await _compute();
    }
  }

  Future<LibraryStats> _compute() async {
    final watched = Variable.withString(WatchStatus.watched.name);
    final movieType = Variable.withString(MediaType.movie.name);
    final tvType = Variable.withString(MediaType.tv.name);

    final countRows = await _db
        .customSelect(
          'SELECT status, media_type, COUNT(*) AS c FROM library_items '
          'GROUP BY status, media_type',
        )
        .get();
    final counts = <(WatchStatus, MediaType), int>{};
    for (final row in countRows) {
      final status = WatchStatus.tryParse(row.read<String>('status'));
      final type = MediaType.tryParse(row.read<String>('media_type'));
      if (status != null && type != null) {
        counts[(status, type)] = row.read<int>('c');
      }
    }

    final movieRuntimeRow = await _db.customSelect(
      'SELECT COALESCE(SUM(COALESCE(runtime_minutes, ?1)), 0) AS mins '
      'FROM library_items WHERE status = ?2 AND media_type = ?3',
      variables: [
        Variable.withInt(LibraryStats.avgMovieMinutes),
        watched,
        movieType,
      ],
    ).getSingle();

    final episodes = await _db.customSelect(
      'SELECT COUNT(*) AS c, '
      'COALESCE(SUM(COALESCE(li.runtime_minutes, ?1)), 0) AS mins '
      'FROM watched_episodes we '
      'JOIN library_items li ON li.id = we.item_id',
      variables: [Variable.withInt(LibraryStats.avgEpisodeMinutes)],
    ).getSingle();

    final quickCompletedEpisodes = await _db.customSelect(
      'SELECT COALESCE(SUM(ts.episode_count), 0) AS c, '
      'COALESCE(SUM(ts.episode_count * COALESCE(li.runtime_minutes, ?1)), 0) AS mins '
      'FROM tv_seasons ts '
      'JOIN library_items li ON li.id = ts.item_id '
      'WHERE li.status = ?2 AND li.media_type = ?3 '
      'AND NOT EXISTS ('
      '  SELECT 1 FROM watched_episodes we WHERE we.item_id = li.id'
      ')',
      variables: [
        Variable.withInt(LibraryStats.avgEpisodeMinutes),
        watched,
        tvType,
      ],
    ).getSingle();

    final genreRows = await _db.customSelect(
      'SELECT g.genre_id AS gid, MAX(g.genre_name) AS name, COUNT(*) AS c '
      'FROM item_genres g '
      'JOIN library_items li ON li.id = g.item_id WHERE li.status = ? '
      'GROUP BY g.genre_id',
      variables: [watched],
    ).get();

    final yearRows = await _db.customSelect(
      'SELECT release_year AS y, COUNT(*) AS c FROM library_items '
      'WHERE status = ? AND release_year IS NOT NULL '
      'GROUP BY release_year ORDER BY release_year',
      variables: [watched],
    ).get();

    final totalMinutes = movieRuntimeRow.read<int>('mins') +
        episodes.read<int>('mins') +
        quickCompletedEpisodes.read<int>('mins');

    return LibraryStats(
      counts: counts,
      watchedEpisodes:
          episodes.read<int>('c') + quickCompletedEpisodes.read<int>('c'),
      estimatedWatchMinutes: totalMinutes,
      genreRows: [
        for (final r in genreRows)
          GenreCountRow(
            genreId: r.read<int>('gid'),
            fallbackName: r.read<String>('name'),
            count: r.read<int>('c'),
          ),
      ],
      releaseYears: [
        for (final r in yearRows)
          CountByLabel(r.read<int>('y'), r.read<int>('c')),
      ],
    );
  }
}

final statsProvider = StreamProvider<LibraryStats>(
  (ref) => StatsDao(ref.watch(appDatabaseProvider)).watchStats(),
);
