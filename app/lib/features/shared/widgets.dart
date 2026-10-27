import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import 'formatting.dart';
import 'story.dart';

/// Keeps reading lines at a comfortable width on tablets.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

/// Centres [child] when there is room and scrolls when there is not (small screens, large text).
class ScrollableCenter extends StatelessWidget {
  const ScrollableCenter({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Center(child: child),
          ),
        ),
      );
}

/// A quiet notice (offline, partial refresh, ...). Announced to screen readers when it appears.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer))),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.primary),
          const SizedBox(height: 16),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// A story in a list: headline, source, date, excerpt, topics and a save button.
class StoryCard extends ConsumerWidget {
  const StoryCard({super.key, required this.story, required this.onOpen, this.onSavedToggle});

  final Story story;
  final VoidCallback onOpen;

  /// Overrides the default save/unsave (for example to offer "Undo" on the Saved screen).
  final Future<void> Function(Story story, bool wasSaved)? onSavedToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider)();
    final saved = ref.watch(savedIdsProvider).value?.contains(story.id) ?? story.saved;
    final date = formatStoryDate(story.publishedAt, now);
    final topics = story.topics.take(2).map(topicLabel).join(' · ');

    return Card(
      key: Key('story-card-${story.id}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: '${story.title}. ${story.sourceName}. $date.${topics.isEmpty ? '' : ' $topics.'} Opens the story.',
            excludeSemantics: true,
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${story.sourceName}  ·  $date',
                      style: text.labelLarge?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(story.title, style: text.storyTitle),
                    if (story.excerpt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        story.excerpt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(topics, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  tooltip: saved ? 'Remove from saved' : 'Save story',
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () {
                    final toggle = onSavedToggle;
                    if (toggle != null) {
                      toggle(story, saved);
                    } else {
                      ref.read(storyActionsProvider).toggleSaved(story, isSaved: saved);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
