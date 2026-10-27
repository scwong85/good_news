import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../shared/story.dart';
import '../shared/widgets.dart';

/// Saved stories. They come from stored snapshots, so they work offline and survive the
/// automatic clean-up of old articles.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedStoriesProvider);

    Future<void> toggle(Story story, bool wasSaved) async {
      await ref.read(storyActionsProvider).toggleSaved(story, isSaved: wasSaved);
      if (!context.mounted || !wasSaved) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: const Text('Removed from saved'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => ref.read(storyActionsProvider).toggleSaved(story, isSaved: false),
          ),
        ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(icon: Icons.error_outline, title: "Couldn't load saved stories"),
        data: (stories) {
          if (stories.isEmpty) {
            return const ScrollableCenter(
              child: EmptyState(
                icon: Icons.bookmark_border,
                title: 'Nothing saved yet',
                message: 'Tap the bookmark on any story to keep it here. Saved stories are available offline.',
              ),
            );
          }
          return ContentWidth(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: stories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => StoryCard(
                story: stories[i],
                onSavedToggle: toggle,
                onOpen: () => context.push('/story/${stories[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
