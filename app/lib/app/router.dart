import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/explore/explore_screen.dart';
import '../features/hidden/hidden_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/story/story_screen.dart';
import '../features/today/today_screen.dart';
import '../features/welcome/welcome_overlay.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // One navigator key per router: a shared top-level key breaks multiple app instances (tests).
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) => _TabPager(shell: shell, children: children),
        branches: [
          StatefulShellBranch(preload: true, routes: [GoRoute(path: '/', builder: (_, _) => const TodayScreen())]),
          StatefulShellBranch(preload: true, routes: [GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen())]),
          StatefulShellBranch(preload: true, routes: [GoRoute(path: '/saved', builder: (_, _) => const SavedScreen())]),
          StatefulShellBranch(preload: true, routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
        ],
      ),
      GoRoute(
        path: '/story/:id',
        parentNavigatorKey: rootKey,
        builder: (_, state) => StoryScreen(storyId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/about', parentNavigatorKey: rootKey, builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/hidden', parentNavigatorKey: rootKey, builder: (_, _) => const HiddenScreen()),
      GoRoute(path: '/privacy', parentNavigatorKey: rootKey, builder: (_, _) => const PrivacyScreen()),
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
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(welcomeStateProvider);
    final shellView = _layout(context);
    return seen ? shellView : Stack(children: [shellView, const Positioned.fill(child: WelcomeOverlay())]);
  }

  Widget _layout(BuildContext context) {
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

/// The tabs side by side in a [PageView]: dragging follows the finger and settles smoothly, and
/// tapping a tab slides to it. Every tab stays alive, so scroll positions and searches survive.
/// Scrollable children (topic chips, the slider) take their own horizontal drags first.
class _TabPager extends StatefulWidget {
  const _TabPager({required this.shell, required this.children});
  final StatefulNavigationShell shell;
  final List<Widget> children;

  @override
  State<_TabPager> createState() => _TabPagerState();
}

class _TabPagerState extends State<_TabPager> {
  late final PageController _controller = PageController(initialPage: widget.shell.currentIndex);
  bool _animating = false; // a tap-driven slide passes through the tabs in between

  @override
  void didUpdateWidget(_TabPager old) {
    super.didUpdateWidget(old);
    final target = widget.shell.currentIndex;
    if (!_controller.hasClients || (_controller.page ?? target.toDouble()).round() == target) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(target);
    } else {
      _animating = true;
      _controller
          .animateToPage(target, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic)
          .whenComplete(() => _animating = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
        controller: _controller,
        onPageChanged: (i) {
          if (!_animating && i != widget.shell.currentIndex) widget.shell.goBranch(i);
        },
        children: [
          for (var i = 0; i < widget.children.length; i++)
            // Every tab stays alive, but only tabs that are on screen are visible to touch,
            // search and screen readers (like an indexed stack, with a sliding hand-over).
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final page = _controller.hasClients && _controller.position.haveDimensions
                    ? _controller.page!
                    : widget.shell.currentIndex.toDouble();
                return Offstage(offstage: (i - page).abs() >= 1, child: child);
              },
              child: _KeepAlive(child: widget.children[i]),
            ),
        ],
      );
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
