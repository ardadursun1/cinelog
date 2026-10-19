import '../models/media_type.dart';
import '../models/title_summary.dart';

const int _maxTitleLength = 500;
const int _maxOverviewLength = 10000;
const int _minYear = 1800;
const int _maxYear = 2200;

final RegExp _posterPathPattern =
    RegExp(r'^/[A-Za-z0-9_\-]+\.(jpg|jpeg|png|webp)$');

/// Accepts only TMDB-style image paths so untrusted data can never
/// redirect image requests to another host.
String? sanitizePosterPath(Object? value) =>
    value is String && _posterPathPattern.hasMatch(value) ? value : null;

String tmdbPosterUrl(String posterPath, {String size = 'w342'}) =>
    'https://image.tmdb.org/t/p/$size$posterPath';

int? parseYear(Object? date) {
  if (date is! String || date.length < 4) return null;
  final year = int.tryParse(date.substring(0, 4));
  return isValidYear(year) ? year : null;
}

bool isValidYear(int? year) =>
    year != null && year >= _minYear && year <= _maxYear;

String _clip(Object? value, int max) {
  if (value is! String) return '';
  final trimmed = value.trim();
  return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
}

int _positiveInt(Object? value, {int fallback = 0}) =>
    value is int && value > 0 ? value : fallback;

double? _computeWeightedRating(
  Object? rawAverage,
  Object? rawCount, {
  required MediaType mediaType,
}) {
  if (rawAverage is! num) return null;
  final r = rawAverage.toDouble();
  if (r <= 0 || r > 10) return null;

  final v = rawCount is int && rawCount >= 0 ? rawCount : 0;
  if (v < 15) return null;

  // Baseline mean (C) and confidence vote threshold (m) using the
  // IMDb Top 250 Bayesian weighted rating formula. Only damp scores
  // above the baseline so genuinely low-rated titles are never boosted.
  const baseline = 6.5;
  if (r <= baseline) return r;

  final minVotes = mediaType == MediaType.movie ? 1500.0 : 600.0;
  return (v / (v + minVotes)) * r + (minVotes / (v + minVotes)) * baseline;
}

class TmdbSearchItem {
  const TmdbSearchItem({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.originalTitle,
    required this.posterPath,
    required this.overview,
    required this.year,
    required this.voteAverage,
    required this.genreIds,
    this.voteCount = 0,
    this.originalLanguage = '',
  });

  final int id;
  final MediaType mediaType;
  final String title;
  final String originalTitle;
  final String? posterPath;
  final String overview;
  final int? year;
  final double? voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final String originalLanguage;

  TitleKey get key => (tmdbId: id, mediaType: mediaType);

  /// Returns `null` for unsupported (e.g. `person`) or malformed entries.
  static TmdbSearchItem? tryParse(Object? json, {MediaType? defaultType}) {
    if (json is! Map<String, dynamic>) return null;
    final type = MediaType.tryParse(json['media_type']) ?? defaultType;
    final id = json['id'];
    if (type == null || id is! int || id <= 0) return null;

    final isMovie = type == MediaType.movie;
    final title = _clip(json[isMovie ? 'title' : 'name'], _maxTitleLength);
    if (title.isEmpty) return null;

    final rawGenres = json['genre_ids'];
    final voteCount = _positiveInt(json['vote_count']);
    return TmdbSearchItem(
      id: id,
      mediaType: type,
      title: title,
      originalTitle: _clip(
        json[isMovie ? 'original_title' : 'original_name'],
        _maxTitleLength,
      ),
      posterPath: sanitizePosterPath(json['poster_path']),
      overview: _clip(json['overview'], _maxOverviewLength),
      year: parseYear(json[isMovie ? 'release_date' : 'first_air_date']),
      voteAverage: _computeWeightedRating(
        json['vote_average'],
        voteCount,
        mediaType: type,
      ),
      voteCount: voteCount,
      genreIds: rawGenres is List
          ? rawGenres.whereType<int>().where((g) => g > 0).toList()
          : const [],
      originalLanguage: _clip(json['original_language'], 16),
    );
  }

  TitleSummary toSummary(Map<int, String> genreNames) => TitleSummary(
        tmdbId: id,
        mediaType: mediaType,
        title: title,
        originalTitle: originalTitle,
        posterPath: posterPath,
        overview: overview,
        releaseYear: year,
        voteAverage: voteAverage,
        genres: [
          for (final g in genreIds)
            if (genreNames[g] case final name?) Genre(g, name),
        ],
      );
}

class TmdbSearchPage {
  const TmdbSearchPage({
    required this.results,
    required this.page,
    required this.totalPages,
  });

  final List<TmdbSearchItem> results;
  final int page;
  final int totalPages;

  factory TmdbSearchPage.fromJson(
    Map<String, dynamic> json, {
    MediaType? defaultType,
  }) {
    final raw = json['results'];
    return TmdbSearchPage(
      results: raw is List
          ? raw
              .map((e) => TmdbSearchItem.tryParse(e, defaultType: defaultType))
              .nonNulls
              .toList()
          : const [],
      page: _positiveInt(json['page'], fallback: 1),
      totalPages: _positiveInt(json['total_pages']),
    );
  }
}

class SeasonInfo {
  const SeasonInfo({
    required this.number,
    required this.episodeCount,
    this.name = '',
  });

  static const int maxSeasonNumber = 1000;
  static const int maxEpisodeCount = 10000;

  final int number;
  final int episodeCount;
  final String name;

  /// Skips specials (season 0) and seasons without episodes.
  static SeasonInfo? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final number = json['season_number'];
    final count = json['episode_count'];
    if (number is! int || number < 1 || number > maxSeasonNumber) return null;
    if (count is! int || count < 1 || count > maxEpisodeCount) return null;
    return SeasonInfo(
      number: number,
      episodeCount: count,
      name: _clip(json['name'], 200),
    );
  }

  static List<SeasonInfo> listFromTvDetails(Map<String, dynamic> json) {
    final raw = json['seasons'];
    if (raw is! List) return const [];
    final seasons = raw.map(tryParse).nonNulls.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return seasons;
  }
}

List<Genre> parseGenreList(Map<String, dynamic> json) {
  final raw = json['genres'];
  if (raw is! List) return const [];
  return [
    for (final g in raw)
      if (g is Map<String, dynamic> &&
          g['id'] is int &&
          (g['id'] as int) > 0 &&
          g['name'] is String)
        Genre(g['id'] as int, _clip(g['name'], 100)),
  ];
}

final RegExp _youtubeKeyPattern = RegExp(r'^[A-Za-z0-9_\-]{6,20}$');

class CrewMember {
  const CrewMember({
    this.id,
    required this.name,
    this.job = '',
    this.profilePath,
  });

  final int? id;
  final String name;
  final String job;
  final String? profilePath;
}

class CastMember {
  const CastMember({
    this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  final int? id;
  final String name;
  final String character;
  final String? profilePath;
}

class WatchProvider {
  const WatchProvider({
    required this.id,
    required this.name,
    this.logoPath,
  });

  final int id;
  final String name;
  final String? logoPath;

  static WatchProvider? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['provider_id'];
    final name = _clip(raw['provider_name'], 100);
    if (id is! int || id <= 0 || name.isEmpty) return null;
    return WatchProvider(
      id: id,
      name: name,
      logoPath: sanitizePosterPath(raw['logo_path']),
    );
  }
}

class WatchProvidersInfo {
  const WatchProvidersInfo({
    this.region = '',
    this.link,
    this.flatrate = const [],
    this.rent = const [],
    this.buy = const [],
  });

  final String region;
  final String? link;
  final List<WatchProvider> flatrate;
  final List<WatchProvider> rent;
  final List<WatchProvider> buy;

  bool get isEmpty => flatrate.isEmpty && rent.isEmpty && buy.isEmpty;
  bool get isNotEmpty => !isEmpty;

  static List<WatchProvider> _parseProviderList(List<Object?> sources) {
    final seen = <int>{};
    final result = <WatchProvider>[];
    for (final src in sources) {
      if (src is! List) continue;
      for (final item in src) {
        final parsed = WatchProvider.tryParse(item);
        if (parsed != null && seen.add(parsed.id)) {
          result.add(parsed);
        }
      }
    }
    return result;
  }

  static WatchProvidersInfo fromJson(
    Object? rawWatchProviders, {
    List<String> preferredRegions = const ['TR', 'US', 'GB', 'DE'],
  }) {
    if (rawWatchProviders is! Map<String, dynamic>) {
      return const WatchProvidersInfo();
    }
    final results = rawWatchProviders['results'];
    if (results is! Map<String, dynamic> || results.isEmpty) {
      return const WatchProvidersInfo();
    }

    String? chosenRegion;
    Map<String, dynamic>? regionMap;
    for (final code in preferredRegions) {
      final candidate = results[code];
      if (candidate is Map<String, dynamic>) {
        chosenRegion = code;
        regionMap = candidate;
        break;
      }
    }
    if (regionMap == null) return const WatchProvidersInfo();

    final rawLink = regionMap['link'];
    String? safeLink;
    if (rawLink is String) {
      final uri = Uri.tryParse(rawLink);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host == 'www.themoviedb.org') {
        safeLink = rawLink;
      }
    }

    final flatrate = _parseProviderList([
      regionMap['flatrate'],
      regionMap['free'],
      regionMap['ads'],
    ]);
    final flatrateIds = {for (final p in flatrate) p.id};
    final rent = [
      for (final p in _parseProviderList([regionMap['rent']]))
        if (!flatrateIds.contains(p.id)) p,
    ];
    final rentOrFlatIds = {...flatrateIds, for (final p in rent) p.id};
    final buy = [
      for (final p in _parseProviderList([regionMap['buy']]))
        if (!rentOrFlatIds.contains(p.id)) p,
    ];

    return WatchProvidersInfo(
      region: chosenRegion ?? '',
      link: safeLink,
      flatrate: flatrate,
      rent: rent,
      buy: buy,
    );
  }
}

class RichTitleDetails {
  const RichTitleDetails({
    this.runtimeMinutes,
    this.tagline = '',
    this.creators = const [],
    this.cast = const [],
    this.youtubeTrailerKey,
    this.recommendations = const [],
    this.watchProviders = const WatchProvidersInfo(),
  });

  final int? runtimeMinutes;
  final String tagline;
  final List<CrewMember> creators;
  final List<CastMember> cast;
  final String? youtubeTrailerKey;
  final List<TmdbSearchItem> recommendations;
  final WatchProvidersInfo watchProviders;

  List<String> get creatorsOrDirectors => [for (final c in creators) c.name];

  String? get youtubeTrailerUrl =>
      youtubeTrailerKey != null && _youtubeKeyPattern.hasMatch(youtubeTrailerKey!)
          ? 'https://www.youtube.com/watch?v=$youtubeTrailerKey'
          : null;

  factory RichTitleDetails.fromJson(
    Map<String, dynamic> json, {
    required MediaType mediaType,
  }) {
    final isMovie = mediaType == MediaType.movie;

    int? runtime;
    if (isMovie) {
      final rawRuntime = json['runtime'];
      if (rawRuntime is int && rawRuntime > 0 && rawRuntime < 1500) {
        runtime = rawRuntime;
      }
    } else {
      final runTimes = json['episode_run_time'];
      if (runTimes is List) {
        final first = runTimes
            .whereType<int>()
            .where((r) => r > 0 && r < 600)
            .firstOrNull;
        runtime = first;
      }
      if (runtime == null) {
        final lastEp = json['last_episode_to_air'];
        if (lastEp is Map<String, dynamic>) {
          final r = lastEp['runtime'];
          if (r is int && r > 0 && r < 600) runtime = r;
        }
      }
    }

    final creators = <CrewMember>[];
    final seenCreatorNames = <String>{};
    if (!isMovie) {
      final rawCreatedBy = json['created_by'];
      if (rawCreatedBy is List) {
        for (final entry in rawCreatedBy) {
          if (entry is Map<String, dynamic>) {
            final name = _clip(entry['name'], 120);
            if (name.isNotEmpty && seenCreatorNames.add(name)) {
              final rawId = entry['id'];
              creators.add(
                CrewMember(
                  id: rawId is int && rawId > 0 ? rawId : null,
                  name: name,
                  job: 'Creator',
                  profilePath: sanitizePosterPath(entry['profile_path']),
                ),
              );
            }
          }
        }
      }
    }

    final castList = <CastMember>[];
    final credits = json['credits'];
    if (credits is Map<String, dynamic>) {
      if (isMovie || creators.isEmpty) {
        final rawCrew = credits['crew'];
        if (rawCrew is List) {
          for (final entry in rawCrew) {
            if (entry is Map<String, dynamic>) {
              final job = entry['job'];
              if (job == 'Director' ||
                  (!isMovie && job == 'Executive Producer')) {
                final name = _clip(entry['name'], 120);
                if (name.isNotEmpty && seenCreatorNames.add(name)) {
                  final rawId = entry['id'];
                  creators.add(
                    CrewMember(
                      id: rawId is int && rawId > 0 ? rawId : null,
                      name: name,
                      job: _clip(job, 60),
                      profilePath: sanitizePosterPath(entry['profile_path']),
                    ),
                  );
                  if (creators.length >= 3) break;
                }
              }
            }
          }
        }
      }

      final rawCast = credits['cast'];
      if (rawCast is List) {
        for (final entry in rawCast) {
          if (entry is Map<String, dynamic>) {
            final name = _clip(entry['name'], 120);
            if (name.isEmpty) continue;
            final rawId = entry['id'];
            castList.add(
              CastMember(
                id: rawId is int && rawId > 0 ? rawId : null,
                name: name,
                character: _clip(entry['character'], 120),
                profilePath: sanitizePosterPath(entry['profile_path']),
              ),
            );
            if (castList.length >= 12) break;
          }
        }
      }
    }

    String? trailerKey;
    final videos = json['videos'];
    if (videos is Map<String, dynamic>) {
      final rawVideos = videos['results'];
      if (rawVideos is List) {
        String? teaserFallback;
        for (final v in rawVideos) {
          if (v is! Map<String, dynamic>) continue;
          if (v['site'] != 'YouTube') continue;
          final key = v['key'];
          if (key is! String || !_youtubeKeyPattern.hasMatch(key)) continue;
          final vType = v['type'];
          if (vType == 'Trailer') {
            trailerKey = key;
            break;
          } else if (vType == 'Teaser' && teaserFallback == null) {
            teaserFallback = key;
          }
        }
        trailerKey ??= teaserFallback;
      }
    }

    final recs = <TmdbSearchItem>[];
    final recommendations = json['recommendations'];
    if (recommendations is Map<String, dynamic>) {
      final rawRecs = recommendations['results'];
      if (rawRecs is List) {
        for (final item in rawRecs) {
          final parsed = TmdbSearchItem.tryParse(item, defaultType: mediaType);
          if (parsed != null) {
            recs.add(parsed);
            if (recs.length >= 10) break;
          }
        }
      }
    }

    return RichTitleDetails(
      runtimeMinutes: runtime,
      tagline: _clip(json['tagline'], 300),
      creators: creators,
      cast: castList,
      youtubeTrailerKey: trailerKey,
      recommendations: recs,
      watchProviders: WatchProvidersInfo.fromJson(json['watch/providers']),
    );
  }
}

class PersonDetails {
  const PersonDetails({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography = '',
    this.knownForDepartment = '',
    this.birthYear,
    this.placeOfBirth = '',
    this.credits = const [],
  });

  final int id;
  final String name;
  final String? profilePath;
  final String biography;
  final String knownForDepartment;
  final int? birthYear;
  final String placeOfBirth;
  final List<TmdbSearchItem> credits;

  factory PersonDetails.fromJson(
    Map<String, dynamic> json, {
    required int fallbackId,
  }) {
    final id = _positiveInt(json['id'], fallback: fallbackId);
    final name = _clip(json['name'], 200);
    final profilePath = sanitizePosterPath(json['profile_path']);
    final biography = _clip(json['biography'], 4000);
    final department = _clip(json['known_for_department'], 100);
    final birthYear = parseYear(json['birthday']);
    final placeOfBirth = _clip(json['place_of_birth'], 200);

    final seenKeys = <TitleKey>{};
    final items = <TmdbSearchItem>[];

    final combined = json['combined_credits'];
    if (combined is Map<String, dynamic>) {
      final rawCast = combined['cast'];
      if (rawCast is List) {
        for (final entry in rawCast) {
          final parsed = TmdbSearchItem.tryParse(entry);
          if (parsed != null && seenKeys.add(parsed.key)) {
            items.add(parsed);
          }
        }
      }
      final rawCrew = combined['crew'];
      if (rawCrew is List) {
        for (final entry in rawCrew) {
          if (entry is! Map<String, dynamic>) continue;
          final job = entry['job'];
          if (job != 'Director' &&
              job != 'Creator' &&
              job != 'Executive Producer' &&
              job != 'Writer' &&
              job != 'Screenplay') {
            continue;
          }
          final parsed = TmdbSearchItem.tryParse(entry);
          if (parsed != null && seenKeys.add(parsed.key)) {
            items.add(parsed);
          }
        }
      }
    }

    // Sort by voteCount descending (most well-known works first), then rating.
    items.sort((a, b) {
      final voteCmp = b.voteCount.compareTo(a.voteCount);
      if (voteCmp != 0) return voteCmp;
      return (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0);
    });

    return PersonDetails(
      id: id,
      name: name,
      profilePath: profilePath,
      biography: biography,
      knownForDepartment: department,
      birthYear: birthYear,
      placeOfBirth: placeOfBirth,
      credits: items.take(60).toList(),
    );
  }
}

