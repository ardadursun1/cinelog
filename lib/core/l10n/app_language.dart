enum AppLanguage {
  tr('Türkçe', 'tr-TR'),
  en('English', 'en-US');

  const AppLanguage(this.displayName, this.tmdbLocale);

  final String displayName;
  final String tmdbLocale;

  bool get isEn => this == AppLanguage.en;

  String pick(String trText, String enText) =>
      this == AppLanguage.en ? enText : trText;

  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.en : AppLanguage.tr;
}
