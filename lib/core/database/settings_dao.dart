import 'app_database.dart';

abstract final class SettingKeys {
  static const tmdbApiKey = 'tmdb_api_key';
  static const themeMode = 'theme_mode';
  static const excludedCategories = 'excluded_categories';
  static const language = 'language';
  static const favoriteTitles = 'favorite_titles';
}

class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  Stream<String?> watch(String name) {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.name.equals(name));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  /// Writes [value]; `null` removes the setting.
  Future<void> write(String name, String? value) async {
    if (value == null) {
      await (_db.delete(_db.appSettings)..where((t) => t.name.equals(name)))
          .go();
      return;
    }
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(name: name, value: value),
        );
  }
}
