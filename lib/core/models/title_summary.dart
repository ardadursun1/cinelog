import '../l10n/app_language.dart';
import 'media_type.dart';
import 'tmdb_genres.dart';

typedef TitleKey = ({int tmdbId, MediaType mediaType});

class Genre {
  const Genre(this.id, this.name);

  final int id;
  final String name;

  String labelFor(AppLanguage lang) => localizedGenreName(id, name, lang);
}

/// Minimal, source-independent description of a movie or TV show.
class TitleSummary {
  const TitleSummary({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.originalTitle = '',
    this.posterPath,
    this.overview = '',
    this.releaseYear,
    this.runtimeMinutes,
    this.voteAverage,
    this.genres = const [],
  });

  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String originalTitle;
  final String? posterPath;
  final String overview;
  final int? releaseYear;
  final int? runtimeMinutes;
  final double? voteAverage;
  final List<Genre> genres;

  TitleKey get key => (tmdbId: tmdbId, mediaType: mediaType);

  String? get formattedVoteAverage {
    final v = voteAverage;
    if (v == null || v <= 0) return null;
    return v.toStringAsFixed(1);
  }

  String get genreLabel => genreLabelFor(AppLanguage.tr);

  String genreLabelFor(AppLanguage lang) =>
      genres.map((g) => g.labelFor(lang)).join(', ');

  String get metaLabel => metaLabelFor(AppLanguage.tr);

  String metaLabelFor(AppLanguage lang) => [
        mediaType.labelFor(lang),
        if (releaseYear != null) '$releaseYear',
        if (genres.isNotEmpty) genreLabelFor(lang),
      ].join(' · ');
}

