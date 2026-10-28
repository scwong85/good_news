import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/providers.dart';
import '../shared/formatting.dart';
import '../shared/widgets.dart';

const exploreTopics = ['environment', 'science', 'health', 'education', 'technology', 'community', 'development', 'society', 'culture'];
const exploreStoryTypes = [
  'progress', 'solution', 'community', 'science_health', 'environment', 'education_opportunity', 'human_interest', 'technology_for_good', //
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(exploreQueryProvider.notifier).setText(value);
    });
    setState(() {}); // show/hide the clear button
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(exploreQueryProvider);
    final results = ref.watch(exploreResultsProvider);
    final notifier = ref.read(exploreQueryProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final filterCount = query.storyTypes.length + query.regions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search stories',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _controller.clear();
                                  notifier.setText('');
                                  setState(() {});
                                },
                              ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Badge(
                    isLabelVisible: filterCount > 0,
                    label: Text('$filterCount'),
                    child: IconButton.filledTonal(
                      tooltip: 'More filters',
                      icon: const Icon(Icons.tune),
                      onPressed: () => _showFilters(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final t in exploreTopics)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(topicLabel(t)),
                        selected: query.topics.contains(t),
                        onSelected: (_) => notifier.toggleTopic(t),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: results.when(
                skipLoadingOnReload: true, // keep the list (and scroll position) while it refreshes
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const EmptyState(icon: Icons.error_outline, title: "Couldn't load stories", message: 'Please try again in a moment.'),
                data: (stories) {
                  if (stories.isEmpty) {
                    return ScrollableCenter(
                      child: EmptyState(
                        icon: Icons.search_off,
                        illustration: const SproutMark(size: 84),
                        title: query.isEmpty ? 'Nothing here yet' : 'No stories match',
                        message: query.isEmpty
                            ? 'Open Today first so the app can fetch the latest stories.'
                            : 'Try removing a filter or searching for something else.',
                        action: query.isEmpty
                            ? null
                            : FilledButton.tonal(
                                onPressed: () {
                                  _controller.clear();
                                  notifier.clear();
                                  setState(() {});
                                },
                                child: const Text('Clear filters'),
                              ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: stories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Semantics(
                          liveRegion: true,
                          child: Text(
                            '${stories.length} ${stories.length == 1 ? 'story' : 'stories'} from the last two weeks',
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        );
                      }
                      final story = stories[i - 1];
                      return StoryCard(story: story, onOpen: () => context.push('/story/${story.id}'));
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

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FiltersSheet(),
    );
  }
}

class _FiltersSheet extends ConsumerWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(exploreQueryProvider);
    final notifier = ref.read(exploreQueryProvider.notifier);
    final regions = ref.watch(regionsProvider).value ?? const <String>[];
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type of story', style: text.titleMedium),
            const SizedBox(height: 4),
            Text('Tags are assigned automatically and can be imperfect.', style: text.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in exploreStoryTypes)
                  FilterChip(
                    label: Text(storyTypeLabel(t)),
                    selected: query.storyTypes.contains(t),
                    onSelected: (_) => notifier.toggleType(t),
                  ),
              ],
            ),
            if (regions.length > 1) ...[
              const SizedBox(height: 20),
              Text('Region', style: text.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in regions)
                    FilterChip(label: Text(topicLabel(r)), selected: query.regions.contains(r), onSelected: (_) => notifier.toggleRegion(r)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: notifier.clear, child: const Text('Clear all filters')),
            ),
          ],
        ),
      ),
    );
  }
}
