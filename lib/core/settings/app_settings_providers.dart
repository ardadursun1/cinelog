import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../database/app_database.dart';
import '../database/settings_dao.dart';
import '../l10n/app_language.dart';
import '../models/content_category.dart';
import '../models/media_type.dart';
import '../models/title_summary.dart';

final settingsDaoProvider =
    Provider<SettingsDao>((ref) => SettingsDao(ref.watch(appDatabaseProvider)));

final storedApiKeyProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsDaoProvider).watch(SettingKeys.tmdbApiKey),
);

enum ApiKeySource { loading, settings, environment, none }

class ApiKeyState {
  const ApiKeyState(this.source, [this.key]);

  final ApiKeySource source;
  final String? key;

  bool get hasKey => key != null;
}

/// Priority: key saved in Settings > dev key from env.json > none.
final apiKeyProvider = Provider<ApiKeyState>((ref) {
  final stored = ref.watch(storedApiKeyProvider);
  if (!stored.hasValue && stored.isLoading) {
    return const ApiKeyState(ApiKeySource.loading);
  }
  final value = stored.value;
  if (value != null && value.isNotEmpty) {
    return ApiKeyState(ApiKeySource.settings, value);
  }
  if (kTmdbApiKeyFromEnv.isNotEmpty) {
    return const ApiKeyState(ApiKeySource.environment, kTmdbApiKeyFromEnv);
  }
  return const ApiKeyState(ApiKeySource.none);
});

final themeModeProvider = StreamProvider<ThemeMode>((ref) => ref
    .watch(settingsDaoProvider)
    .watch(SettingKeys.themeMode)
    .map((value) => ThemeMode.values.asNameMap()[value] ?? ThemeMode.system));

final appLanguageProvider = StreamProvider<AppLanguage>((ref) => ref
    .watch(settingsDaoProvider)
    .watch(SettingKeys.language)
    .map(AppLanguage.fromCode));

final currentLanguageProvider = Provider<AppLanguage>(
  (ref) => ref.watch(appLanguageProvider).value ?? AppLanguage.tr,
);

/// Persisted set of category keys (e.g. `'anime'`) that the user chose to hide.
final excludedCategoriesProvider = StreamProvider<Set<String>>((ref) => ref
    .watch(settingsDaoProvider)
    .watch(SettingKeys.excludedCategories)
    .map((raw) {
      if (raw == null || raw.isEmpty) return const <String>{};
      return {
        for (final part in raw.split(','))
          if (kCategoryByKey.containsKey(part.trim())) part.trim(),
      };
    }));

String encodeTitleKey(TitleKey key) => '${key.mediaType.name}:${key.tmdbId}';

TitleKey? decodeTitleKey(String token) {
  final trimmed = token.trim();
  final idx = trimmed.indexOf(':');
  if (idx <= 0 || idx >= trimmed.length - 1) return null;
  final type = MediaType.tryParse(trimmed.substring(0, idx));
  final id = int.tryParse(trimmed.substring(idx + 1));
  if (type == null || id == null || id <= 0) return null;
  return (tmdbId: id, mediaType: type);
}

Set<TitleKey> parseFavoriteTitleKeys(String? raw) {
  if (raw == null || raw.isEmpty) return const <TitleKey>{};
  final result = <TitleKey>{};
  for (final part in raw.split(',')) {
    final decoded = decodeTitleKey(part);
    if (decoded != null) result.add(decoded);
  }
  return result;
}

String serializeFavoriteTitleKeys(Iterable<TitleKey> keys) =>
    keys.map(encodeTitleKey).join(',');

final favoriteTitlesProvider = StreamProvider<Set<TitleKey>>((ref) => ref
    .watch(settingsDaoProvider)
    .watch(SettingKeys.favoriteTitles)
    .map(parseFavoriteTitleKeys));

Future<bool> toggleFavoriteTitle(WidgetRef ref, TitleKey key) async {
  final current = Set<TitleKey>.of(
    ref.read(favoriteTitlesProvider).value ?? const <TitleKey>{},
  );
  final added = current.add(key);
  if (!added) current.remove(key);
  await ref.read(settingsDaoProvider).write(
        SettingKeys.favoriteTitles,
        current.isEmpty ? null : serializeFavoriteTitleKeys(current),
      );
  return added;
}

