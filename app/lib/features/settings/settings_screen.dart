import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/providers.dart';
import '../../selection/daily_selector.dart';
import '../explore/explore_screen.dart' show exploreTopics;
import '../shared/formatting.dart';
import '../shared/widgets.dart';
import '../today/today_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider).value;
    final sources = ref.watch(sourcesProvider).value ?? const [];
    final regions = ref.watch(regionsProvider).value ?? const <String>[];
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(preferencesRepositoryProvider);
    final today = ref.read(todayControllerProvider.notifier);

    Future<void> changed() async => ref.read(dataVersionProvider.notifier).bump();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stories per day', style: text.titleMedium),
                      const SizedBox(height: 4),
                      _StoriesPerDaySlider(
                        stored: prefs.storiesPerDay,
                        onCommitted: (n) async {
                          await repo.setStoriesPerDay(n);
                          await today.reloadPicks(extend: true);
                          await changed();
                        },
                      ),
                      Text('Between $minStoriesPerDay and $maxStoriesPerDay. Today keeps the stories it already chose and adds more if you raise this.',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 28),
                      Text('Topics you like', style: text.titleMedium),
                      const SizedBox(height: 4),
                      Text('We prefer these when choosing your stories. Other topics can still appear.',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final t in exploreTopics)
                            FilterChip(
                              label: Text(topicLabel(t)),
                              selected: prefs.topics.contains(t),
                              onSelected: (on) async {
                                final next = {...prefs.topics};
                                on ? next.add(t) : next.remove(t);
                                await repo.setTopics(next);
                                await changed();
                              },
                            ),
                        ],
                      ),
                      if (regions.length > 1) ...[
                        const SizedBox(height: 24),
                        Text('Regions', style: text.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final r in regions)
                              FilterChip(
                                label: Text(topicLabel(r)),
                                selected: prefs.regions.contains(r),
                                onSelected: (on) async {
                                  final next = {...prefs.regions};
                                  on ? next.add(r) : next.remove(r);
                                  await repo.setRegions(next);
                                  await changed();
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      Text('Sources', style: text.titleMedium),
                      const SizedBox(height: 4),
                      Text('Turn a source off and its stories stop appearing in Explore and in new picks.',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                for (final s in sources)
                  ContentWidth(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.name),
                      subtitle: Text(Uri.tryParse(s.homepageUrl)?.host ?? s.homepageUrl),
                      value: s.userEnabled,
                      onChanged: (on) async {
                        await ref.read(databaseProvider).setSourceEnabled(s.id, on);
                        await changed();
                        if (on) await today.refresh();
                      },
                    ),
                  ),
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About and how stories are chosen'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/about'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No account. Nothing about you leaves this phone: the app only asks the news sources for their latest headlines.',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Slider that only saves (and extends today's picks) when the reader lets go, not on every step.
class _StoriesPerDaySlider extends StatefulWidget {
  const _StoriesPerDaySlider({required this.stored, required this.onCommitted});
  final int stored;
  final Future<void> Function(int) onCommitted;

  @override
  State<_StoriesPerDaySlider> createState() => _StoriesPerDaySliderState();
}

class _StoriesPerDaySliderState extends State<_StoriesPerDaySlider> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final value = _dragging ?? widget.stored.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${value.round()} stories', style: Theme.of(context).textTheme.bodyLarge),
        Slider(
          value: value,
          min: minStoriesPerDay.toDouble(),
          max: maxStoriesPerDay.toDouble(),
          divisions: maxStoriesPerDay - minStoriesPerDay,
          label: '${value.round()}',
          semanticFormatterCallback: (v) => '${v.round()} stories per day',
          onChanged: (v) => setState(() => _dragging = v),
          onChangeEnd: (v) async {
            await widget.onCommitted(v.round());
            if (mounted) setState(() => _dragging = null);
          },
        ),
      ],
    );
  }
}
