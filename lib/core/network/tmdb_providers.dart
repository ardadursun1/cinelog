import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_type.dart';
import '../models/title_summary.dart';
import '../settings/app_settings_providers.dart';
import 'tmdb_client.dart';
import 'tmdb_models.dart';

/// `null` when no API key is configured.
final tmdbClientProvider = Provider<TmdbClient?>((ref) {
  final key = ref.watch(apiKeyProvider).key;
  if (key == null) return null;
  final lang = ref.watch(currentLanguageProvider);
  final client = TmdbClient(key, language: lang.tmdbLocale);
  ref.onDispose(client.close);
  return client;
});

/// Genre id -> localized (tr-TR) name, per media type.
final genreNamesProvider =
    FutureProvider<Map<MediaType, Map<int, String>>>((ref) async {
  final client = ref.watch(tmdbClientProvider);
  if (client == null) return const {};
  final results = await Future.wait(
    MediaType.values.map(client.fetchGenres),
  );
  return {
    for (var i = 0; i < MediaType.values.length; i++)
      MediaType.values[i]: {for (final g in results[i]) g.id: g.name},
  };
});

final richTitleDetailsProvider =
    FutureProvider.autoDispose.family<RichTitleDetails?, TitleKey>((
  ref,
  key,
) async {
  final client = ref.watch(tmdbClientProvider);
  if (client == null) return null;
  final excluded =
      ref.watch(excludedCategoriesProvider).value ?? const <String>{};
  return client.fetchRichDetails(key, excludedCategoryKeys: excluded);
});

final personDetailsProvider =
    FutureProvider.autoDispose.family<PersonDetails?, int>((
  ref,
  personId,
) async {
  final client = ref.watch(tmdbClientProvider);
  if (client == null) return null;
  final excluded =
      ref.watch(excludedCategoriesProvider).value ?? const <String>{};
  return client.fetchPersonDetails(personId, excludedCategoryKeys: excluded);
});

