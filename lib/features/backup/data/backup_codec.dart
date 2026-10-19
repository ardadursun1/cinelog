import 'dart:convert';

import '../../../core/database/tables.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_models.dart';
import '../../library/domain/watch_status.dart';

const String kBackupAppId = 'movie_tracker';
const int kBackupSchemaVersion = 1;
const int kMaxBackupBytes = 20 * 1024 * 1024;
const int _maxItems = 100000;
const int _maxEpisodesPerItem = 100000;

class BackupEpisode {
  const BackupEpisode(this.season, this.episode, this.watchedAt);

  final int season;
  final int episode;
  final DateTime watchedAt;
}

class BackupItem {
  const BackupItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.originalTitle = '',
    this.posterPath,
    this.overview = '',
    this.releaseYear,
    required this.status,
    this.userRating,
    this.note,
    this.isFavorite = false,
    required this.addedAt,
    required this.updatedAt,
    this.watchedAt,
    this.genres = const [],
    this.seasons = const [],
    this.episodes = const [],
  });

  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String originalTitle;
  final String? posterPath;
  final String overview;
  final int? releaseYear;
  final WatchStatus status;
  final int? userRating;
  final String? note;
  final bool isFavorite;
  final DateTime addedAt;
  final DateTime updatedAt;
  final DateTime? watchedAt;
  final List<Genre> genres;
  final List<SeasonInfo> seasons;
  final List<BackupEpisode> episodes;
}

class BackupDecodeResult {
  const BackupDecodeResult(this.items, this.errors);

  final List<BackupItem> items;
  final List<String> errors;
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Pure JSON <-> model conversion with strict validation of untrusted input.
abstract final class BackupCodec {
  static String encode(List<BackupItem> items, {DateTime? exportedAt}) {
    final data = {
      'app': kBackupAppId,
      'schemaVersion': kBackupSchemaVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'items': [for (final item in items) _encodeItem(item)],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Map<String, Object?> _encodeItem(BackupItem i) => {
        'tmdbId': i.tmdbId,
        'mediaType': i.mediaType.name,
        'title': i.title,
        'originalTitle': i.originalTitle,
        'posterPath': i.posterPath,
        'overview': i.overview,
        'releaseYear': i.releaseYear,
        'status': i.status.name,
        'userRating': i.userRating,
        'note': i.note,
        if (i.isFavorite) 'isFavorite': true,
        'addedAt': i.addedAt.toUtc().toIso8601String(),
        'updatedAt': i.updatedAt.toUtc().toIso8601String(),
        'watchedAt': i.watchedAt?.toUtc().toIso8601String(),
        'genres': [
          for (final g in i.genres) {'id': g.id, 'name': g.name},
        ],
        'seasons': [
          for (final s in i.seasons)
            {'number': s.number, 'episodeCount': s.episodeCount, 'name': s.name},
        ],
        'watchedEpisodes': [
          for (final e in i.episodes)
            {
              'season': e.season,
              'episode': e.episode,
              'watchedAt': e.watchedAt.toUtc().toIso8601String(),
            },
        ],
      };

  /// Throws [BackupFormatException] if the file itself is unusable.
  /// Invalid individual items are skipped and reported in `errors`.
  static BackupDecodeResult decode(String source) {
    final Object? root;
    try {
      root = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException('Dosya geçerli bir JSON değil.');
    }
    if (root is! Map<String, dynamic> || root['app'] != kBackupAppId) {
      throw const BackupFormatException(
        'Bu dosya bir Movie Tracker yedeği değil.',
      );
    }
    final version = root['schemaVersion'];
    if (version is! int || version < 1) {
      throw const BackupFormatException('Yedek sürümü okunamadı.');
    }
    if (version > kBackupSchemaVersion) {
      throw const BackupFormatException(
        'Yedek, uygulamanın daha yeni bir sürümüyle oluşturulmuş.',
      );
    }
    final rawItems = root['items'];
    if (rawItems is! List) {
      throw const BackupFormatException('Yedekte "items" listesi yok.');
    }
    if (rawItems.length > _maxItems) {
      throw const BackupFormatException('Yedekte çok fazla kayıt var.');
    }

    final items = <BackupItem>[];
    final errors = <String>[];
    final seen = <TitleKey>{};
    for (var i = 0; i < rawItems.length; i++) {
      try {
        final item = _decodeItem(rawItems[i]);
        if (!seen.add((tmdbId: item.tmdbId, mediaType: item.mediaType))) {
          throw const FormatException('aynı başlık birden fazla kez var');
        }
        items.add(item);
      } on FormatException catch (e) {
        errors.add('Kayıt #${i + 1}: ${e.message}');
      }
    }
    return BackupDecodeResult(items, errors);
  }

  static BackupItem _decodeItem(Object? raw) {
    if (raw is! Map<String, dynamic>) throw const FormatException('nesne değil');

    final tmdbId = _requireInt(raw, 'tmdbId', min: 1);
    final mediaType = MediaType.tryParse(raw['mediaType']) ??
        (throw const FormatException('geçersiz mediaType'));
    final status = WatchStatus.tryParse(raw['status']) ??
        (throw const FormatException('geçersiz status'));
    final title = _requireString(raw, 'title', max: 500);
    if (title.trim().isEmpty) throw const FormatException('başlık boş');

    final rawPoster = raw['posterPath'];
    final posterPath = sanitizePosterPath(rawPoster);
    if (rawPoster != null && posterPath == null) {
      throw const FormatException('geçersiz posterPath');
    }
    final releaseYear = _optionalInt(raw, 'releaseYear');
    if (releaseYear != null && !isValidYear(releaseYear)) {
      throw const FormatException('geçersiz releaseYear');
    }
    final rating = _optionalInt(raw, 'userRating');
    if (rating != null && (rating < 1 || rating > 10)) {
      throw const FormatException('userRating 1-10 arasında olmalı');
    }
    final note = _optionalString(raw, 'note', max: kNoteMaxLength);
    final rawFav = raw['isFavorite'];
    final isFavorite = rawFav is bool && rawFav;
    final now = DateTime.now();

    return BackupItem(
      tmdbId: tmdbId,
      mediaType: mediaType,
      title: title.trim(),
      originalTitle: _optionalString(raw, 'originalTitle', max: 500) ?? '',
      posterPath: posterPath,
      overview: _optionalString(raw, 'overview', max: 10000) ?? '',
      releaseYear: releaseYear,
      status: status,
      userRating: rating,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      isFavorite: isFavorite,
      addedAt: _optionalDate(raw, 'addedAt') ?? now,
      updatedAt: _optionalDate(raw, 'updatedAt') ?? now,
      watchedAt: _optionalDate(raw, 'watchedAt'),
      genres: _list(raw, 'genres', 200, (g) {
        final map = _asMap(g);
        return Genre(
          _requireInt(map, 'id', min: 1),
          _requireString(map, 'name', max: 100),
        );
      }),
      seasons: _list(raw, 'seasons', SeasonInfo.maxSeasonNumber, (s) {
        final map = _asMap(s);
        return SeasonInfo(
          number: _requireInt(map, 'number',
              min: 1, max: SeasonInfo.maxSeasonNumber),
          episodeCount: _requireInt(map, 'episodeCount',
              min: 0, max: SeasonInfo.maxEpisodeCount),
          name: _optionalString(map, 'name', max: 200) ?? '',
        );
      }),
      episodes: _list(raw, 'watchedEpisodes', _maxEpisodesPerItem, (e) {
        final map = _asMap(e);
        return BackupEpisode(
          _requireInt(map, 'season', min: 1, max: SeasonInfo.maxSeasonNumber),
          _requireInt(map, 'episode', min: 1, max: SeasonInfo.maxEpisodeCount),
          _optionalDate(map, 'watchedAt') ?? now,
        );
      }),
    );
  }

  static Map<String, dynamic> _asMap(Object? v) => v is Map<String, dynamic>
      ? v
      : throw const FormatException('liste elemanı nesne değil');

  static List<T> _list<T>(
    Map<String, dynamic> m,
    String key,
    int maxLength,
    T Function(Object?) parse,
  ) {
    final v = m[key];
    if (v == null) return const [];
    if (v is! List) throw FormatException('$key liste değil');
    if (v.length > maxLength) throw FormatException('$key çok uzun');
    return v.map(parse).toList();
  }

  static int _requireInt(Map<String, dynamic> m, String key,
      {int? min, int? max}) {
    final v = m[key];
    if (v is! int || (min != null && v < min) || (max != null && v > max)) {
      throw FormatException('geçersiz $key');
    }
    return v;
  }

  static int? _optionalInt(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is! int) throw FormatException('geçersiz $key');
    return v;
  }

  static String _requireString(Map<String, dynamic> m, String key,
      {required int max}) {
    final v = m[key];
    if (v is! String || v.length > max) throw FormatException('geçersiz $key');
    return v;
  }

  static String? _optionalString(Map<String, dynamic> m, String key,
      {required int max}) {
    final v = m[key];
    if (v == null) return null;
    if (v is! String || v.length > max) throw FormatException('geçersiz $key');
    return v;
  }

  static DateTime? _optionalDate(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    final parsed = v is String ? DateTime.tryParse(v) : null;
    if (parsed == null) throw FormatException('geçersiz $key');
    return parsed.toLocal();
  }
}
