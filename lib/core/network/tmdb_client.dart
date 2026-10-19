import 'package:dio/dio.dart';

import '../l10n/app_language.dart';
import '../models/content_category.dart';
import '../models/media_type.dart';
import '../models/title_summary.dart';
import 'tmdb_models.dart';

enum TmdbErrorKind {
  missingKey,
  unauthorized,
  notFound,
  rateLimited,
  timeout,
  network,
  server,
  invalidResponse,
  cancelled,
}

/// Never carries the underlying [DioException]: its request URI may contain
/// the API key and must not end up in logs or UI.
class TmdbException implements Exception {
  const TmdbException(this.kind, [this.statusCode]);

  final TmdbErrorKind kind;
  final int? statusCode;

  String get userMessage => userMessageForLang(AppLanguage.tr);

  String userMessageForLang(AppLanguage lang) => switch (kind) {
        TmdbErrorKind.missingKey => lang.pick(
            'TMDB API anahtarı girilmemiş.',
            'TMDB API key is missing.',
          ),
        TmdbErrorKind.unauthorized => lang.pick(
            'TMDB API anahtarı geçersiz. Ayarlar ekranından kontrol et.',
            'Invalid TMDB API key. Please check Settings.',
          ),
        TmdbErrorKind.notFound => lang.pick(
            'İstenen içerik TMDB\'de bulunamadı.',
            'Requested content was not found on TMDB.',
          ),
        TmdbErrorKind.rateLimited => lang.pick(
            'Çok fazla istek gönderildi. Biraz bekleyip tekrar dene.',
            'Too many requests. Please wait a moment and try again.',
          ),
        TmdbErrorKind.timeout => lang.pick(
            'TMDB yanıt vermedi (zaman aşımı).',
            'TMDB request timed out.',
          ),
        TmdbErrorKind.network => lang.pick(
            'TMDB\'ye bağlanılamadı. İnternet bağlantını kontrol et.',
            'Could not connect to TMDB. Check your internet connection.',
          ),
        TmdbErrorKind.server => lang.pick(
            'TMDB sunucu hatası. Daha sonra tekrar dene.',
            'TMDB server error. Please try again later.',
          ),
        TmdbErrorKind.invalidResponse => lang.pick(
            'TMDB\'den beklenmeyen yanıt geldi.',
            'Received an unexpected response from TMDB.',
          ),
        TmdbErrorKind.cancelled => lang.pick(
            'İstek iptal edildi.',
            'Request cancelled.',
          ),
      };

  @override
  String toString() => 'TmdbException($kind, status: $statusCode)';
}

String userMessageFor(Object error, [AppLanguage lang = AppLanguage.tr]) =>
    error is TmdbException
        ? error.userMessageForLang(lang)
        : lang.pick(
            'Beklenmeyen bir hata oluştu.',
            'An unexpected error occurred.',
          );

class TmdbClient {
  TmdbClient(String apiKey, {String language = 'tr-TR', Dio? dio})
      : _dio = dio ?? Dio() {
    final key = apiKey.trim();
    final bearer = isReadAccessToken(key);
    _dio.options = BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3/',
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      responseType: ResponseType.json,
      queryParameters: {
        'language': language,
        if (!bearer) 'api_key': key,
      },
      headers: {
        'Accept': 'application/json',
        if (bearer) 'Authorization': 'Bearer $key',
      },
    );
  }

  static const Duration _timeout = Duration(seconds: 15);
  static const int maxQueryLength = 200;
  static const int _maxKeyLength = 1024;
  static final RegExp _keyPattern = RegExp(r'^[A-Za-z0-9._\-]+$');

  final Dio _dio;

  /// TMDB accepts either a v3 "API Key" or a v4 "Read Access Token" (JWT).
  static bool isReadAccessToken(String key) =>
      key.startsWith('eyJ') && key.contains('.');

  static bool isPlausibleKey(String key) =>
      key.isNotEmpty &&
      key.length <= _maxKeyLength &&
      _keyPattern.hasMatch(key);

  Future<TmdbSearchPage> searchMulti(
    String query, {
    int page = 1,
    Set<String> excludedCategoryKeys = const {},
    CancelToken? cancelToken,
  }) async {
    final trimmed = query.trim();
    final safeQuery = trimmed.length > maxQueryLength
        ? trimmed.substring(0, maxQueryLength)
        : trimmed;
    final json = await _get(
      'search/multi',
      query: {'query': safeQuery, 'page': page, 'include_adult': false},
      cancelToken: cancelToken,
    );
    final parsed = TmdbSearchPage.fromJson(json);
    return TmdbSearchPage(
      results: _filterExcluded(parsed.results, excludedCategoryKeys),
      page: parsed.page,
      totalPages: parsed.totalPages,
    );
  }

  static const Set<String> _nicheCategoryKeys = {
    'documentary',
    'western',
    'music',
    'war',
    'history',
    'reality',
  };

  static int _minVoteCountFor(MediaType type, ContentCategory? category) {
    final isMovie = type == MediaType.movie;
    if (category == null) {
      return isMovie ? 3000 : 1000;
    }
    if (_nicheCategoryKeys.contains(category.key)) {
      return isMovie ? 400 : 150;
    }
    if (category.key == 'anime') {
      return isMovie ? 800 : 500;
    }
    return isMovie ? 1500 : 600;
  }

  static List<TmdbSearchItem> _sortByWeightedRating(List<TmdbSearchItem> items) {
    final sorted = List<TmdbSearchItem>.of(items);
    sorted.sort((a, b) {
      final scoreCmp = (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0);
      if (scoreCmp != 0) return scoreCmp;
      return b.voteCount.compareTo(a.voteCount);
    });
    return sorted;
  }

  Future<TmdbSearchPage> discover(
    MediaType type, {
    required bool sortByRating,
    ContentCategory? category,
    Set<String> excludedCategoryKeys = const {},
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final includeGenres = category?.genreIdsFor(type) ?? const <int>[];
    if (category != null && includeGenres.isEmpty) {
      return TmdbSearchPage(results: const [], page: page, totalPages: 0);
    }

    final excludedGenres = <int>{
      // Exclude concert/music specials (10402) and TV movies (10770) from the
      // general top-rated movie feed unless specifically requested.
      if (sortByRating && category == null && type == MediaType.movie) ...[
        10402,
        10770,
      ],
    };
    final excludedKeywords = <int>{};
    for (final key in excludedCategoryKeys) {
      if (key == category?.key) continue;
      final cat = kCategoryByKey[key];
      if (cat == null) continue;
      excludedGenres.addAll(cat.genreIdsFor(type));
      if (cat.tmdbKeywordId != null) {
        excludedKeywords.add(cat.tmdbKeywordId!);
      }
    }
    excludedGenres.removeAll(includeGenres);

    final query = <String, dynamic>{
      'page': page,
      'include_adult': false,
      if (type == MediaType.movie) 'include_video': false,
      'sort_by': sortByRating ? 'vote_average.desc' : 'popularity.desc',
      if (sortByRating) 'vote_count.gte': _minVoteCountFor(type, category),
      if (includeGenres.isNotEmpty) 'with_genres': includeGenres.join('|'),
      if (category?.includeOriginalLanguage != null)
        'with_original_language': category!.includeOriginalLanguage,
      if (excludedGenres.isNotEmpty) 'without_genres': excludedGenres.join(','),
      if (excludedKeywords.isNotEmpty)
        'without_keywords': excludedKeywords.join(','),
    };

    final json = await _get(
      'discover/${type.name}',
      query: query,
      cancelToken: cancelToken,
    );
    final parsed = TmdbSearchPage.fromJson(json, defaultType: type);
    final filtered = _filterExcluded(parsed.results, excludedCategoryKeys);
    return TmdbSearchPage(
      results: sortByRating ? _sortByWeightedRating(filtered) : filtered,
      page: parsed.page,
      totalPages: parsed.totalPages,
    );
  }

  Future<TmdbSearchPage> discoverCombined({
    required bool sortByRating,
    ContentCategory? category,
    Set<String> excludedCategoryKeys = const {},
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final pages = await Future.wait([
      discover(
        MediaType.movie,
        sortByRating: sortByRating,
        category: category,
        excludedCategoryKeys: excludedCategoryKeys,
        page: page,
        cancelToken: cancelToken,
      ),
      discover(
        MediaType.tv,
        sortByRating: sortByRating,
        category: category,
        excludedCategoryKeys: excludedCategoryKeys,
        page: page,
        cancelToken: cancelToken,
      ),
    ]);
    final movies = pages[0].results;
    final shows = pages[1].results;
    final merged = <TmdbSearchItem>[];
    final maxLen =
        movies.length > shows.length ? movies.length : shows.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < movies.length) merged.add(movies[i]);
      if (i < shows.length) merged.add(shows[i]);
    }
    final maxTotalPages = pages[0].totalPages > pages[1].totalPages
        ? pages[0].totalPages
        : pages[1].totalPages;
    return TmdbSearchPage(
      results: sortByRating ? _sortByWeightedRating(merged) : merged,
      page: page,
      totalPages: maxTotalPages,
    );
  }

  static List<TmdbSearchItem> _filterExcluded(
    List<TmdbSearchItem> items,
    Set<String> excludedKeys,
  ) {
    if (excludedKeys.isEmpty) return items;
    final excluded = [
      for (final key in excludedKeys) ?kCategoryByKey[key],
    ];
    if (excluded.isEmpty) return items;
    return [
      for (final item in items)
        if (!excluded.any((cat) => cat.matchesExcluded(item))) item,
    ];
  }

  Future<List<Genre>> fetchGenres(MediaType type) async =>
      parseGenreList(await _get('genre/${type.name}/list'));

  Future<List<SeasonInfo>> fetchTvSeasons(int tvId) async =>
      SeasonInfo.listFromTvDetails(await _get('tv/$tvId'));

  Future<RichTitleDetails> fetchRichDetails(
    TitleKey key, {
    Set<String> excludedCategoryKeys = const {},
  }) async {
    final json = await _get(
      '${key.mediaType.name}/${key.tmdbId}',
      query: const {
        'append_to_response':
            'credits,videos,recommendations,watch/providers',
        'include_video_language': 'tr,en,null',
      },
    );
    final parsed = RichTitleDetails.fromJson(json, mediaType: key.mediaType);
    if (excludedCategoryKeys.isEmpty) return parsed;
    return RichTitleDetails(
      runtimeMinutes: parsed.runtimeMinutes,
      tagline: parsed.tagline,
      creators: parsed.creators,
      cast: parsed.cast,
      youtubeTrailerKey: parsed.youtubeTrailerKey,
      recommendations: _filterExcluded(
        parsed.recommendations,
        excludedCategoryKeys,
      ),
      watchProviders: parsed.watchProviders,
    );
  }

  Future<PersonDetails> fetchPersonDetails(
    int personId, {
    Set<String> excludedCategoryKeys = const {},
  }) async {
    final json = await _get(
      'person/$personId',
      query: const {
        'append_to_response': 'combined_credits',
      },
    );
    final parsed = PersonDetails.fromJson(json, fallbackId: personId);
    if (excludedCategoryKeys.isEmpty) return parsed;
    return PersonDetails(
      id: parsed.id,
      name: parsed.name,
      profilePath: parsed.profilePath,
      biography: parsed.biography,
      knownForDepartment: parsed.knownForDepartment,
      birthYear: parsed.birthYear,
      placeOfBirth: parsed.placeOfBirth,
      credits: _filterExcluded(parsed.credits, excludedCategoryKeys),
    );
  }

  /// Throws [TmdbException] with [TmdbErrorKind.unauthorized] for bad keys.
  Future<void> validateKey() => _get('authentication');

  void close() => _dio.close(force: true);

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      throw const TmdbException(TmdbErrorKind.invalidResponse);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static TmdbException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TmdbException(TmdbErrorKind.timeout);
      case DioExceptionType.cancel:
        return const TmdbException(TmdbErrorKind.cancelled);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final kind = switch (status) {
          401 => TmdbErrorKind.unauthorized,
          404 => TmdbErrorKind.notFound,
          429 => TmdbErrorKind.rateLimited,
          final s? when s >= 500 => TmdbErrorKind.server,
          _ => TmdbErrorKind.invalidResponse,
        };
        return TmdbException(kind, status);
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const TmdbException(TmdbErrorKind.network);
    }
  }
}
