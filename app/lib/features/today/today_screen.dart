import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../shared/formatting.dart';
import '../shared/widgets.dart';
import 'today_controller.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);
    final now = ref.watch(clockProvider)();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final updated = state.lastUpdated == null ? null : 'Updated ${formatUpdated(state.lastUpdated!, now)}';
    final count = state.picks.length;

    final children = <Widget>[
      Text('Today', style: text.pageTitle),
      const SizedBox(height: 2),
      Text(
        [
          formatLongDay(now),
          if (count > 0) '$count ${count == 1 ? 'story' : 'stories'}',
          ?updated,
        ].join('  ·  '),
        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      ..._banner(state),
    ];

    if (state.loading && state.picks.isEmpty) {
      children.add(const _Gathering());
    } else if (state.picks.isEmpty) {
      children.add(EmptyState(
        icon: Icons.wb_twilight,
        title: 'No stories to show yet',
        message: state.issue == RefreshIssue.offline
            ? "You seem to be offline. We'll show today's stories as soon as we can reach the news sources."
            : "We couldn't find enough good stories right now. Try again in a little while.",
        action: FilledButton.tonal(
          onPressed: state.refreshing ? null : () => controller.refresh(manual: true),
          child: const Text('Try again'),
        ),
      ));
    } else {
      for (final story in state.picks) {
        children
          ..add(StoryCard(story: story, onOpen: () => context.push('/story/${story.id}')))
          ..add(const SizedBox(height: 12));
      }
      children.add(_EndOfToday(onExplore: () => context.go('/explore')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good News'),
        actions: [
          IconButton(
            tooltip: 'Refresh stories',
            onPressed: state.refreshing ? null : () => controller.refresh(manual: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: state.refreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3, semanticsLabel: 'Refreshing stories'),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(manual: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [ContentWidth(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children))],
        ),
      ),
    );
  }

  /// Notices about a refresh problem. Only shown next to stories; with nothing to show, the
  /// empty state already explains the situation.
  List<Widget> _banner(TodayState s) {
    if (s.picks.isEmpty) return const [];
    switch (s.issue) {
      case RefreshIssue.offline:
        return const [
          StatusBanner(icon: Icons.cloud_off, text: "You're offline. Showing your latest stories."),
          SizedBox(height: 16),
        ];
      case RefreshIssue.partial:
        return [
          StatusBanner(
            icon: Icons.info_outline,
            text: "${s.failedSources} of ${s.totalSources} sources couldn't be reached. Showing what we have.",
          ),
          const SizedBox(height: 16),
        ];
      case RefreshIssue.failed:
        return const [
          StatusBanner(icon: Icons.error_outline, text: 'Something went wrong while refreshing. Showing your latest stories.'),
          SizedBox(height: 16),
        ];
      case RefreshIssue.none:
        return const [];
    }
  }
}

class _Gathering extends StatelessWidget {
  const _Gathering();

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: "Gathering today's stories",
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Gathering today's stories…"),
            ],
          ),
        ),
      );
}

class _EndOfToday extends StatelessWidget {
  const _EndOfToday({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: scheme.primary),
          const SizedBox(height: 8),
          Text("That's everything for today.", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Come back tomorrow for more.', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextButton(onPressed: onExplore, child: const Text('Browse more in Explore')),
        ],
      ),
    );
  }
}
