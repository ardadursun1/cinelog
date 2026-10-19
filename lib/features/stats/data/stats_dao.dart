import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/models/media_type.dart';
import '../../library/domain/watch_status.dart';

class CountByLabel<T> {
  const CountByLabel(this.label, this.count);

  final T label;
  final int count;
}

class LibraryStats {
  const LibraryStats({
    required this.counts,
    required this.watchedEpisodes,
    required this.genres,
    required this.releaseYears,
  });

  static const int avgMovieMinutes = 115;
  static const int avgEpisodeMinutes = 42;

  final Map<(WatchStatus, MediaType), int> counts;
  final int watchedEpisodes;
  final List<CountByLabel<String>> genres;
  final List<CountByLabel<int>> releaseYears;

  int count(WatchStatus status, [MediaType? type]) => counts.entries
      .where((e) => e.key.$1 == status && (type == null || e.key.$2 == type))
      .fold(0, (sum, e) => sum + e.value);

  int get totalItems => counts.values.fold(0, (a, b) => a + b);

  int get estimatedWatchMinutes =>
      count(WatchStatus.watched, MediaType.movie) * avgMovieMinutes +
      watchedEpisodes * avgEpisodeMinutes;

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
      'Film (~115 dk) + bölüm (~42 dk) toplamı',
      'Movies (~115m) + episodes (~42m) total',
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

    final episodes = await _db
        .customSelect('SELECT COUNT(*) AS c FROM watched_episodes')
        .getSingle();
    final quickCompletedEpisodes = await _db.customSelect(
      'SELECT COALESCE(SUM(ts.episode_count), 0) AS c '
      'FROM tv_seasons ts '
      'JOIN library_items li ON li.id = ts.item_id '
      'WHERE li.status = ? AND li.media_type = ? '
      'AND NOT EXISTS ('
      '  SELECT 1 FROM watched_episodes we WHERE we.item_id = li.id'
      ')',
      variables: [watched, Variable.withString(MediaType.tv.name)],
    ).getSingle();

    final genreRows = await _db.customSelect(
      'SELECT g.genre_name AS name, COUNT(*) AS c FROM item_genres g '
      'JOIN library_items li ON li.id = g.item_id WHERE li.status = ? '
      'GROUP BY g.genre_name ORDER BY c DESC, name',
      variables: [watched],
    ).get();

    final yearRows = await _db.customSelect(
      'SELECT release_year AS y, COUNT(*) AS c FROM library_items '
      'WHERE status = ? AND release_year IS NOT NULL '
      'GROUP BY release_year ORDER BY release_year',
      variables: [watched],
    ).get();

    return LibraryStats(
      counts: counts,
      watchedEpisodes:
          episodes.read<int>('c') + quickCompletedEpisodes.read<int>('c'),
      genres: [
        for (final r in genreRows)
          CountByLabel(r.read<String>('name'), r.read<int>('c')),
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
