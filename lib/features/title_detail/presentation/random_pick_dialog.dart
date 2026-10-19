import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/title_summary.dart';
import '../../../core/network/tmdb_models.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../library/domain/watch_status.dart';
import '../../library/presentation/library_providers.dart';
import 'title_detail_dialog.dart';

Future<void> showRandomPickDialog(
  BuildContext context, {
  required List<TitleSummary> candidates,
  required String sourceLabel,
}) {
  if (candidates.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Öneri yapılabilecek film veya dizi bulunamadı.'),
      ),
    );
    return Future.value();
  }
  return showDialog<void>(
    context: context,
    builder: (_) => _RandomPickDialog(
      candidates: candidates,
      sourceLabel: sourceLabel,
    ),
  );
}

class _RandomPickDialog extends ConsumerStatefulWidget {
  const _RandomPickDialog({
    required this.candidates,
    required this.sourceLabel,
  });

  final List<TitleSummary> candidates;
  final String sourceLabel;

  @override
  ConsumerState<_RandomPickDialog> createState() => _RandomPickDialogState();
}

class _RandomPickDialogState extends ConsumerState<_RandomPickDialog> {
  final math.Random _random = math.Random();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _random.nextInt(widget.candidates.length);
  }

  void _pickAnother() {
    if (widget.candidates.length <= 1) return;
    int next = _currentIndex;
    while (next == _currentIndex) {
      next = _random.nextInt(widget.candidates.length);
    }
    setState(() => _currentIndex = next);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentLanguageProvider);
    final summary = widget.candidates[_currentIndex];
    final status = ref.watch(libraryStatusIndexProvider)[summary.key];
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.casino_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.pick('Ne İzlesem?', 'Surprise Me')),
                Text(
                  widget.sourceLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: lang.pick('Kapat', 'Close'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 140,
                height: 210,
                child: summary.posterPath != null
                    ? Image.network(
                        tmdbPosterUrl(summary.posterPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(Icons.movie, size: 42),
                        ),
                      )
                    : ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.movie, size: 42),
                      ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      summary.metaLabelFor(lang),
                      if (summary.voteAverage != null)
                        '★ ${summary.voteAverage!.toStringAsFixed(1)}',
                    ].join(' · '),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary.overview.isNotEmpty
                        ? summary.overview
                        : lang.pick(
                            'Özet bulunmuyor.',
                            'No overview available.',
                          ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.candidates.length > 1)
          OutlinedButton.icon(
            onPressed: _pickAnother,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(lang.pick('Başka Öner', 'Pick Another')),
          ),
        if (status != WatchStatus.planned && status != WatchStatus.watched)
          FilledButton.tonalIcon(
            onPressed: () {
              ref
                  .read(libraryServiceProvider)
                  .setOrAddStatus(summary, WatchStatus.planned);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              lang.pick('İzleneceklere Ekle', 'Add to Watchlist'),
            ),
          ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            showTitleDetailDialog(context, summary);
          },
          icon: const Icon(Icons.info_outline, size: 18),
          label: Text(
            lang.pick('Detaylar & Fragman', 'Details & Trailer'),
          ),
        ),
      ],
    );
  }
}

