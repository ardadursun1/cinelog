import '../../../core/l10n/app_language.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import 'library_entry.dart';
import 'watch_status.dart';

enum LibrarySort {
  addedDesc('Eklenme (yeni → eski)', 'Added (newest → oldest)'),
  titleAsc('Başlık (A → Z)', 'Title (A → Z)'),
  ratingDesc('Puanım (yüksek → düşük)', 'My Rating (high → low)'),
  yearDesc('Yapım yılı (yeni → eski)', 'Release Year (newest → oldest)');

  const LibrarySort(this.label, this.labelEn);

  final String label;
  final String labelEn;

  String labelFor(AppLanguage lang) => lang.isEn ? labelEn : label;
}

class LibraryFilter {
  const LibraryFilter({
    this.status,
    this.mediaType,
    this.favoritesOnly = false,
    this.genreId,
    this.searchQuery = '',
    this.sort = LibrarySort.addedDesc,
  });

  final WatchStatus? status;
  final MediaType? mediaType;
  final bool favoritesOnly;
  final int? genreId;
  final String searchQuery;
  final LibrarySort sort;

  LibraryFilter copyWith({
    WatchStatus? Function()? status,
    MediaType? Function()? mediaType,
    bool? favoritesOnly,
    int? Function()? genreId,
    String? searchQuery,
    LibrarySort? sort,
  }) =>
      LibraryFilter(
        status: status != null ? status() : this.status,
        mediaType: mediaType != null ? mediaType() : this.mediaType,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        genreId: genreId != null ? genreId() : this.genreId,
        searchQuery: searchQuery ?? this.searchQuery,
        sort: sort ?? this.sort,
      );

  List<LibraryEntry> apply(
    List<LibraryEntry> entries, {
    Set<TitleKey> favorites = const {},
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final result = entries
        .where((e) => status == null || e.item.status == status)
        .where((e) => mediaType == null || e.item.mediaType == mediaType)
        .where((e) => !favoritesOnly || favorites.contains(e.key))
        .where(
          (e) =>
              genreId == null || e.genres.any((g) => g.id == genreId),
        )
        .where((e) => _matchesQuery(e, normalizedQuery))
        .toList()
      ..sort(_compare);
    return result;
  }

  static bool _matchesQuery(LibraryEntry entry, String query) {
    if (query.isEmpty) return true;
    final item = entry.item;
    if (item.title.toLowerCase().contains(query)) return true;
    if (item.originalTitle.toLowerCase().contains(query)) return true;
    final note = item.note;
    if (note != null && note.toLowerCase().contains(query)) return true;
    for (final g in entry.genres) {
      if (g.name.toLowerCase().contains(query)) return true;
    }
    return false;
  }

  int _compare(LibraryEntry a, LibraryEntry b) {
    final byTitle =
        a.item.title.toLowerCase().compareTo(b.item.title.toLowerCase());
    switch (sort) {
      case LibrarySort.addedDesc:
        return b.item.addedAt.compareTo(a.item.addedAt);
      case LibrarySort.titleAsc:
        return byTitle;
      case LibrarySort.ratingDesc:
        final cmp = _compareNullableDesc(a.item.userRating, b.item.userRating);
        return cmp != 0 ? cmp : byTitle;
      case LibrarySort.yearDesc:
        final cmp =
            _compareNullableDesc(a.item.releaseYear, b.item.releaseYear);
        return cmp != 0 ? cmp : byTitle;
    }
  }

  /// Descending, with nulls last.
  static int _compareNullableDesc(int? a, int? b) {
    if (a == b) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
