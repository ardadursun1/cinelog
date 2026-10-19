import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_providers.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../episodes/data/episode_dao.dart';
import '../data/library_dao.dart';
import '../data/library_service.dart';
import '../domain/library_entry.dart';
import '../domain/library_filter.dart';
import '../domain/watch_status.dart';

final libraryDaoProvider =
    Provider<LibraryDao>((ref) => LibraryDao(ref.watch(appDatabaseProvider)));

final episodeDaoProvider = Provider<EpisodeDao>((ref) => EpisodeDao(
      ref.watch(appDatabaseProvider),
      ref.watch(libraryDaoProvider),
    ));

final libraryServiceProvider = Provider<LibraryService>((ref) => LibraryService(
      ref.watch(libraryDaoProvider),
      ref.watch(episodeDaoProvider),
      () => ref.read(tmdbClientProvider),
    ));

final libraryEntriesProvider = StreamProvider<List<LibraryEntry>>(
  (ref) => ref.watch(libraryDaoProvider).watchEntries(),
);

final libraryStatusIndexProvider = Provider<Map<TitleKey, WatchStatus>>((ref) {
  final entries = ref.watch(libraryEntriesProvider).value ?? const [];
  return {for (final e in entries) e.key: e.item.status};
});

final libraryItemProvider =
    StreamProvider.autoDispose.family<LibraryItem?, TitleKey>(
  (ref, key) => ref.watch(libraryDaoProvider).watchItem(key),
);

class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => const LibraryFilter();

  void setStatus(WatchStatus? status) =>
      state = state.copyWith(status: () => status);

  void setMediaType(MediaType? type) =>
      state = state.copyWith(mediaType: () => type);

  void setFavoritesOnly(bool favoritesOnly) =>
      state = state.copyWith(favoritesOnly: favoritesOnly);

  void setGenreId(int? genreId) =>
      state = state.copyWith(genreId: () => genreId);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void setSort(LibrarySort sort) => state = state.copyWith(sort: sort);
}

final libraryFilterProvider =
    NotifierProvider<LibraryFilterNotifier, LibraryFilter>(
  LibraryFilterNotifier.new,
);

final filteredLibraryProvider = Provider<AsyncValue<List<LibraryEntry>>>((ref) {
  final filter = ref.watch(libraryFilterProvider);
  final favorites =
      ref.watch(favoriteTitlesProvider).value ?? const <TitleKey>{};
  return ref
      .watch(libraryEntriesProvider)
      .whenData((entries) => filter.apply(entries, favorites: favorites));
});

