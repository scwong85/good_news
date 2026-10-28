import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/brand.dart';
import '../../app/copy.dart';
import '../../app/providers.dart';
import '../shared/widgets.dart';

/// First run: three short cards (what this is, how stories are chosen, your privacy), then the
/// reader's first Today. Skippable; the only thing stored is one local flag.
class WelcomeOverlay extends ConsumerStatefulWidget {
  const WelcomeOverlay({super.key});

  @override
  ConsumerState<WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends ConsumerState<WelcomeOverlay> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() => ref.read(welcomeStateProvider.notifier).markSeen();

  void _next() {
    if (_page == welcomePages.length - 1) {
      _finish();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final last = _page == welcomePages.length - 1;
    return Material(
      key: const Key('welcome'),
      color: scheme.surface,
      child: SafeArea(
        child: ContentWidth(
          maxWidth: 520,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text(welcomeSkip),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (var i = 0; i < welcomePages.length; i++)
                      ScrollableCenter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 24),
                              i == 2
                                  ? const SproutMark(size: 120)
                                  : const SunriseMark(size: 120),
                              const SizedBox(height: 28),
                              Semantics(
                                header: true,
                                child: Text(
                                  welcomePages[i].title,
                                  style: text.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                welcomePages[i].body,
                                style: text.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < welcomePages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(last ? welcomeStart : welcomeNext),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
