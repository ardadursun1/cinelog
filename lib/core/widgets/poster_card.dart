import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/domain/watch_status.dart';
import '../../features/library/presentation/watch_status_style.dart';
import '../models/title_summary.dart';
import '../network/tmdb_models.dart';
import '../settings/app_settings_providers.dart';

class PosterCard extends ConsumerStatefulWidget {
  const PosterCard({
    super.key,
    required this.summary,
    required this.onTap,
    this.onQuickStatus,
    this.status,
    this.userRating,
    this.progressLabel,
  });

  final TitleSummary summary;
  final VoidCallback onTap;
  final ValueChanged<WatchStatus>? onQuickStatus;
  final WatchStatus? status;
  final int? userRating;
  final String? progressLabel;

  @override
  ConsumerState<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends ConsumerState<PosterCard> {
  bool _hovered = false;

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
                      _PosterImage(posterPath: summary.posterPath),
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
                                tooltip: lang.pick(
                                  'İzlenecek listesine ekle',
                                  'Add to Plan to Watch',
                                ),
                                active: status == WatchStatus.planned,
                                activeColor: scheme.tertiary,
                                onPressed: () =>
                                    onQuickStatus(WatchStatus.planned),
                              ),
                              const SizedBox(height: 6),
                              _QuickActionButton(
                                icon: Icons.check_rounded,
                                tooltip: lang.pick(
                                  'İzledim listesine ekle',
                                  'Mark as Watched',
                                ),
                                active: status == WatchStatus.watched,
                                activeColor: Colors.green.shade600,
                                onPressed: () =>
                                    onQuickStatus(WatchStatus.watched),
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
                                  final added = await toggleFavoriteTitle(
                                    ref,
                                    summary.key,
                                  );
                                  if (added && status == null) {
                                    onQuickStatus(WatchStatus.planned);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      if (widget.progressLabel != null)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: _Badge(
                              icon: Icons.tv,
                              label: widget.progressLabel!,
                              background: Colors.black87,
                              foreground: Colors.white,
                            ),
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

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.posterPath});

  final String? posterPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = posterPath;
    if (path == null) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.movie_outlined,
          size: 48,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return Image.network(
      tmdbPosterUrl(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
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
