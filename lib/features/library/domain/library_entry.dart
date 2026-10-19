import '../../../core/database/app_database.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';

class LibraryEntry {
  const LibraryEntry({
    required this.item,
    required this.genres,
    required this.watchedEpisodeCount,
    required this.totalEpisodeCount,
    this.lastSeason,
    this.lastEpisode,
  });

  final LibraryItem item;
  final List<Genre> genres;
  final int watchedEpisodeCount;
  final int totalEpisodeCount;
  final int? lastSeason;
  final int? lastEpisode;

  TitleKey get key => (tmdbId: item.tmdbId, mediaType: item.mediaType);

  bool get isTv => item.mediaType == MediaType.tv;

  String? get progressLabel {
    if (!isTv || lastSeason == null || lastEpisode == null) return null;
    final position = 'S$lastSeason B$lastEpisode';
    return totalEpisodeCount > 0
        ? '$position · $watchedEpisodeCount/$totalEpisodeCount'
        : position;
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
