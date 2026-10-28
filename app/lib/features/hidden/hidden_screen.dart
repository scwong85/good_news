import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../shared/formatting.dart';
import '../shared/widgets.dart';

/// Stories the reader hid or reported, with a way to bring each back.
class HiddenScreen extends ConsumerWidget {
  const HiddenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hiddenStoriesProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: const Text('Hidden stories')),
      body: hidden.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const ScrollableCenter(child: EmptyState(icon: Icons.error_outline, title: "Couldn't load hidden stories")),
        data: (stories) {
          if (stories.isEmpty) {
            return const ScrollableCenter(
              child: EmptyState(
                icon: Icons.visibility_outlined,
                title: 'No hidden stories',
                message: 'Stories you hide or report appear here, so you can bring them back.',
              ),
            );
          }
          return ContentWidth(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: stories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = stories[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.sourceName}  ·  ${formatStoryDate(s.publishedAt, now)}', style: text.labelMedium?.copyWith(color: scheme.primary)),
                        const SizedBox(height: 4),
                        Text(s.title, style: text.bodyLarge),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Show again'),
                            onPressed: () async {
                              await ref.read(feedbackServiceProvider).restore(s.id);
                              ref.read(dataVersionProvider.notifier).bump();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
