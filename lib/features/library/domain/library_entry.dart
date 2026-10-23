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
    this.lastSeason,
    this.lastEpisode,
  });

  final LibraryItem item;
  final List<Genre> genres;
  final List<(int season, int episodeCount)> seasonCounts;
  final int watchedEpisodeCount;
  final int totalEpisodeCount;
  final int? lastSeason;
  final int? lastEpisode;

  TitleKey get key => (tmdbId: item.tmdbId, mediaType: item.mediaType);

  bool get isTv => item.mediaType == MediaType.tv;

  String? get progressLabel {
    if (!isTv || lastSeason == null || lastEpisode == null) return null;
    final position = formatEpisodeCode(lastSeason!, lastEpisode!);
    return totalEpisodeCount > 0
        ? '$position · $watchedEpisodeCount/$totalEpisodeCount'
        : position;
  }

  /// Returns the next unwatched `(season, episode)` for a TV show, or `null`
  /// if it is a movie or already completed.
  (int season, int episode)? get nextEpisode {
    if (!isTv || item.status == WatchStatus.watched) return null;
    if (totalEpisodeCount > 0 && watchedEpisodeCount >= totalEpisodeCount) {
      return null;
    }

    final lastS = lastSeason;
    final lastE = lastEpisode;
    if (lastS == null || lastE == null) {
      if (seasonCounts.isNotEmpty) {
        return (seasonCounts.first.$1, 1);
      }
      return (1, 1);
    }

    if (seasonCounts.isEmpty) {
      return (lastS, lastE + 1);
    }

    for (var i = 0; i < seasonCounts.length; i++) {
      final (sNum, epCount) = seasonCounts[i];
      if (sNum == lastS) {
        if (lastE < epCount) {
          return (lastS, lastE + 1);
        }
        if (i + 1 < seasonCounts.length) {
          return (seasonCounts[i + 1].$1, 1);
        }
        return null;
      }
      if (sNum > lastS) {
        return (sNum, 1);
      }
    }
    return null;
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
        genres: genres,
      );
}
