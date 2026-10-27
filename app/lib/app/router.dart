import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/explore/explore_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/story/story_screen.dart';
import '../features/today/today_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // One navigator key per router: a shared top-level key breaks multiple app instances (tests).
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const TodayScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/saved', builder: (_, _) => const SavedScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
        ],
      ),
      GoRoute(
        path: '/story/:id',
        parentNavigatorKey: rootKey,
        builder: (_, state) => StoryScreen(storyId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/about', parentNavigatorKey: rootKey, builder: (_, _) => const AboutScreen()),
    ],
  );
});

const _destinations = [
  (icon: Icons.wb_sunny_outlined, selected: Icons.wb_sunny, label: 'Today'),
  (icon: Icons.explore_outlined, selected: Icons.explore, label: 'Explore'),
  (icon: Icons.bookmark_border, selected: Icons.bookmark, label: 'Saved'),
  (icon: Icons.tune, selected: Icons.tune, label: 'Settings'),
];

/// Bottom navigation on phones, a navigation rail on tablets.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: d.label),
        ],
      ),
    );
  }
}
