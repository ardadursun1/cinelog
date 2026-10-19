import '../../../core/l10n/app_language.dart';

enum WatchStatus {
  planned('İzlenecek', 'Plan to Watch'),
  watching('İzliyorum', 'Watching'),
  watched('İzledim', 'Watched');

  const WatchStatus(this.label, this.labelEn);

  final String label;
  final String labelEn;

  String labelFor(AppLanguage lang) => lang.isEn ? labelEn : label;

  static WatchStatus? tryParse(Object? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

