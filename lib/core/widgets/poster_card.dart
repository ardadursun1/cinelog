import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/domain/watch_status.dart';
import '../../features/library/presentation/library_providers.dart';
import '../../features/library/presentation/watch_status_style.dart';
import '../models/title_summary.dart';
import '../settings/app_settings_providers.dart';
import 'cached_tmdb_image.dart';

class PosterCard extends ConsumerStatefulWidget {
  const PosterCard({
    super.key,
    required this.summary,
    required this.onTap,
    this.onQuickStatus,
    this.status,
    this.userRating,
    this.progressLabel,
    this.nextEpisodeLabel,
    this.onMarkNextEpisode,
  });

  final TitleSummary summary;
  final VoidCallback onTap;
  final ValueChanged<WatchStatus>? onQuickStatus;
  final WatchStatus? status;
  final int? userRating;
  final String? progressLabel;
  final String? nextEpisodeLabel;
  final VoidCallback? onMarkNextEpisode;

  @override
  ConsumerState<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends ConsumerState<PosterCard> {
  bool _hovered = false;
  bool _autoAddedByFavorite = false;

  @override
  void didUpdateWidget(covariant PosterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary.key != widget.summary.key) {
      _autoAddedByFavorite = false;
    } else if (widget.status != null && widget.status != WatchStatus.planned) {
      _autoAddedByFavorite = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentLanguageProvider);
    final favorites =
        ref.watch(favoriteTitlesProvider).value ?? const <TitleKey>{};
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summary = widget.summary;
    final status = widget.status;
    final onQuickStatus = widget.onQuickStatus;
    final isFavorite = favorites.contains(summary.key);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Card(
          elevation: _hovered ? 6 : 1,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedTmdbImage(
                        imagePath: summary.posterPath,
                        size: 'w342',
                        cacheWidth: 360,
                        placeholderIcon: Icons.movie_outlined,
                        placeholderIconSize: 48,
                      ),
                      if (_hovered && summary.overview.isNotEmpty)
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: _hovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.78),
                              padding: const EdgeInsets.fromLTRB(12, 48, 44, 12),
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                summary.overview,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (summary.formattedVoteAverage != null ||
                          widget.userRating != null ||
                          status != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 44,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (summary.formattedVoteAverage != null)
                                _Badge(
                                  icon: Icons.star_rounded,
                                  label: summary.formattedVoteAverage!,
                                  background: Colors.black87,
                                  foreground: Colors.amber,
                                ),
                              if (summary.formattedVoteAverage != null &&
                                  widget.userRating != null)
                                const SizedBox(height: 4),
                              if (widget.userRating != null)
                                _Badge(
                                  icon: Icons.star_rounded,
                                  label: '${widget.userRating}/10',
                                  background: Colors.black87,
                                  foreground: Colors.amber,
                                ),
                              if ((summary.formattedVoteAverage != null ||
                                      widget.userRating != null) &&
                                  status != null)
                                const SizedBox(height: 4),
                              if (status != null)
                                _Badge(
                                  icon: status.icon,
                                  label: status.labelFor(lang),
                                  background: status.color(scheme),
                                  foreground: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      if (onQuickStatus != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QuickActionButton(
                                icon: Icons.add_rounded,
                                tooltip: status == WatchStatus.planned
                                    ? lang.pick(
                                        'İzlenecek listesinden çıkar',
                                        'Remove from Plan to Watch',
                                      )
                                    : lang.pick(
                                        'İzlenecek listesine ekle',
                                        'Add to Plan to Watch',
                                      ),
                                active: status == WatchStatus.planned,
                                activeColor: scheme.tertiary,
                                onPressed: () {
                                  _autoAddedByFavorite = false;
                                  onQuickStatus(WatchStatus.planned);
                                },
                              ),
                              const SizedBox(height: 6),
                              _QuickActionButton(
                                icon: Icons.check_rounded,
                                tooltip: status == WatchStatus.watched
                                    ? lang.pick(
                                        'İzledim listesinden çıkar',
                                        'Remove from Watched',
                                      )
                                    : lang.pick(
                                        'İzledim listesine ekle',
                                        'Mark as Watched',
                                      ),
                                active: status == WatchStatus.watched,
                                activeColor: Colors.green.shade600,
                                onPressed: () {
                                  _autoAddedByFavorite = false;
                                  onQuickStatus(WatchStatus.watched);
                                },
                              ),
                              const SizedBox(height: 6),
                              _QuickActionButton(
                                icon: isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                tooltip: isFavorite
                                    ? lang.pick(
                                        'Favorilerden çıkar',
                                        'Remove from Favorites',
                                      )
                                    : lang.pick(
                                        'Favorilere ekle',
                                        'Add to Favorites',
                                      ),
                                active: isFavorite,
                                activeColor: Colors.pinkAccent.shade400,
                                onPressed: () async {
                                  final wasNullStatus = status == null;
                                  final shouldUndoAutoAdd =
                                      _autoAddedByFavorite &&
                                          status == WatchStatus.planned &&
                                          widget.userRating == null;
                                  final added = await toggleFavoriteTitle(
                                    ref,
                                    summary.key,
                                  );
                                  if (added && wasNullStatus) {
                                    _autoAddedByFavorite = true;
                                    onQuickStatus(WatchStatus.planned);
                                  } else if (!added && shouldUndoAutoAdd) {
                                    _autoAddedByFavorite = false;
                                    await ref
                                        .read(libraryServiceProvider)
                                        .removeIfUnmodifiedPlanned(summary.key);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      if (widget.progressLabel != null ||
                          (widget.nextEpisodeLabel != null &&
                              widget.onMarkNextEpisode != null))
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.progressLabel != null)
                                _Badge(
                                  icon: Icons.tv,
                                  label: widget.progressLabel!,
                                  background: Colors.black87,
                                  foreground: Colors.white,
                                ),
                              if (widget.progressLabel != null &&
                                  widget.nextEpisodeLabel != null &&
                                  widget.onMarkNextEpisode != null)
                                const SizedBox(height: 5),
                              if (widget.nextEpisodeLabel != null &&
                                  widget.onMarkNextEpisode != null)
                                Tooltip(
                                  message: lang.pick(
                                    'Sıradaki bölümü izledim olarak işaretle',
                                    'Mark next episode as watched',
                                  ),
                                  child: Material(
                                    color: Colors.green.shade700.withValues(
                                      alpha: 0.94,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 2,
                                    child: InkWell(
                                      onTap: widget.onMarkNextEpisode,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 3),
                                            Flexible(
                                              child: Text(
                                                widget.nextEpisodeLabel!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary.metaLabelFor(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.activeColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? activeColor : Colors.black.withValues(alpha: 0.72),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
