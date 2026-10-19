import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../settings/app_settings_providers.dart';
import 'search_focus.dart';

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _focusSearch(WidgetRef ref) {
    navigationShell.goBranch(0);
    ref.read(searchFocusSignalProvider.notifier).trigger();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentLanguageProvider);
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _FocusSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              _focusSearch(ref);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_movies_rounded,
                          size: 26,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CineLog',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.search_outlined),
                      selectedIcon: const Icon(Icons.search),
                      label: Text(lang.pick('Ara', 'Search')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.video_library_outlined),
                      selectedIcon: const Icon(Icons.video_library),
                      label: Text(lang.pick('Kütüphane', 'Library')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.bar_chart_outlined),
                      selectedIcon: const Icon(Icons.bar_chart),
                      label: Text(lang.pick('İstatistik', 'Stats')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(lang.pick('Ayarlar', 'Settings')),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
