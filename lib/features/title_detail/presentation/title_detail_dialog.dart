import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/models/media_type.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_models.dart';
import '../../../core/network/tmdb_providers.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../episodes/presentation/season_episode_panel.dart';
import '../../library/domain/watch_status.dart';
import '../../library/presentation/library_providers.dart';
import '../../library/presentation/watch_status_style.dart';
import 'person_credits_dialog.dart';

Future<void> showTitleDetailDialog(
  BuildContext context,
  TitleSummary summary,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => TitleDetailDialog(summary: summary),
  );
}

class TitleDetailDialog extends ConsumerStatefulWidget {
  const TitleDetailDialog({super.key, required this.summary});

  final TitleSummary summary;

  @override
  ConsumerState<TitleDetailDialog> createState() => _TitleDetailDialogState();
}

class _TitleDetailDialogState extends ConsumerState<TitleDetailDialog> {
  final TextEditingController _noteController = TextEditingController();
  int? _boundItemId;
  bool _savingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _syncNoteField(LibraryItem? item) {
    if (item == null) {
      _boundItemId = null;
      return;
    }
    if (_boundItemId != item.id) {
      _boundItemId = item.id;
      _noteController.text = item.note ?? '';
    }
  }

  Future<void> _saveNote(int itemId, AppLanguage lang) async {
    setState(() => _savingNote = true);
    try {
      await ref
          .read(libraryDaoProvider)
          .setNote(itemId, _noteController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.pick('Not kaydedildi.', 'Note saved.')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _openExternalUrl(
    String url,
    AppLanguage lang, {
    Set<String> allowedHosts = const {'www.youtube.com', 'www.themoviedb.org'},
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !allowedHosts.contains(uri.host)) {
      return;
    }
    try {
      if (Platform.isWindows) {
        await Process.run('rundll32', ['url.dll,FileProtocolHandler', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.pick(
                'Bağlantı panoya kopyalandı.',
                'Link copied to clipboard.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmRemove(LibraryItem item, AppLanguage lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.pick('Kütüphaneden kaldır', 'Remove from Library')),
        content: Text(
          lang.pick(
            '"${item.title}" kütüphaneden ve varsa bölüm kayıtlarından kaldırılsın mı?',
            'Remove "${item.title}" and its episode records from your library?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(lang.pick('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(lang.pick('Kaldır', 'Remove')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(libraryDaoProvider).remove(item.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentLanguageProvider);
    final favorites =
        ref.watch(favoriteTitlesProvider).value ?? const <TitleKey>{};
    final summary = widget.summary;
    final itemAsync = ref.watch(libraryItemProvider(summary.key));
    final richAsync = ref.watch(richTitleDetailsProvider(summary.key));
    final rich = richAsync.value;
    final item = itemAsync.value;
    final isFavorite = favorites.contains(summary.key);
    _syncNoteField(item);

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final runtimeText = switch (rich?.runtimeMinutes) {
      final m? when summary.mediaType == MediaType.movie =>
        lang.pick('$m dk', '$m min'),
      final m? => lang.pick('~$m dk / bölüm', '~$m min / ep'),
      null => null,
    };
    final metaParts = [
      summary.metaLabelFor(lang),
      ?runtimeText,
      if (summary.voteAverage != null)
        '★ ${summary.voteAverage!.toStringAsFixed(1)}',
    ];

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 160,
                            height: 240,
                            child: summary.posterPath != null
                                ? Image.network(
                                    tmdbPosterUrl(summary.posterPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => ColoredBox(
                                      color: scheme.surfaceContainerHighest,
                                      child: const Icon(Icons.movie, size: 48),
                                    ),
                                  )
                                : ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                    child: const Icon(Icons.movie, size: 48),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      summary.title,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: lang.pick('Kapat', 'Close'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              if (summary.originalTitle.isNotEmpty &&
                                  summary.originalTitle != summary.title)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    summary.originalTitle,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              Text(
                                metaParts.join(' · '),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (rich != null && rich.creators.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${summary.mediaType == MediaType.movie ? lang.pick("Yönetmen", "Director") : lang.pick("Yaratıcı / Yapımcı", "Creator / Producer")}:',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    for (final c in rich.creators)
                                      c.id != null
                                          ? ActionChip(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              avatar: const Icon(
                                                Icons.person_search_outlined,
                                                size: 15,
                                              ),
                                              label: Text(
                                                c.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  showPersonCreditsDialog(
                                                context,
                                                personId: c.id!,
                                                fallbackName: c.name,
                                                fallbackProfilePath:
                                                    c.profilePath,
                                              ),
                                            )
                                          : Text(
                                              c.name,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                  ],
                                ),
                              ],
                              if (rich != null && rich.tagline.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '"${rich.tagline}"',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.secondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              if (summary.overview.isNotEmpty)
                                Text(
                                  summary.overview,
                                  style: textTheme.bodyMedium?.copyWith(
                                    height: 1.45,
                                  ),
                                )
                              else
                                Text(
                                  lang.pick(
                                    'Özet bulunmuyor.',
                                    'No overview available.',
                                  ),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _buildStatusSection(item, lang),
                                  FilterChip(
                                    avatar: Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 18,
                                      color: Colors.pinkAccent.shade400,
                                    ),
                                    label: Text(
                                      lang.pick('Favori', 'Favorite'),
                                    ),
                                    selected: isFavorite,
                                    onSelected: (_) async {
                                      final added = await toggleFavoriteTitle(
                                        ref,
                                        summary.key,
                                      );
                                      if (added && item == null) {
                                        await ref
                                            .read(libraryServiceProvider)
                                            .add(summary, WatchStatus.planned);
                                      }
                                    },
                                  ),
                                  if (rich?.youtubeTrailerUrl case final url?)
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _openExternalUrl(url, lang),
                                      icon: const Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.redAccent,
                                      ),
                                      label: Text(
                                        lang.pick(
                                          'Fragmanı İzle',
                                          'Watch Trailer',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (rich != null && rich.watchProviders.isNotEmpty) ...[
                      const Divider(height: 32),
                      _buildWatchProvidersSection(rich.watchProviders, lang),
                    ],
                    if (item != null) ...[
                      const Divider(height: 32),
                      _buildRatingAndNote(item, lang),
                      if (summary.mediaType == MediaType.tv) ...[
                        const Divider(height: 32),
                        SeasonEpisodePanel(
                          itemId: item.id,
                          summary: summary,
                          currentStatus: item.status,
                        ),
                      ],
                    ],
                    if (rich != null && rich.cast.isNotEmpty) ...[
                      const Divider(height: 32),
                      _buildCastSection(rich.cast, lang),
                    ],
                    if (rich != null && rich.recommendations.isNotEmpty) ...[
                      const Divider(height: 32),
                      _buildRecommendationsSection(rich.recommendations, lang),
                    ],
                  ],
                ),
              ),
            ),
            if (item != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmRemove(item, lang),
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      label: Text(
                        lang.pick(
                          'Kütüphaneden kaldır',
                          'Remove from Library',
                        ),
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(lang.pick('Tamam', 'Done')),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(LibraryItem? item, AppLanguage lang) {
    final service = ref.read(libraryServiceProvider);
    final dao = ref.read(libraryDaoProvider);

    if (item == null) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final status in WatchStatus.values)
            FilledButton.tonalIcon(
              onPressed: () async {
                final res = await service.add(widget.summary, status);
                if (res.seasonError != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang.pick(
                          'Kütüphaneye eklendi ancak sezonlar alınamadı: '
                              '${res.seasonError!.userMessageForLang(lang)}',
                          'Added to library, but seasons could not be fetched: '
                              '${res.seasonError!.userMessageForLang(lang)}',
                        ),
                      ),
                    ),
                  );
                }
              },
              icon: Icon(status.icon, size: 18),
              label: Text(
                lang.pick(
                  'Kütüphaneye ekle: ${status.labelFor(lang)}',
                  'Add to Library: ${status.labelFor(lang)}',
                ),
              ),
            ),
        ],
      );
    }

    return SegmentedButton<WatchStatus>(
      segments: [
        for (final status in WatchStatus.values)
          ButtonSegment<WatchStatus>(
            value: status,
            icon: Icon(status.icon),
            label: Text(status.labelFor(lang)),
          ),
      ],
      selected: {item.status},
      onSelectionChanged: (selection) {
        dao.setStatus(item.id, selection.first);
      },
    );
  }

  Widget _buildRatingAndNote(LibraryItem item, AppLanguage lang) {
    final dao = ref.read(libraryDaoProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              lang.pick('Puanım:', 'My Rating:'),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 4,
              children: [
                for (var r = 1; r <= 10; r++)
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$r'),
                    selected: item.userRating == r,
                    onSelected: (selected) =>
                        dao.setRating(item.id, selected ? r : null),
                  ),
              ],
            ),
            if (item.userRating != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: lang.pick('Puanı temizle', 'Clear rating'),
                onPressed: () => dao.setRating(item.id, null),
                icon: const Icon(Icons.clear, size: 18),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLength: kNoteMaxLength,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: lang.pick('Kısa not', 'Short note'),
                  hintText: lang.pick(
                    'Bu film/dizi hakkında notun...',
                    'Your note about this movie/show...',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: _savingNote ? null : () => _saveNote(item.id, lang),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(lang.pick('Notu kaydet', 'Save note')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWatchProvidersSection(
    WatchProvidersInfo providers,
    AppLanguage lang,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget buildGroup(String label, List<WatchProvider> list) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in list)
                    Container(
                      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p.logoPath != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                tmdbPosterUrl(p.logoPath!, size: 'w92'),
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.tv, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            p.name,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              lang.pick('Hangi Platformda?', 'Where to Watch'),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (providers.region.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  providers.region,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (providers.link != null)
              TextButton.icon(
                onPressed: () => _openExternalUrl(providers.link!, lang),
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text(
                  'JustWatch / TMDB',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        if (providers.flatrate.isNotEmpty)
          buildGroup(
            lang.pick('Abonelik / Yayın', 'Stream'),
            providers.flatrate,
          ),
        if (providers.rent.isNotEmpty)
          buildGroup(lang.pick('Kiralama', 'Rent'), providers.rent),
        if (providers.buy.isNotEmpty)
          buildGroup(lang.pick('Satın Alma', 'Buy'), providers.buy),
      ],
    );
  }

  Widget _buildCastSection(List<CastMember> cast, AppLanguage lang) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              lang.pick('Oyuncu Kadrosu', 'Cast'),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              lang.pick(
                '(Diğer yapımlarını görmek için oyuncuya tıkla)',
                '(Click an actor to view their filmography)',
              ),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final member = cast[index];
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: member.id == null
                    ? null
                    : () => showPersonCreditsDialog(
                          context,
                          personId: member.id!,
                          fallbackName: member.name,
                          fallbackProfilePath: member.profilePath,
                        ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: SizedBox(
                    width: 96,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 80,
                            height: 96,
                            child: member.profilePath != null
                                ? Image.network(
                                    tmdbPosterUrl(
                                      member.profilePath!,
                                      size: 'w185',
                                    ),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => ColoredBox(
                                      color: scheme.surfaceContainerHighest,
                                      child: const Icon(Icons.person_outline),
                                    ),
                                  )
                                : ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                    child: const Icon(Icons.person_outline),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (member.character.isNotEmpty)
                          Text(
                            member.character,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(
    List<TmdbSearchItem> recommendations,
    AppLanguage lang,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final genreMap = ref.watch(genreNamesProvider).value ??
        const <MediaType, Map<int, String>>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.pick('Benzer Yapımlar', 'Similar Titles'),
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              final recSummary =
                  rec.toSummary(genreMap[rec.mediaType] ?? const {});
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.of(context).pop();
                  showTitleDetailDialog(context, recSummary);
                },
                child: SizedBox(
                  width: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 112,
                          height: 152,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              rec.posterPath != null
                                  ? Image.network(
                                      tmdbPosterUrl(
                                        rec.posterPath!,
                                        size: 'w185',
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => ColoredBox(
                                        color: scheme.surfaceContainerHighest,
                                        child: const Icon(Icons.movie_outlined),
                                      ),
                                    )
                                  : ColoredBox(
                                      color: scheme.surfaceContainerHighest,
                                      child: const Icon(Icons.movie_outlined),
                                    ),
                              if (rec.voteAverage != null)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.78,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '★ ${rec.voteAverage!.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFFC107),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rec.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

