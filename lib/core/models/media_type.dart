import '../l10n/app_language.dart';

enum MediaType {
  movie('Film', 'Movie'),
  tv('Dizi', 'TV Show');

  const MediaType(this.label, this.labelEn);

  final String label;
  final String labelEn;

  String labelFor(AppLanguage lang) => lang.isEn ? labelEn : label;

  static MediaType? tryParse(Object? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

