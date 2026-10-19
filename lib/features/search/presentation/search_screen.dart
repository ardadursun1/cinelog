import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/settings_dao.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/models/content_category.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/network/tmdb_models.dart';
import '../../../core/network/tmdb_providers.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../../core/widgets/poster_card.dart';
import '../../../core/widgets/responsive_poster_grid.dart';
import '../../../core/widgets/search_focus.dart';
import '../../library/domain/watch_status.dart';
import '../../library/presentation/library_providers.dart';
import '../../title_detail/presentation/random_pick_dialog.dart';
import '../../title_detail/presentation/title_detail_dialog.dart';
import 'missing_key_hint.dart';

enum _DiscoverFeed {
  topAll(
    'En İyi Film & Diziler',
    'Top Movies & TV',
    Icons.workspace_premium_outlined,
  ),
  topMovies('En İyi Filmler', 'Top Movies', Icons.movie_outlined),
  topTv('En İyi Diziler', 'Top TV Shows', Icons.tv_outlined),
  popular('Popüler', 'Popular', Icons.local_fire_department_outlined);

  const _DiscoverFeed(this.label, this.labelEn, this.icon);

  final String label;
  final String labelEn;
  final IconData icon;

  String labelFor(AppLanguage lang) => lang.isEn ? labelEn : label;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;
  CancelToken? _cancelToken;

  _DiscoverFeed _feed = _DiscoverFeed.topAll;
  String? _selectedCategoryKey;
  String _activeQuery = '';
  String? _loadedSignature;
  List<TmdbSearchItem> _items = const [];
  int _page = 1;
  int _totalPages = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _loadingMore || _page >= _totalPages) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadFirstPage(value);
    });
  }

  Future<TmdbSearchPage> _fetchPage(
    TmdbClient client,
    String query,
    int page,
    CancelToken token,
  ) {
    final excluded =
        ref.read(excludedCategoriesProvider).value ?? const <String>{};
    if (query.isNotEmpty) {
      return client.searchMulti(
        query,
        page: page,
        excludedCategoryKeys: excluded,
        cancelToken: token,
      );
    }

    final category = _selectedCategoryKey != null
        ? kCategoryByKey[_selectedCategoryKey!]
        : null;

    return switch (_feed) {
      _DiscoverFeed.topAll => client.discoverCombined(
          sortByRating: true,
          category: category,
          excludedCategoryKeys: excluded,
          page: page,
          cancelToken: token,
        ),
      _DiscoverFeed.topMovies => client.discover(
          MediaType.movie,
          sortByRating: true,
          category: category,
          excludedCategoryKeys: excluded,
          page: page,
          cancelToken: token,
        ),
      _DiscoverFeed.topTv => client.discover(
          MediaType.tv,
          sortByRating: true,
          category: category,
          excludedCategoryKeys: excluded,
          page: page,
          cancelToken: token,
        ),
      _DiscoverFeed.popular => client.discoverCombined(
          sortByRating: false,
          category: category,
          excludedCategoryKeys: excluded,
          page: page,
          cancelToken: token,
        ),
    };
  }

  Future<void> _loadFirstPage([String? rawQuery]) async {
    final query = (rawQuery ?? _controller.text).trim();
    _cancelToken?.cancel();

    final client = ref.read(tmdbClientProvider);
    if (client == null) return;

    final token = CancelToken();
    _cancelToken = token;
    setState(() {
      _activeQuery = query;
      _loading = true;
      _loadingMore = false;
      _error = null;
    });

    try {
      final page = await _fetchPage(client, query, 1, token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _items = page.results;
        _page = page.page;
        _totalPages = page.totalPages;
        _loading = false;
      });
      _ensureViewportFilled();
    } on TmdbException catch (e) {
      if (!mounted || e.kind == TmdbErrorKind.cancelled) return;
      setState(() {
        _loading = false;
        _error = e.userMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userMessageFor(e);
      });
    }
  }

  void _ensureViewportFilled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loading || _loadingMore || _page >= _totalPages) return;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent <= 120) {
        _loadNextPage();
      }
    });
  }

  Future<void> _loadNextPage() async {
    final client = ref.read(tmdbClientProvider);
    if (client == null) return;

    final nextPage = _page + 1;
    final token = CancelToken();
    _cancelToken = token;
    setState(() => _loadingMore = true);

    try {
      final page = await _fetchPage(client, _activeQuery, nextPage, token);
      if (!mounted || token.isCancelled) return;
      final seen = <TitleKey>{for (final i in _items) i.key};
      setState(() {
        _items = [
          ..._items,
          for (final i in page.results)
            if (seen.add(i.key)) i,
        ];
        _page = page.page;
        _totalPages = page.totalPages;
        _loadingMore = false;
      });
      _ensureViewportFilled();
    } on TmdbException catch (e) {
      if (!mounted || e.kind == TmdbErrorKind.cancelled) return;
      setState(() => _loadingMore = false);
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openRandomPick(
    AppLanguage lang,
    Map<MediaType, Map<int, String>> genreMap,
    Map<TitleKey, WatchStatus> statusIndex,
  ) {
    final unwatched = [
      for (final i in _items)
        if (statusIndex[i.key] != WatchStatus.watched)
          i.toSummary(genreMap[i.mediaType] ?? const {}),
    ];
    final pool = unwatched.isNotEmpty
        ? unwatched
        : [
            for (final i in _items)
              i.toSummary(genreMap[i.mediaType] ?? const {}),
          ];
    final catName = _selectedCategoryKey != null
        ? kCategoryByKey[_selectedCategoryKey!]?.labelFor(lang)
        : null;
    final source = _activeQuery.isNotEmpty
        ? lang.pick(
            '"$_activeQuery" arama sonuçlarından',
            'From "$_activeQuery" search results',
          )
        : lang.pick(
            '${_feed.labelFor(lang)}${catName != null ? " · $catName" : ""} listesinden',
            'From ${_feed.labelFor(lang)}${catName != null ? " · $catName" : ""}',
          );
    showRandomPickDialog(context, candidates: pool, sourceLabel: source);
  }

  Future<void> _saveExcludedCategories(Set<String> keys) async {
    if (_selectedCategoryKey != null && keys.contains(_selectedCategoryKey)) {
      _selectedCategoryKey = null;
    }
    final serialized = keys.isEmpty ? null : keys.join(',');
    await ref
        .read(settingsDaoProvider)
        .write(SettingKeys.excludedCategories, serialized);
  }

  Future<void> _openExcludeDialog(
    Set<String> currentExcluded,
    AppLanguage lang,
  ) async {
    final updated = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _ExcludeCategoriesDialog(
        initial: currentExcluded,
        lang: lang,
      ),
    );
    if (updated != null && mounted) {
      await _saveExcludedCategories(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyState = ref.watch(apiKeyProvider);
    final lang = ref.watch(currentLanguageProvider);
    final excludedAsync = ref.watch(excludedCategoriesProvider);
    final excluded = excludedAsync.value ?? const <String>{};
    final focusNode = ref.watch(searchFocusNodeProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<int>(searchFocusSignalProvider, (_, _) {
      focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });

    if (keyState.source == ApiKeySource.loading ||
        (!excludedAsync.hasValue && excludedAsync.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!keyState.hasKey) {
      _loadedSignature = null;
      return const MissingKeyHint();
    }

    final signature = '${keyState.key}|${lang.name}|${excluded.join(',')}';
    if (_loadedSignature != signature) {
      _loadedSignature = signature;
      if (_selectedCategoryKey != null &&
          excluded.contains(_selectedCategoryKey)) {
        _selectedCategoryKey = null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFirstPage();
      });
    }

    final genreMap = ref.watch(genreNamesProvider).value ??
        const <MediaType, Map<int, String>>{};
    final statusIndex = ref.watch(libraryStatusIndexProvider);

    final visibleCategories = [
      for (final c in kContentCategories)
        if (!excluded.contains(c.key)) c,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controller,
            focusNode: focusNode,
            autofocus: true,
            onChanged: _onQueryChanged,
            onSubmitted: _loadFirstPage,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: lang.pick(
                'Film veya dizi adı yazın... (Ctrl+F)',
                'Search movies or TV shows... (Ctrl+F)',
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: lang.pick('Temizle', 'Clear'),
                      onPressed: () {
                        _controller.clear();
                        _loadFirstPage('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_activeQuery.isEmpty)
                for (final feed in _DiscoverFeed.values)
                  ChoiceChip(
                    avatar: Icon(feed.icon, size: 18),
                    label: Text(feed.labelFor(lang)),
                    selected: _feed == feed,
                    onSelected: (selected) {
                      if (!selected || _feed == feed) return;
                      setState(() => _feed = feed);
                      _loadFirstPage('');
                    },
                  ),
              if (_items.isNotEmpty)
                ActionChip(
                  avatar: Icon(
                    Icons.casino_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  label: Text(lang.pick('Ne İzlesem?', 'Surprise Me')),
                  onPressed: () => _openRandomPick(lang, genreMap, statusIndex),
                ),
              ActionChip(
                avatar: Icon(
                  Icons.block,
                  size: 18,
                  color: excluded.isEmpty ? scheme.onSurfaceVariant : scheme.error,
                ),
                label: Text(
                  excluded.isEmpty
                      ? lang.pick('Kategori Çıkar', 'Exclude Category')
                      : lang.pick(
                          'Kategori Çıkar (${excluded.length})',
                          'Exclude Category (${excluded.length})',
                        ),
                ),
                onPressed: () => _openExcludeDialog(excluded, lang),
              ),
              for (final key in excluded)
                if (kCategoryByKey[key] case final cat?)
                  InputChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      Icons.visibility_off_outlined,
                      size: 16,
                      color: scheme.error,
                    ),
                    label: Text(
                      lang.pick(
                        'Gizli: ${cat.labelFor(lang)}',
                        'Hidden: ${cat.labelFor(lang)}',
                      ),
                    ),
                    onDeleted: () {
                      final next = {...excluded}..remove(key);
                      _saveExcludedCategories(next);
                    },
                  ),
            ],
          ),
        ),
        if (_activeQuery.isEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(lang.pick('Tüm Kategoriler', 'All Categories')),
                    selected: _selectedCategoryKey == null,
                    onSelected: (selected) {
                      if (!selected || _selectedCategoryKey == null) return;
                      setState(() => _selectedCategoryKey = null);
                      _loadFirstPage('');
                    },
                  ),
                ),
                for (final cat in visibleCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.labelFor(lang)),
                      selected: _selectedCategoryKey == cat.key,
                      onSelected: (selected) {
                        final next = selected ? cat.key : null;
                        if (_selectedCategoryKey == next) return;
                        setState(() => _selectedCategoryKey = next);
                        _loadFirstPage('');
                      },
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _buildBody(lang, genreMap, statusIndex),
        ),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (!_loading && _items.isNotEmpty && _page < _totalPages)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Center(
              child: TextButton.icon(
                onPressed: _loadNextPage,
                icon: const Icon(Icons.expand_more, size: 18),
                label: Text(
                  lang.pick(
                    'Daha Fazla Göster (Sayfa $_page/$_totalPages)',
                    'Load More (Page $_page/$_totalPages)',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    AppLanguage lang,
    Map<MediaType, Map<int, String>> genreMap,
    Map<TitleKey, dynamic> statusIndex,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _loadFirstPage(_controller.text),
                icon: const Icon(Icons.refresh),
                label: Text(lang.pick('Tekrar Dene', 'Retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (!_loading && _items.isEmpty) {
      return Center(
        child: Text(
          _activeQuery.isEmpty
              ? lang.pick(
                  'Bu filtreye uygun içerik bulunamadı.',
                  'No content found for this filter.',
                )
              : lang.pick(
                  '"$_activeQuery" için sonuç bulunamadı.',
                  'No results found for "$_activeQuery".',
                ),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return ResponsivePosterGrid(
      controller: _scrollController,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final summary = item.toSummary(genreMap[item.mediaType] ?? const {});
        final status = ref.watch(libraryStatusIndexProvider)[item.key];
        return PosterCard(
          summary: summary,
          status: status,
          onQuickStatus: (targetStatus) {
            ref
                .read(libraryServiceProvider)
                .setOrAddStatus(summary, targetStatus);
          },
          onTap: () => showTitleDetailDialog(context, summary),
        );
      },
    );
  }
}

class _ExcludeCategoriesDialog extends StatefulWidget {
  const _ExcludeCategoriesDialog({
    required this.initial,
    required this.lang,
  });

  final Set<String> initial;
  final AppLanguage lang;

  @override
  State<_ExcludeCategoriesDialog> createState() =>
      _ExcludeCategoriesDialogState();
}

class _ExcludeCategoriesDialogState extends State<_ExcludeCategoriesDialog> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(
        lang.pick('Kategori Çıkar (Gizle)', 'Exclude (Hide) Categories'),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.pick(
                'Seçtiğin kategoriler kaydedilir ve sen geri açana kadar ne ana sayfada ne de aramalarda bir daha gösterilmez.',
                'Selected categories are saved and hidden from both the home feed and search results until re-enabled.',
              ),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in kContentCategories)
                  FilterChip(
                    label: Text(cat.labelFor(lang)),
                    selected: _selected.contains(cat.key),
                    selectedColor: scheme.errorContainer,
                    checkmarkColor: scheme.onErrorContainer,
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          _selected.add(cat.key);
                        } else {
                          _selected.remove(cat.key);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_selected.isNotEmpty)
          TextButton(
            onPressed: () => setState(_selected.clear),
            child: Text(lang.pick('Tümünü Temizle', 'Clear All')),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lang.pick('Vazgeç', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(lang.pick('Kaydet', 'Save')),
        ),
      ],
    );
  }
}

