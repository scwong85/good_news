import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/brand.dart';
import '../../app/copy.dart';
import '../../app/providers.dart';
import '../../core/providers.dart';
import '../shared/widgets.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final sources = ref.watch(sourcesProvider).value ?? const [];
    final rules = ref.watch(rulesProvider).value;

    Widget section(String title, List<String> paragraphs) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(title, style: text.titleMedium)),
              const SizedBox(height: 8),
              for (final p in paragraphs)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(p, style: text.bodyMedium?.copyWith(height: 1.45))),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const SunriseMark(size: 56),
                    const SizedBox(width: 14),
                    Expanded(child: Text(trustBadge, style: text.titleSmall?.copyWith(color: scheme.onSecondaryContainer, height: 1.35))),
                  ],
                ),
              ),
              section('What this app is', [
                'A small daily briefing of credible, constructive news: progress, solutions, recovery, '
                    'cooperation and discovery. It is not a filter that calls all news good or bad.',
              ]),
              section('How stories are chosen', [
                'The app asks a hand-picked list of news sources for their latest headlines and short excerpts. '
                    'It then scores each one against published rules that look for things like progress, solutions, '
                    'people working together, research and measurable results, and that mark down lists, advice, '
                    'opinion, promotion and distressing news.',
                'The strongest matches go to Today. Close matches appear in Explore, and fill Today when there are '
                    'too few strong ones. Stories about the same news are grouped so you see one.',
              ]),
              section('What to keep in mind', [
                'The choice is automatic and based only on the headline and a short excerpt. No person checks each '
                    'story, and the app cannot verify facts. It will sometimes miss good stories or include imperfect ones. '
                    'Each story explains why it was included.',
                'The app shows only the headline, a short excerpt, the source and a link. The full story is always on '
                    "the publisher's own site.",
              ]),
              section('Your privacy', [
                'No account, no ads and no tracking. Your saved stories and settings stay on this phone. The only '
                    'network traffic is asking the news sources for their latest headlines when you open the app, '
                    'and opening a story in your browser when you tap it.',
              ]),
              Semantics(header: true, child: Text('Sources', style: text.titleMedium)),
              const SizedBox(height: 8),
              for (final s in sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${s.name} · ${Uri.tryParse(s.homepageUrl)?.host ?? s.homepageUrl}', style: text.bodyMedium),
                ),
              if (rules != null) ...[
                const SizedBox(height: 24),
                Text('Selection rules version ${rules.version}', style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
