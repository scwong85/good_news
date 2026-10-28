import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/brand.dart';
import '../../app/copy.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../story/why_included.dart';
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
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action, this.illustration});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// A drawn mark (sunrise, sprout) shown instead of the plain icon.
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration ??
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: scheme.onSecondaryContainer),
              ),
          const SizedBox(height: 20),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// A small pill with the topic's icon and name (never colour alone).
class TopicChip extends StatelessWidget {
  const TopicChip({super.key, required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context) {
    final style = topicStyle(topic, Theme.of(context).brightness);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: style.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 5),
          Flexible(child: Text(topicLabel(topic), style: text.labelMedium?.copyWith(color: style.color), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// A story in a list: topic, source, date, headline, excerpt, why it was chosen and a save
/// button. [lead] is the larger first story of the day.
class StoryCard extends ConsumerWidget {
  const StoryCard({super.key, required this.story, required this.onOpen, this.onSavedToggle, this.lead = false});

  final Story story;
  final VoidCallback onOpen;
  final bool lead;

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
    final reasons = whyIncluded(story).reasons;

    return Card(
      key: Key('story-card-${story.id}'),
      clipBehavior: Clip.antiAlias,
      color: lead ? scheme.tertiaryContainer.withValues(alpha: 0.45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: '${lead ? "$todayLead. " : ""}${story.title}. ${story.sourceName}. $date.${topics.isEmpty ? '' : ' $topics.'} Opens the story.',
            excludeSemantics: true,
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, lead ? 18 : 16, 18, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lead) ...[
                      Row(children: [
                        Icon(Icons.wb_sunny_outlined, size: 18, color: scheme.tertiary),
                        const SizedBox(width: 6),
                        Flexible(child: Text(todayLead, style: text.labelLarge?.copyWith(color: scheme.tertiary))),
                      ]),
                      const SizedBox(height: 10),
                    ],
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (story.topics.isNotEmpty) TopicChip(topic: story.topics.first),
                        Text('${story.sourceName}  ·  $date', style: text.labelLarge?.copyWith(color: scheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(story.title, style: lead ? text.leadTitle : text.storyTitle),
                    if (story.excerpt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        story.excerpt,
                        maxLines: lead ? 4 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                      ),
                    ],
                    if (reasons.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_outline, size: 16, color: scheme.primary)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(reasons.first, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: IconButton(
                tooltip: saved ? 'Remove from saved' : 'Save story',
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                color: saved ? scheme.tertiary : null,
                onPressed: () {
                  final toggle = onSavedToggle;
                  if (toggle != null) {
                    toggle(story, saved);
                  } else {
                    ref.read(storyActionsProvider).toggleSaved(story, isSaved: saved);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
