import '../l10n/app_language.dart';

/// Canonical bilingual (TR / EN) names for standard TMDB movie & TV genre IDs.
/// Grouping by `genreId` and resolving labels through this table prevents
/// duplicate genre entries when titles are added under different app languages.
const Map<int, (String tr, String en)> _kCanonicalGenreNames = {
  // Movie & shared genres
  28: ('Aksiyon', 'Action'),
  12: ('Macera', 'Adventure'),
  16: ('Animasyon', 'Animation'),
  35: ('Komedi', 'Comedy'),
  80: ('Suç', 'Crime'),
  99: ('Belgesel', 'Documentary'),
  18: ('Dram', 'Drama'),
  10751: ('Aile', 'Family'),
  14: ('Fantastik', 'Fantasy'),
  36: ('Tarih', 'History'),
  27: ('Korku', 'Horror'),
  10402: ('Müzik', 'Music'),
  9648: ('Gizem', 'Mystery'),
  10749: ('Romantik', 'Romance'),
  878: ('Bilim Kurgu', 'Sci-Fi'),
  10770: ('TV Filmi', 'TV Movie'),
  53: ('Gerilim', 'Thriller'),
  10752: ('Savaş', 'War'),
  37: ('Vahşi Batı', 'Western'),
  // TV-specific genres
  10759: ('Aksiyon & Macera', 'Action & Adventure'),
  10762: ('Çocuk', 'Kids'),
  10763: ('Haber', 'News'),
  10764: ('Reality', 'Reality'),
  10765: ('Bilim Kurgu & Fantazi', 'Sci-Fi & Fantasy'),
  10766: ('Pembe Dizi', 'Soap'),
  10767: ('Talk Show', 'Talk'),
  10768: ('Savaş & Politik', 'War & Politics'),
};

String localizedGenreName(
  int genreId,
  String fallbackName,
  AppLanguage lang,
) {
  final pair = _kCanonicalGenreNames[genreId];
  if (pair != null) {
    return lang.isEn ? pair.$2 : pair.$1;
  }
  return fallbackName;
}
