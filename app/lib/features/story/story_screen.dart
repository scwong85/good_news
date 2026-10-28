import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../selection/feedback_service.dart';
import '../shared/formatting.dart';
import '../today/today_controller.dart';
import '../shared/story.dart';
import '../shared/widgets.dart';
import 'why_included.dart';

class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key, required this.storyId});
  final String storyId;

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  @override
  void initState() {
    super.initState();
    // Opening a story counts as seeing it, so it won't be picked again.
    Future.microtask(() => ref.read(storyActionsProvider).markSeen(widget.storyId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storyProvider(widget.storyId));
    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (_, _) => _Missing(),
      data: (story) => story == null ? _Missing() : _StoryView(story: story),
    );
  }
}

class _Missing extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: ScrollableCenter(
          child: EmptyState(
            icon: Icons.search_off,
            title: 'This story is no longer available',
            message: 'It may have been removed from the app after a while.',
            action: FilledButton.tonal(onPressed: () => context.pop(), child: const Text('Go back')),
          ),
        ),
      );
}

class _StoryView extends ConsumerWidget {
  const _StoryView({required this.story});
  final Story story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider)();
    final saved = ref.watch(savedIdsProvider).value?.contains(story.id) ?? story.saved;
    final why = whyIncluded(story);

    Future<void> openOriginal() async {
      final ok = await ref.read(linkOpenerProvider).open(Uri.parse(story.url));
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open the link.")));
      }
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save story',
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => ref.read(storyActionsProvider).toggleSaved(story, isSaved: saved),
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ref.read(sharerProvider).share(title: story.title, url: Uri.parse(story.url)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${story.sourceName}  ·  ${formatStoryDate(story.publishedAt, now)}',
                  style: text.labelLarge?.copyWith(color: scheme.primary)),
              const SizedBox(height: 12),
              Semantics(header: true, child: Text(story.title, style: text.storyHeadline)),
              if (story.topics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [for (final t in story.topics) Chip(label: Text(topicLabel(t)), visualDensity: VisualDensity.compact)],
                ),
              ],
              if (story.excerpt.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(story.excerpt, style: text.bodyLarge?.copyWith(height: 1.5)),
              ],
              const SizedBox(height: 8),
              Text(
                'This is a short excerpt from ${story.sourceName}. Read the full story on their site.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openOriginal,
                  icon: const Icon(Icons.open_in_new),
                  label: Text('Read at ${story.sourceName}'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
              const SizedBox(height: 28),
              _WhySection(why: why),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Hide or report this story'),
                  onPressed: () => _hide(context, ref, story),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _hide(BuildContext context, WidgetRef ref, Story story) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final reason = await showModalBottomSheet<HideReason>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _HideSheet(),
  );
  if (reason == null) return;
  // Read everything from `ref` now: this screen is gone by the time Undo is tapped.
  final service = ref.read(feedbackServiceProvider);
  final version = ref.read(dataVersionProvider.notifier);
  final today = ref.read(todayControllerProvider.notifier);
  await service.hide(articleId: story.id, sourceId: story.sourceId, reason: reason);
  version.bump();
  await today.reloadPicks(extend: true); // refill the slot
  if (navigator.canPop()) navigator.pop();
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: const Text('Story hidden on this phone'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await service.restore(story.id);
          version.bump();
          await today.reloadPicks(extend: true);
        },
      ),
    ));
}

class _HideSheet extends StatelessWidget {
  const _HideSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Why hide this story?', style: text.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'This stays on your phone. The story will not appear again, and you can bring it back under Settings, Hidden stories.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            for (final r in HideReason.values)
              ListTile(
                title: Text(r.label),
                subtitle: Text(r.description),
                onTap: () => Navigator.of(context).pop(r),
              ),
          ],
        ),
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  const _WhySection({required this.why});
  final WhyIncluded why;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget bullets(List<String> items, IconData icon) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 18, color: scheme.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r, style: text.bodyMedium)),
                  ],
                ),
              ),
          ],
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text('Why this story was included', style: text.titleMedium)),
            const SizedBox(height: 8),
            Text(why.headline, style: text.bodyMedium),
            if (why.reasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              bullets(why.reasons, Icons.check_circle_outline),
            ],
            if (why.cautions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Worth knowing', style: text.labelLarge),
              const SizedBox(height: 6),
              bullets(why.cautions, Icons.info_outline),
            ],
            const SizedBox(height: 8),
            Text(why.footnote, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            if (why.detail != null) ...[
              const SizedBox(height: 6),
              Text(why.detail!, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
