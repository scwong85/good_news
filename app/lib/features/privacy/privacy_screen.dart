import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../shared/widgets.dart';
import 'legal_text.dart';

final _policyProvider = FutureProvider<String>(
  (ref) => rootBundle.loadString('assets/legal/privacy_policy.md', cache: false),
);

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final policy = ref.watch(_policyProvider);
    final contact = ref.watch(appConfigProvider).contactEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: policy.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const ScrollableCenter(child: EmptyState(icon: Icons.error_outline, title: "Couldn't load the policy")),
        data: (markdown) {
          final doc = parseLegal(markdown, contactEmail: contact);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in doc.blocks)
                    switch (b.kind) {
                      LegalKind.heading => Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 6),
                          child: Semantics(header: true, child: Text(b.text, style: text.titleMedium)),
                        ),
                      LegalKind.bullet => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(padding: const EdgeInsets.only(top: 8, right: 10), child: Icon(Icons.circle, size: 6, color: scheme.primary)),
                              Expanded(child: Text(b.text, style: text.bodyMedium?.copyWith(height: 1.45))),
                            ],
                          ),
                        ),
                      LegalKind.paragraph => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(b.text, style: text.bodyMedium?.copyWith(height: 1.45)),
                        ),
                    },
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
