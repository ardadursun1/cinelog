import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_settings_providers.dart';

class MissingKeyHint extends ConsumerWidget {
  const MissingKeyHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentLanguageProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.key_outlined, size: 28, color: scheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      lang.pick(
                        'TMDB API Anahtarı Gerekli',
                        'TMDB API Key Required',
                      ),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lang.pick(
                    'Film ve dizi araması yapabilmek için ücretsiz bir TMDB API anahtarı girmelisin:',
                    'To search and browse movies & TV shows, please enter a free TMDB API key:',
                  ),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  lang.pick(
                    '1. themoviedb.org adresinden ücretsiz hesap aç.',
                    '1. Create a free account at themoviedb.org.',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.pick(
                    '2. Hesap Ayarları → API bölümüne git.',
                    '2. Go to Account Settings → API.',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.pick(
                    '3. "API Anahtarı (v3 auth)" veya "API Okuma Erişim Jetonu" değerini kopyala.',
                    '3. Copy your "API Key (v3 auth)" or "API Read Access Token".',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.pick(
                    '4. Uygulamanın Ayarlar ekranına yapıştırıp kaydet.',
                    '4. Paste it into the Settings screen and save.',
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(
                      lang.pick('Ayarlar\'a Git', 'Go to Settings'),
                    ),
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

