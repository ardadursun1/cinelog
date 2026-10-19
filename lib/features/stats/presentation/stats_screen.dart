import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_type.dart';
import '../../../core/settings/app_settings_providers.dart';
import '../../library/domain/watch_status.dart';
import '../data/stats_dao.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentLanguageProvider);
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          lang.pick(
            'İstatistikler yüklenemedi: $e',
            'Could not load statistics: $e',
          ),
        ),
      ),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryCard(
                  icon: Icons.check_circle_outline,
                  title: lang.pick('Toplam İzlenen', 'Total Watched'),
                  value: '${stats.count(WatchStatus.watched)}',
                  subtitle: lang.pick(
                    '${stats.count(WatchStatus.watched, MediaType.movie)} film · '
                        '${stats.count(WatchStatus.watched, MediaType.tv)} dizi',
                    '${stats.count(WatchStatus.watched, MediaType.movie)} movies · '
                        '${stats.count(WatchStatus.watched, MediaType.tv)} TV shows',
                  ),
                ),
                _SummaryCard(
                  icon: Icons.play_circle_outline,
                  title: lang.pick('İzleniyor', 'Watching'),
                  value: '${stats.count(WatchStatus.watching)}',
                  subtitle: lang.pick(
                    '${stats.count(WatchStatus.watching, MediaType.movie)} film · '
                        '${stats.count(WatchStatus.watching, MediaType.tv)} dizi',
                    '${stats.count(WatchStatus.watching, MediaType.movie)} movies · '
                        '${stats.count(WatchStatus.watching, MediaType.tv)} TV shows',
                  ),
                ),
                _SummaryCard(
                  icon: Icons.bookmark_outline,
                  title: lang.pick('İzlenecek', 'Plan to Watch'),
                  value: '${stats.count(WatchStatus.planned)}',
                  subtitle: lang.pick(
                    '${stats.count(WatchStatus.planned, MediaType.movie)} film · '
                        '${stats.count(WatchStatus.planned, MediaType.tv)} dizi',
                    '${stats.count(WatchStatus.planned, MediaType.movie)} movies · '
                        '${stats.count(WatchStatus.planned, MediaType.tv)} TV shows',
                  ),
                ),
                _SummaryCard(
                  icon: Icons.tv_outlined,
                  title: lang.pick('İzlenen Bölüm', 'Watched Episodes'),
                  value: '${stats.watchedEpisodes}',
                  subtitle: lang.pick(
                    'Toplam tamamlanan dizi bölümü',
                    'Total completed TV episodes',
                  ),
                ),
                _SummaryCard(
                  icon: Icons.schedule_outlined,
                  title: lang.pick(
                    'Tahmini İzleme Süresi',
                    'Est. Watch Time',
                  ),
                  value: stats.watchTimePrimaryLabelFor(lang),
                  subtitle: stats.watchTimeSubtitleFor(lang),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _BarSection(
              title: lang.pick(
                'Tür Dağılımı (İzlenenler)',
                'Genre Breakdown (Watched)',
              ),
              emptyText: lang.pick(
                'Henüz "İzledim" olarak işaretlenmiş kayıt yok.',
                'No titles marked as "Watched" yet.',
              ),
              rows: [
                for (final g in stats.genres) (g.label, g.count),
              ],
            ),
            const SizedBox(height: 28),
            _BarSection(
              title: lang.pick(
                'Yapım Yılına Göre İzlenenler',
                'Watched by Release Year',
              ),
              emptyText: lang.pick(
                'Henüz "İzledim" olarak işaretlenmiş kayıt yok.',
                'No titles marked as "Watched" yet.',
              ),
              rows: [
                for (final y in stats.releaseYears) ('${y.label}', y.count),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarSection extends StatelessWidget {
  const _BarSection({
    required this.title,
    required this.emptyText,
    required this.rows,
  });

  final String title;
  final String emptyText;
  final List<(String label, int count)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxCount = rows.fold<int>(0, (m, r) => math.max(m, r.$2));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              Text(
                emptyText,
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              for (final (label, count) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            value: maxCount > 0 ? count / maxCount : 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
