import '../../../core/database/app_database.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import 'watch_status.dart';

String formatEpisodeCode(int season, int episode) {
  final s = season.toString().padLeft(2, '0');
  final e = episode.toString().padLeft(2, '0');
  return 'S${s}E$e';
}

class LibraryEntry {
  const LibraryEntry({
    required this.item,
    required this.genres,
    required this.watchedEpisodeCount,
    required this.totalEpisodeCount,
    this.seasonCounts = const [],
    this.watchedEpisodes = const {},
    this.lastSeason,
    this.lastEpisode,
  });

  final LibraryItem item;
  final List<Genre> genres;
  final List<(int season, int episodeCount)> seasonCounts;
  final Set<(int season, int episode)> watchedEpisodes;
  final int watchedEpisodeCount;
  final int totalEpisodeCount;
  final int? lastSeason;
  final int? lastEpisode;

  TitleKey get key => (tmdbId: item.tmdbId, mediaType: item.mediaType);

  bool get isTv => item.mediaType == MediaType.tv;

  String? get progressLabel {
    if (!isTv || item.status == WatchStatus.planned) return null;
    if (lastSeason == null || lastEpisode == null) return null;
    final position = formatEpisodeCode(lastSeason!, lastEpisode!);
    return totalEpisodeCount > 0
        ? '$position · $watchedEpisodeCount/$totalEpisodeCount'
        : position;
  }

  /// Returns the first unwatched `(season, episode)` in chronological order
  /// (never skipping gaps between watched seasons/episodes), or `null` if it
  /// is a movie or already completed.
  (int season, int episode)? get nextEpisode {
    if (!isTv || item.status == WatchStatus.watched) return null;
    if (totalEpisodeCount > 0 && watchedEpisodeCount >= totalEpisodeCount) {
      return null;
    }

    if (seasonCounts.isNotEmpty) {
      for (final (sNum, epCount) in seasonCounts) {
        for (var ep = 1; ep <= epCount; ep++) {
          if (!watchedEpisodes.contains((sNum, ep))) {
            return (sNum, ep);
          }
        }
      }
      return null;
    }

    final lastS = lastSeason;
    final lastE = lastEpisode;
    if (lastS == null || lastE == null) {
      return (1, 1);
    }
    return (lastS, lastE + 1);
  }

  String? get nextEpisodeLabel {
    final next = nextEpisode;
    if (next == null) return null;
    return '${formatEpisodeCode(next.$1, next.$2)} → ✓';
  }

  TitleSummary toSummary() => TitleSummary(
        tmdbId: item.tmdbId,
        mediaType: item.mediaType,
        title: item.title,
        originalTitle: item.originalTitle,
        posterPath: item.posterPath,
        overview: item.overview,
        releaseYear: item.releaseYear,
        runtimeMinutes: item.runtimeMinutes,
        genres: genres,
      );
}
