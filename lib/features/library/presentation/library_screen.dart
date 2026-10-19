import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../../core/widgets/poster_card.dart';
import '../../../core/widgets/responsive_poster_grid.dart';
import '../../title_detail/presentation/random_pick_dialog.dart';
import '../../title_detail/presentation/title_detail_dialog.dart';
import '../domain/library_filter.dart';
import '../domain/watch_status.dart';
import 'library_providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentLanguageProvider);
    final filter = ref.watch(libraryFilterProvider);
    final filterNotifier = ref.read(libraryFilterProvider.notifier);
    final entriesAsync = ref.watch(filteredLibraryProvider);
    final allEntries = ref.watch(libraryEntriesProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;

    if (_searchController.text != filter.searchQuery) {
      _searchController.value = TextEditingValue(
        text: filter.searchQuery,
        selection: TextSelection.collapsed(offset: filter.searchQuery.length),
      );
    }

    // Collect distinct genres across the user's library for quick filtering.
    final genreMap = <int, String>{};
    for (final entry in allEntries) {
      for (final g in entry.genres) {
        genreMap.putIfAbsent(g.id, () => g.name);
      }
    }
    final availableGenres = [
      for (final e in genreMap.entries) Genre(e.key, e.value),
    ]..sort((a, b) => a.name.compareTo(b.name));
    final activeGenreId =
        genreMap.containsKey(filter.genreId) ? filter.genreId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        onChanged: filterNotifier.setSearchQuery,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          hintText: lang.pick(
                            'Kütüphanede ara (başlık, orijinal ad, not veya tür)...',
                            'Search library (title, original name, note, or genre)...',
                          ),
                          suffixIcon: filter.searchQuery.isNotEmpty
                              ? IconButton(
                                  tooltip: lang.pick('Temizle', 'Clear'),
                                  onPressed: () {
                                    _searchController.clear();
                                    filterNotifier.setSearchQuery('');
                                  },
                                  icon: const Icon(Icons.clear, size: 18),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  if (allEntries.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    ActionChip(
                      avatar: Icon(
                        Icons.casino_outlined,
                        size: 18,
                        color: scheme.primary,
                      ),
                      label: Text(lang.pick('Ne İzlesem?', 'Surprise Me')),
                      onPressed: () {
                        final planned = [
                          for (final e in allEntries)
                            if (e.item.status == WatchStatus.planned ||
                                e.item.status == WatchStatus.watching)
                              e.toSummary(),
                        ];
                        final pool = planned.isNotEmpty
                            ? planned
                            : [for (final e in allEntries) e.toSummary()];
                        showRandomPickDialog(
                          context,
                          candidates: pool,
                          sourceLabel: planned.isNotEmpty
                              ? lang.pick(
                                  'İzlenecek / İzleniyor Listemden',
                                  'From My Watchlist',
                                )
                              : lang.pick('Kütüphanemden', 'From My Library'),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: Text(lang.pick('Tümü', 'All')),
                    selected: filter.status == null && !filter.favoritesOnly,
                    onSelected: (_) {
                      filterNotifier.setStatus(null);
                      filterNotifier.setFavoritesOnly(false);
                    },
                  ),
                  FilterChip(
                    avatar: Icon(
                      filter.favoritesOnly
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: Colors.pinkAccent.shade400,
                    ),
                    label: Text(lang.pick('Favoriler', 'Favorites')),
                    selected: filter.favoritesOnly,
                    onSelected: filterNotifier.setFavoritesOnly,
                  ),
                  for (final status in WatchStatus.values)
                    FilterChip(
                      label: Text(status.labelFor(lang)),
                      selected: filter.status == status,
                      onSelected: (selected) =>
                          filterNotifier.setStatus(selected ? status : null),
                    ),
                  const SizedBox(width: 6),
                  for (final type in MediaType.values)
                    FilterChip(
                      label: Text(type.labelFor(lang)),
                      selected: filter.mediaType == type,
                      onSelected: (selected) =>
                          filterNotifier.setMediaType(selected ? type : null),
                    ),
                  if (availableGenres.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    DropdownButton<int?>(
                      value: activeGenreId,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(12),
                      hint: Text(lang.pick('Tüm Türler', 'All Genres')),
                      onChanged: filterNotifier.setGenreId,
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(lang.pick('Tüm Türler', 'All Genres')),
                        ),
                        for (final g in availableGenres)
                          DropdownMenuItem<int?>(
                            value: g.id,
                            child: Text(g.name),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  DropdownButton<LibrarySort>(
                    value: filter.sort,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (sort) {
                      if (sort != null) filterNotifier.setSort(sort);
                    },
                    items: [
                      for (final sort in LibrarySort.values)
                        DropdownMenuItem(
                          value: sort,
                          child: Text(sort.labelFor(lang)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                lang.pick(
                  'Kütüphane yüklenemedi: $e',
                  'Could not load library: $e',
                ),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    lang.pick(
                      'Bu filtreye uygun kayıt yok. "Ara" sekmesinden film veya dizi ekleyebilirsin.',
                      'No entries match this filter. You can add movies or TV shows from the "Search" tab.',
                    ),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                );
              }
              return ResponsivePosterGrid(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final summary = entry.toSummary();
                  return PosterCard(
                    summary: summary,
                    status: entry.item.status,
                    userRating: entry.item.userRating,
                    progressLabel: entry.progressLabel,
                    onQuickStatus: (targetStatus) {
                      ref
                          .read(libraryDaoProvider)
                          .setStatus(entry.item.id, targetStatus);
                    },
                    onTap: () => showTitleDetailDialog(context, summary),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


