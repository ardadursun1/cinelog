import 'dart:typed_data';

import '../../../core/database/tables.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/network/tmdb_models.dart';
import '../../library/domain/watch_status.dart';
import 'zip_archive_reader.dart';

const int kMaxLetterboxdCsvBytes = 20 * 1024 * 1024;
const int _maxCsvRows = 100000;
const int _maxFilmNameLength = 500;

enum LetterboxdFileKind {
  watched,
  watchlist,
  ratings,
  diary,
  reviews,
  likedFilms,
}

class LetterboxdFormatException implements Exception {
  const LetterboxdFormatException(this.messageTr, this.messageEn);

  final String messageTr;
  final String messageEn;

  String messageFor(AppLanguage lang) => lang.pick(messageTr, messageEn);

  @override
  String toString() => 'LetterboxdFormatException: $messageEn';
}

class LetterboxdFilmEntry {
  const LetterboxdFilmEntry({
    required this.name,
    this.year,
    this.tmdbId,
    this.letterboxdUri,
    required this.status,
    this.userRating,
    this.note,
    this.isFavorite = false,
    this.addedAt,
    this.watchedAt,
  });

  final String name;
  final int? year;
  final int? tmdbId;
  final String? letterboxdUri;
  final WatchStatus status;
  final int? userRating;
  final String? note;
  final bool isFavorite;
  final DateTime? addedAt;
  final DateTime? watchedAt;

  String get displayLabel => year != null ? '$name ($year)' : name;
}

class LetterboxdParseResult {
  const LetterboxdParseResult({
    required this.entries,
    required this.skippedRows,
  });

  final List<LetterboxdFilmEntry> entries;
  final int skippedRows;
}

/// RFC 4180 compliant CSV parser and Letterboxd export merger.
abstract final class LetterboxdCodec {
  static LetterboxdParseResult decodeZipArchive(Uint8List archiveBytes) {
    final Map<String, String> extracted;
    try {
      extracted = ZipArchiveReader.extractTextFiles(
        archiveBytes,
        shouldExtract: (path) => classifyZipPath(path) != null,
      );
    } on ZipFormatException catch (e) {
      throw LetterboxdFormatException(e.messageTr, e.messageEn);
    }

    if (extracted.isEmpty) {
      throw const LetterboxdFormatException(
        'ZIP arşivinde Letterboxd CSV dosyası (watched.csv, watchlist.csv, ratings.csv, diary.csv, reviews.csv) bulunamadı.',
        'No Letterboxd CSV files (watched.csv, watchlist.csv, ratings.csv, diary.csv, reviews.csv) were found in the ZIP archive.',
      );
    }

    final classified = <({LetterboxdFileKind kind, String content})>[];
    for (final entry in extracted.entries) {
      final kind = classifyZipPath(entry.key);
      if (kind != null) {
        classified.add((kind: kind, content: entry.value));
      }
    }
    return _mergeClassifiedFiles(classified);
  }

  static LetterboxdParseResult decodeCsvFiles(
    List<({String fileName, String content})> files,
  ) {
    if (files.isEmpty) {
      throw const LetterboxdFormatException(
        'İçe aktarılacak dosya seçilmedi.',
        'No files selected for import.',
      );
    }

    final classified = <({LetterboxdFileKind kind, String content})>[];
    for (final file in files) {
      final rows = parseCsv(file.content);
      if (rows.isEmpty) continue;
      final kind = classifyStandaloneCsv(file.fileName, rows.first);
      if (kind != null) {
        classified.add((kind: kind, content: file.content));
      }
    }

    if (classified.isEmpty) {
      throw const LetterboxdFormatException(
        'Seçilen CSV dosyası geçerli bir Letterboxd dışa aktarma formatında değil.',
        'Selected CSV file does not match a valid Letterboxd export format.',
      );
    }

    return _mergeClassifiedFiles(classified);
  }

  /// Recognizes Letterboxd export CSVs inside a ZIP while ignoring `deleted/`,
  /// `orphaned/`, `lists/`, and non-film likes (`likes/reviews.csv`, etc.).
  static LetterboxdFileKind? classifyZipPath(String normalizedPath) {
    final lower = normalizedPath.toLowerCase();
    if (!lower.endsWith('.csv')) return null;

    final segments = lower.split('/');
    for (final seg in segments) {
      if (seg.isEmpty ||
          seg.startsWith('.') ||
          seg == '__macosx' ||
          seg == 'deleted' ||
          seg == 'orphaned' ||
          seg == 'lists') {
        return null;
      }
    }

    final fileName = segments.last;
    final parentDir = segments.length >= 2 ? segments[segments.length - 2] : '';

    if (parentDir == 'likes') {
      return fileName == 'films.csv' ? LetterboxdFileKind.likedFilms : null;
    }
    if (segments.contains('likes')) {
      return null;
    }

    return switch (fileName) {
      'watched.csv' => LetterboxdFileKind.watched,
      'watchlist.csv' => LetterboxdFileKind.watchlist,
      'ratings.csv' => LetterboxdFileKind.ratings,
      'diary.csv' => LetterboxdFileKind.diary,
      'reviews.csv' => LetterboxdFileKind.reviews,
      _ => null,
    };
  }

  /// Classifies standalone `.csv` files selected directly by the user based on
  /// both filename hints and CSV column headers.
  static LetterboxdFileKind? classifyStandaloneCsv(
    String fileName,
    List<String> rawHeaders,
  ) {
    final headers = {
      for (final h in rawHeaders) _normalizeHeader(h),
    };
    final hasTitle = headers.contains('name') ||
        headers.contains('title') ||
        headers.contains('tmdbid');
    if (!hasTitle) return null;

    final lowerName = fileName.replaceAll('\\', '/').split('/').last.toLowerCase();
    if (lowerName.contains('watchlist')) return LetterboxdFileKind.watchlist;
    if (lowerName == 'films.csv' || lowerName.contains('like')) {
      return LetterboxdFileKind.likedFilms;
    }
    if (headers.contains('review')) return LetterboxdFileKind.reviews;
    if (headers.contains('watcheddate') || headers.contains('rewatch')) {
      return LetterboxdFileKind.diary;
    }
    if (headers.contains('rating') || headers.contains('rating10')) {
      return LetterboxdFileKind.ratings;
    }
    if (lowerName.contains('watched')) return LetterboxdFileKind.watched;
    if (headers.contains('letterboxduri') || headers.contains('year')) {
      return LetterboxdFileKind.watched;
    }
    return null;
  }

  /// Pure RFC 4180 state-machine CSV parser supporting quoted fields, escaped
  /// quotes (`""`), embedded commas, multiline cells, and UTF-8 BOM.
  static List<List<String>> parseCsv(String rawSource) {
    final source = rawSource.startsWith('\uFEFF')
        ? rawSource.substring(1)
        : rawSource;
    if (source.trim().isEmpty) return const [];

    final rows = <List<String>>[];
    var currentRow = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;
    var i = 0;

    void finishRow() {
      currentRow.add(cell.toString());
      cell.clear();
      // Ignore completely blank trailing/intermediate lines.
      if (currentRow.length > 1 || currentRow.first.trim().isNotEmpty) {
        if (rows.length >= _maxCsvRows) {
          throw const LetterboxdFormatException(
            'CSV dosyasında çok fazla satır var (>100.000).',
            'CSV file contains too many rows (>100,000).',
          );
        }
        rows.add(currentRow);
      }
      currentRow = <String>[];
    }

    while (i < source.length) {
      final ch = source[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < source.length && source[i + 1] == '"') {
            cell.write('"');
            i += 2;
          } else {
            inQuotes = false;
            i++;
          }
        } else {
          cell.write(ch);
          i++;
        }
      } else {
        if (ch == '"' && cell.isEmpty) {
          inQuotes = true;
          i++;
        } else if (ch == ',') {
          currentRow.add(cell.toString());
          cell.clear();
          i++;
        } else if (ch == '\r') {
          finishRow();
          if (i + 1 < source.length && source[i + 1] == '\n') {
            i += 2;
          } else {
            i++;
          }
        } else if (ch == '\n') {
          finishRow();
          i++;
        } else {
          cell.write(ch);
          i++;
        }
      }
    }

    if (cell.isNotEmpty || currentRow.isNotEmpty) {
      finishRow();
    }

    return rows;
  }

  static LetterboxdParseResult _mergeClassifiedFiles(
    List<({LetterboxdFileKind kind, String content})> files,
  ) {
    // Process in deterministic order so authoritative ratings/reviews merge cleanly.
    const order = [
      LetterboxdFileKind.watchlist,
      LetterboxdFileKind.watched,
      LetterboxdFileKind.diary,
      LetterboxdFileKind.reviews,
      LetterboxdFileKind.ratings,
      LetterboxdFileKind.likedFilms,
    ];
    final sorted = List.of(files)
      ..sort((a, b) => order.indexOf(a.kind).compareTo(order.indexOf(b.kind)));

    final accumulators = <String, _FilmAccumulator>{};
    final uriToKey = <String, String>{};
    var skippedRows = 0;

    for (final file in sorted) {
      final rows = parseCsv(file.content);
      if (rows.length <= 1) continue;

      final headerIndex = <String, int>{};
      final rawHeaders = rows.first;
      for (var c = 0; c < rawHeaders.length; c++) {
        headerIndex.putIfAbsent(_normalizeHeader(rawHeaders[c]), () => c);
      }

      String? cellAt(List<String> row, List<String> candidates) {
        for (final name in candidates) {
          final idx = headerIndex[name];
          if (idx != null && idx < row.length) {
            final v = row[idx].trim();
            if (v.isNotEmpty) return v;
          }
        }
        return null;
      }

      for (var r = 1; r < rows.length; r++) {
        final row = rows[r];
        final rawName = cellAt(row, const ['name', 'title']);
        final rawTmdbId = cellAt(row, const ['tmdbid']);
        final parsedTmdbId =
            rawTmdbId != null ? int.tryParse(rawTmdbId) : null;
        final validTmdbId =
            parsedTmdbId != null && parsedTmdbId > 0 ? parsedTmdbId : null;

        if ((rawName == null || rawName.isEmpty) && validTmdbId == null) {
          skippedRows++;
          continue;
        }

        final name = _clipText(rawName ?? 'TMDB #$validTmdbId', _maxFilmNameLength);
        final rawYear = cellAt(row, const ['year']);
        final parsedYear = rawYear != null ? int.tryParse(rawYear) : null;
        final year = isValidYear(parsedYear) ? parsedYear : null;

        final uri = _sanitizeLetterboxdUri(
          cellAt(row, const ['letterboxduri', 'uri', 'url']),
        );

        // Film-level files share the canonical film URI; diary & reviews use per-entry URIs.
        final isFilmLevelUri = file.kind == LetterboxdFileKind.watched ||
            file.kind == LetterboxdFileKind.watchlist ||
            file.kind == LetterboxdFileKind.ratings ||
            file.kind == LetterboxdFileKind.likedFilms;

        String dedupKey;
        if (validTmdbId != null) {
          dedupKey = 'tmdb:$validTmdbId';
        } else if (isFilmLevelUri && uri != null && uriToKey.containsKey(uri)) {
          dedupKey = uriToKey[uri]!;
        } else {
          dedupKey = '${normalizeLookupTitle(name)}|${year ?? ''}';
        }
        if (isFilmLevelUri && uri != null) {
          uriToKey.putIfAbsent(uri, () => dedupKey);
        }

        final acc = accumulators.putIfAbsent(
          dedupKey,
          () => _FilmAccumulator(name: name, year: year),
        );
        if (acc.year == null && year != null) acc.year = year;
        if (acc.tmdbId == null && validTmdbId != null) acc.tmdbId = validTmdbId;
        if (isFilmLevelUri && uri != null && acc.letterboxdUri == null) {
          acc.letterboxdUri = uri;
        }

        final logDate = _parseDate(cellAt(row, const ['date']));
        final watchedDate = _parseDate(cellAt(row, const ['watcheddate']));
        final rating = _parseRating(
          starRating: cellAt(row, const ['rating']),
          rating10: cellAt(row, const ['rating10']),
        );
        final reviewText = file.kind == LetterboxdFileKind.reviews
            ? _cleanReviewText(cellAt(row, const ['review']))
            : null;

        acc.recordEarliestAdded(logDate ?? watchedDate);

        switch (file.kind) {
          case LetterboxdFileKind.watchlist:
            acc.markPlanned();
          case LetterboxdFileKind.watched:
            acc.markWatched(watchedDate ?? logDate);
          case LetterboxdFileKind.diary:
            acc.markWatched(watchedDate ?? logDate);
            if (rating != null) {
              acc.recordDiaryRating(rating, watchedDate ?? logDate);
            }
          case LetterboxdFileKind.reviews:
            acc.markWatched(watchedDate ?? logDate);
            if (rating != null) {
              acc.recordDiaryRating(rating, watchedDate ?? logDate);
            }
            if (reviewText != null && reviewText.isNotEmpty) {
              acc.recordReview(reviewText, watchedDate ?? logDate);
            }
          case LetterboxdFileKind.ratings:
            acc.markWatched(logDate);
            if (rating != null) {
              acc.authoritativeRating = rating;
            }
          case LetterboxdFileKind.likedFilms:
            acc.isFavorite = true;
            // If a film ONLY appears in likes/films.csv, treat it as watched.
            acc.markLikedFallback(logDate);
        }
      }
    }

    final entries = [
      for (final acc in accumulators.values) acc.build(),
    ];

    if (entries.isEmpty) {
      throw const LetterboxdFormatException(
        'Seçilen dosyada içe aktarılabilecek film kaydı bulunamadı.',
        'No importable film entries were found in the selected file.',
      );
    }

    return LetterboxdParseResult(entries: entries, skippedRows: skippedRows);
  }

  static String _normalizeHeader(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

  static String normalizeLookupTitle(String title) => title
      .trim()
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  static String _clipText(String value, int maxLength) {
    final trimmed = value.trim();
    return trimmed.length <= maxLength
        ? trimmed
        : trimmed.substring(0, maxLength);
  }

  static String? _sanitizeLetterboxdUri(String? raw) {
    if (raw == null || raw.length > 200) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    final host = uri.host.toLowerCase();
    if (host == 'boxd.it' ||
        host == 'letterboxd.com' ||
        host == 'www.letterboxd.com') {
      return raw;
    }
    return null;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    if (parsed.year < 1900 || parsed.year > 2100) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  /// Converts Letterboxd 0.5–5.0 star scale (or 1–10 Rating10) to 1–10 integer.
  static int? _parseRating({String? starRating, String? rating10}) {
    if (rating10 != null) {
      final val10 = double.tryParse(rating10.replaceAll(',', '.'));
      if (val10 != null && val10 >= 1 && val10 <= 10) {
        return val10.round().clamp(1, 10);
      }
    }
    if (starRating != null) {
      final stars = double.tryParse(starRating.replaceAll(',', '.'));
      if (stars != null && stars >= 0.5 && stars <= 5.0) {
        return (stars * 2).round().clamp(1, 10);
      }
    }
    return null;
  }

  static String? _cleanReviewText(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var text = raw
        .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', '’')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&nbsp;', ' ');

    text = text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.isEmpty) return null;
    if (text.length <= kNoteMaxLength) return text;
    return '${text.substring(0, kNoteMaxLength - 1).trimRight()}…';
  }
}

class _FilmAccumulator {
  _FilmAccumulator({required this.name, this.year});

  final String name;
  int? year;
  int? tmdbId;
  String? letterboxdUri;

  bool _hasWatched = false;
  bool _hasPlanned = false;
  bool isFavorite = false;

  int? authoritativeRating;
  int? _latestDiaryRating;
  DateTime? _latestDiaryRatingDate;

  String? _latestReview;
  DateTime? _latestReviewDate;

  DateTime? _earliestAddedAt;
  DateTime? _latestWatchedAt;

  void recordEarliestAdded(DateTime? date) {
    if (date == null) return;
    if (_earliestAddedAt == null || date.isBefore(_earliestAddedAt!)) {
      _earliestAddedAt = date;
    }
  }

  void markPlanned() {
    _hasPlanned = true;
  }

  void markWatched(DateTime? watchedDate) {
    _hasWatched = true;
    if (watchedDate != null) {
      if (_latestWatchedAt == null || watchedDate.isAfter(_latestWatchedAt!)) {
        _latestWatchedAt = watchedDate;
      }
    }
  }

  void markLikedFallback(DateTime? likedDate) {
    if (!_hasWatched && !_hasPlanned && likedDate != null) {
      _latestWatchedAt ??= likedDate;
    }
  }

  void recordDiaryRating(int rating, DateTime? date) {
    if (_latestDiaryRating == null ||
        (date != null &&
            (_latestDiaryRatingDate == null ||
                !date.isBefore(_latestDiaryRatingDate!)))) {
      _latestDiaryRating = rating;
      _latestDiaryRatingDate = date;
    }
  }

  void recordReview(String review, DateTime? date) {
    if (_latestReview == null ||
        (date != null &&
            (_latestReviewDate == null || !date.isBefore(_latestReviewDate!)))) {
      _latestReview = review;
      _latestReviewDate = date;
    }
  }

  LetterboxdFilmEntry build() {
    final status = _hasWatched || !_hasPlanned
        ? WatchStatus.watched
        : WatchStatus.planned;
    return LetterboxdFilmEntry(
      name: name,
      year: year,
      tmdbId: tmdbId,
      letterboxdUri: letterboxdUri,
      status: status,
      userRating: authoritativeRating ?? _latestDiaryRating,
      note: _latestReview,
      isFavorite: isFavorite,
      addedAt: _earliestAddedAt,
      watchedAt: status == WatchStatus.watched
          ? (_latestWatchedAt ?? _earliestAddedAt)
          : null,
    );
  }
}
