import '../l10n/app_language.dart';
import '../network/tmdb_models.dart';
import 'media_type.dart';

class ContentCategory {
  const ContentCategory({
    required this.key,
    required this.label,
    required this.labelEn,
    this.movieGenreIds = const [],
    this.tvGenreIds = const [],
    this.includeOriginalLanguage,
    this.tmdbKeywordId,
  });

  final String key;
  final String label;
  final String labelEn;
  final List<int> movieGenreIds;
  final List<int> tvGenreIds;
  final String? includeOriginalLanguage;
  final int? tmdbKeywordId;

  String labelFor(AppLanguage lang) => lang.isEn ? labelEn : label;

  List<int> genreIdsFor(MediaType type) =>
      type == MediaType.movie ? movieGenreIds : tvGenreIds;

  /// True when [item] belongs to this category and should be hidden when the
  /// category is excluded.
  bool matchesExcluded(TmdbSearchItem item) {
    final ids = genreIdsFor(item.mediaType);
    if (ids.any(item.genreIds.contains)) return true;
    if (key == 'anime' &&
        item.originalLanguage == 'ja' &&
        item.genreIds.contains(16)) {
      return true;
    }
    return false;
  }
}

/// Unified categories across TMDB movies and TV shows.
const List<ContentCategory> kContentCategories = [
  ContentCategory(
    key: 'anime',
    label: 'Anime',
    labelEn: 'Anime',
    movieGenreIds: [16],
    tvGenreIds: [16],
    includeOriginalLanguage: 'ja',
    tmdbKeywordId: 210024,
  ),
  ContentCategory(
    key: 'animation',
    label: 'Animasyon',
    labelEn: 'Animation',
    movieGenreIds: [16],
    tvGenreIds: [16],
  ),
  ContentCategory(
    key: 'action',
    label: 'Aksiyon',
    labelEn: 'Action',
    movieGenreIds: [28],
    tvGenreIds: [10759],
  ),
  ContentCategory(
    key: 'adventure',
    label: 'Macera',
    labelEn: 'Adventure',
    movieGenreIds: [12],
    tvGenreIds: [10759],
  ),
  ContentCategory(
    key: 'scifi',
    label: 'Bilim Kurgu',
    labelEn: 'Sci-Fi',
    movieGenreIds: [878],
    tvGenreIds: [10765],
  ),
  ContentCategory(
    key: 'fantasy',
    label: 'Fantastik',
    labelEn: 'Fantasy',
    movieGenreIds: [14],
    tvGenreIds: [10765],
  ),
  ContentCategory(
    key: 'drama',
    label: 'Dram',
    labelEn: 'Drama',
    movieGenreIds: [18],
    tvGenreIds: [18],
  ),
  ContentCategory(
    key: 'comedy',
    label: 'Komedi',
    labelEn: 'Comedy',
    movieGenreIds: [35],
    tvGenreIds: [35],
  ),
  ContentCategory(
    key: 'crime',
    label: 'Suç',
    labelEn: 'Crime',
    movieGenreIds: [80],
    tvGenreIds: [80],
  ),
  ContentCategory(
    key: 'thriller',
    label: 'Gerilim',
    labelEn: 'Thriller',
    movieGenreIds: [53],
    tvGenreIds: [9648],
  ),
  ContentCategory(
    key: 'horror',
    label: 'Korku',
    labelEn: 'Horror',
    movieGenreIds: [27],
    tvGenreIds: [9648],
  ),
  ContentCategory(
    key: 'mystery',
    label: 'Gizem',
    labelEn: 'Mystery',
    movieGenreIds: [9648],
    tvGenreIds: [9648],
  ),
  ContentCategory(
    key: 'romance',
    label: 'Romantik',
    labelEn: 'Romance',
    movieGenreIds: [10749],
    tvGenreIds: [10749],
  ),
  ContentCategory(
    key: 'family',
    label: 'Aile',
    labelEn: 'Family',
    movieGenreIds: [10751],
    tvGenreIds: [10751, 10762],
  ),
  ContentCategory(
    key: 'history',
    label: 'Tarih',
    labelEn: 'History',
    movieGenreIds: [36],
    tvGenreIds: [36],
  ),
  ContentCategory(
    key: 'war',
    label: 'Savaş',
    labelEn: 'War',
    movieGenreIds: [10752],
    tvGenreIds: [10768],
  ),
  ContentCategory(
    key: 'documentary',
    label: 'Belgesel',
    labelEn: 'Documentary',
    movieGenreIds: [99],
    tvGenreIds: [99],
  ),
  ContentCategory(
    key: 'western',
    label: 'Vahşi Batı',
    labelEn: 'Western',
    movieGenreIds: [37],
    tvGenreIds: [37],
  ),
  ContentCategory(
    key: 'music',
    label: 'Müzik',
    labelEn: 'Music',
    movieGenreIds: [10402],
    tvGenreIds: [10402],
  ),
  ContentCategory(
    key: 'reality',
    label: 'Reality / Talk',
    labelEn: 'Reality / Talk',
    movieGenreIds: [],
    tvGenreIds: [10764, 10767, 10766],
  ),
];

final Map<String, ContentCategory> kCategoryByKey = {
  for (final c in kContentCategories) c.key: c,
};

