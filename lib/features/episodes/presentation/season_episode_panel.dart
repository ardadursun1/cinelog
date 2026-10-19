import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../library/domain/watch_status.dart';
import '../../library/presentation/library_providers.dart';

class SeasonEpisodePanel extends ConsumerStatefulWidget {
  const SeasonEpisodePanel({
    super.key,
    required this.itemId,
    required this.summary,
    required this.currentStatus,
  });

  final int itemId;
  final TitleSummary summary;
  final WatchStatus currentStatus;

  @override
  ConsumerState<SeasonEpisodePanel> createState() => _SeasonEpisodePanelState();
}

class _SeasonEpisodePanelState extends ConsumerState<SeasonEpisodePanel> {
  bool _syncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSeasonsLoaded());
  }

  Future<void> _ensureSeasonsLoaded() async {
    final seasons = await ref
        .read(episodeDaoProvider)
        .watchSeasons(widget.itemId)
        .first;
    if (seasons.isEmpty && mounted) {
      await _refreshSeasons();
    }
  }

  Future<void> _refreshSeasons() async {
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      await ref
          .read(libraryServiceProvider)
          .refreshSeasons(widget.itemId, widget.summary.tmdbId);
    } catch (e) {
      if (mounted) {
        final lang = ref.read(currentLanguageProvider);
        setState(() => _error = userMessageFor(e, lang));
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentLanguageProvider);
    final dao = ref.watch(episodeDaoProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<TvSeason>>(
      stream: dao.watchSeasons(widget.itemId),
      builder: (context, seasonSnap) {
        final seasons = seasonSnap.data ?? const [];
        return StreamBuilder<Set<(int, int)>>(
          stream: dao.watchWatched(widget.itemId),
          builder: (context, watchedSnap) {
            final watched = watchedSnap.data ?? const {};
            final totalEpisodes =
                seasons.fold<int>(0, (sum, s) => sum + s.episodeCount);
            (int, int)? lastWatched;
            for (final ep in watched) {
              if (lastWatched == null ||
                  ep.$1 > lastWatched.$1 ||
                  (ep.$1 == lastWatched.$1 && ep.$2 > lastWatched.$2)) {
                lastWatched = ep;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lang.pick(
                        'Sezon ve Bölüm Takibi',
                        'Season & Episode Tracker',
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (lastWatched != null)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.bookmark_added, size: 16),
                        label: Text(
                          lang.pick(
                            'Kaldığın yer: S${lastWatched.$1} B${lastWatched.$2}'
                                '${totalEpisodes > 0 ? ' (${watched.length}/$totalEpisodes)' : ''}',
                            'Progress: S${lastWatched.$1} E${lastWatched.$2}'
                                '${totalEpisodes > 0 ? ' (${watched.length}/$totalEpisodes)' : ''}',
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (seasons.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => dao.markAll(widget.itemId),
                        icon: const Icon(Icons.done_all, size: 18),
                        label: Text(
                          lang.pick('Tümünü izledim', 'Mark all watched'),
                        ),
                      ),
                    IconButton(
                      tooltip: lang.pick(
                        'TMDB\'den sezonları yenile',
                        'Refresh seasons from TMDB',
                      ),
                      onPressed: _syncing ? null : _refreshSeasons,
                      icon: _syncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                if (seasons.isEmpty && !_syncing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      lang.pick(
                        'Sezon bilgisi henüz yüklenmedi. Yenile butonuna basarak TMDB\'den çekebilirsin.',
                        'Season info not loaded yet. Click Refresh to fetch from TMDB.',
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final season in seasons)
                    _SeasonTile(
                      season: season,
                      watched: watched,
                      lang: lang,
                      onToggleEpisode: (ep, isWatched) => dao.setEpisode(
                        widget.itemId,
                        (season.seasonNumber, ep),
                        watched: isWatched,
                      ),
                      onMarkUpTo: (ep) => dao.markUpTo(
                        widget.itemId,
                        (season.seasonNumber, ep),
                      ),
                      onToggleSeason: (allWatched) => dao.setSeason(
                        widget.itemId,
                        season.seasonNumber,
                        watched: !allWatched,
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SeasonTile extends StatelessWidget {
  const _SeasonTile({
    required this.season,
    required this.watched,
    required this.lang,
    required this.onToggleEpisode,
    required this.onMarkUpTo,
    required this.onToggleSeason,
  });

  final TvSeason season;
  final Set<(int, int)> watched;
  final AppLanguage lang;
  final void Function(int episode, bool watched) onToggleEpisode;
  final void Function(int episode) onMarkUpTo;
  final void Function(bool allWatched) onToggleSeason;

  @override
  Widget build(BuildContext context) {
    final sNum = season.seasonNumber;
    var watchedInSeason = 0;
    for (var e = 1; e <= season.episodeCount; e++) {
      if (watched.contains((sNum, e))) watchedInSeason++;
    }
    final allWatched =
        season.episodeCount > 0 && watchedInSeason == season.episodeCount;

    return ExpansionTile(
      initiallyExpanded: sNum == 1,
      title: Text(
        season.name.isNotEmpty
            ? season.name
            : lang.pick('Sezon $sNum', 'Season $sNum'),
      ),
      subtitle: Text(
        lang.pick(
          '$watchedInSeason / ${season.episodeCount} bölüm izlendi',
          '$watchedInSeason / ${season.episodeCount} episodes watched',
        ),
      ),
      trailing: TextButton(
        onPressed: () => onToggleSeason(allWatched),
        child: Text(
          allWatched
              ? lang.pick('Sezonu sıfırla', 'Reset season')
              : lang.pick('Sezonu tamamla', 'Complete season'),
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var ep = 1; ep <= season.episodeCount; ep++)
                _EpisodeChip(
                  episodeNumber: ep,
                  lang: lang,
                  isWatched: watched.contains((sNum, ep)),
                  onTap: () => onToggleEpisode(
                    ep,
                    !watched.contains((sNum, ep)),
                  ),
                  onLongPress: () => onMarkUpTo(ep),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            lang.pick(
              'İpucu: Bir bölüme tıklayarak işaretle/kaldır; basılı tutarak (veya sağ tık) o bölüme kadar tümünü izlendi işaretle.',
              'Tip: Click an episode to toggle; long-press (or right-click) to mark all episodes up to that point as watched.',
            ),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _EpisodeChip extends StatelessWidget {
  const _EpisodeChip({
    required this.episodeNumber,
    required this.lang,
    required this.isWatched,
    required this.onTap,
    required this.onLongPress,
  });

  final int episodeNumber;
  final AppLanguage lang;
  final bool isWatched;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final prefix = lang.pick('B', 'E');
    return GestureDetector(
      onSecondaryTap: onLongPress,
      child: FilterChip(
        visualDensity: VisualDensity.compact,
        label: Text('$prefix$episodeNumber'),
        selected: isWatched,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

