import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_type.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/network/tmdb_models.dart';
import '../../../core/network/tmdb_providers.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../../core/widgets/poster_card.dart';
import '../../../core/widgets/responsive_poster_grid.dart';
import '../../library/presentation/library_providers.dart';
import 'title_detail_dialog.dart';

Future<void> showPersonCreditsDialog(
  BuildContext context, {
  required int personId,
  required String fallbackName,
  String? fallbackProfilePath,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => PersonCreditsDialog(
      personId: personId,
      fallbackName: fallbackName,
      fallbackProfilePath: fallbackProfilePath,
    ),
  );
}

class PersonCreditsDialog extends ConsumerStatefulWidget {
  const PersonCreditsDialog({
    super.key,
    required this.personId,
    required this.fallbackName,
    this.fallbackProfilePath,
  });

  final int personId;
  final String fallbackName;
  final String? fallbackProfilePath;

  @override
  ConsumerState<PersonCreditsDialog> createState() =>
      _PersonCreditsDialogState();
}

class _PersonCreditsDialogState extends ConsumerState<PersonCreditsDialog> {
  MediaType? _mediaFilter;
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentLanguageProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detailsAsync = ref.watch(personDetailsProvider(widget.personId));
    final genreMap = ref.watch(genreNamesProvider).value ??
        const <MediaType, Map<int, String>>{};
    final statusIndex = ref.watch(libraryStatusIndexProvider);

    final person = detailsAsync.value;
    final displayName = (person != null && person.name.isNotEmpty)
        ? person.name
        : widget.fallbackName;
    final profilePath = person?.profilePath ?? widget.fallbackProfilePath;

    final metaParts = <String>[
      if (person != null && person.birthYear != null) '${person.birthYear}',
      if (person != null && person.placeOfBirth.isNotEmpty) person.placeOfBirth,
    ];

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940, maxHeight: 780),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 76,
                      height: 96,
                      child: profilePath != null
                          ? Image.network(
                              tmdbPosterUrl(profilePath, size: 'w185'),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: const Icon(
                                  Icons.person_outline,
                                  size: 36,
                                ),
                              ),
                            )
                          : ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: const Icon(Icons.person_outline, size: 36),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: lang.pick('Kapat', 'Close'),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        if (metaParts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              metaParts.join(' · '),
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (person != null && person.biography.isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () =>
                                setState(() => _bioExpanded = !_bioExpanded),
                            child: Text(
                              person.biography,
                              maxLines: _bioExpanded ? 8 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(lang.pick('Tümü', 'All')),
                              selected: _mediaFilter == null,
                              onSelected: (_) =>
                                  setState(() => _mediaFilter = null),
                            ),
                            for (final type in MediaType.values)
                              FilterChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(type.labelFor(lang)),
                                selected: _mediaFilter == type,
                                onSelected: (selected) => setState(
                                  () => _mediaFilter = selected ? type : null,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: detailsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      userMessageFor(err, lang),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (data) {
                  final allCredits = data?.credits ?? const <TmdbSearchItem>[];
                  final filtered = _mediaFilter == null
                      ? allCredits
                      : [
                          for (final item in allCredits)
                            if (item.mediaType == _mediaFilter) item,
                        ];
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        lang.pick(
                          'Bu kişi için listelenecek yapım bulunamadı.',
                          'No titles found for this person.',
                        ),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ResponsivePosterGrid(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final summary = item.toSummary(
                        genreMap[item.mediaType] ?? const {},
                      );
                      return PosterCard(
                        summary: summary,
                        status: statusIndex[item.key],
                        onQuickStatus: (targetStatus) =>
                            toggleQuickStatusWithFeedback(
                          context,
                          ref,
                          summary,
                          targetStatus,
                        ),
                        onTap: () => showTitleDetailDialog(context, summary),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
