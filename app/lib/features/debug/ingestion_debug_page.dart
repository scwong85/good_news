import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../ingestion/ingestion_service.dart';
import '../../selection/daily_selector.dart';

/// Phase 3/4 harness, not the product UI (Today/Explore/etc. arrive in Phase 5).
/// Opening it runs the fetch-on-open flow, then shows today's picks and what was stored.
class IngestionDebugPage extends ConsumerStatefulWidget {
  const IngestionDebugPage({super.key});

  @override
  ConsumerState<IngestionDebugPage> createState() => _IngestionDebugPageState();
}

class _IngestionDebugPageState extends ConsumerState<IngestionDebugPage> {
  bool _loading = true;
  String? _error;
  IngestionReport? _report;
  List<SourceRow> _sources = const [];
  List<ArticleRow> _articles = const [];
  List<ArticleRow> _picks = const [];
  int _total = 0;
  int _perDay = defaultStoriesPerDay;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({bool force = false}) async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      await db.upsertBundledSources(await ref.read(bundledSourcesProvider.future));
      final report = await (await ref.read(ingestionServiceProvider.future)).refresh(force: force);
      await _loadViews(report: report);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadViews({IngestionReport? report}) async {
    final db = ref.read(databaseProvider);
    final picks = await ref.read(dailyPicksServiceProvider).todaysPicks();
    final prefs = await ref.read(preferencesRepositoryProvider).load();
    final sources = await db.allSources();
    final articles = await db.latestArticles(limit: 30);
    final total = await db.articleCount();
    if (!mounted) return;
    setState(() {
      _report = report ?? _report;
      _picks = picks;
      _perDay = prefs.storiesPerDay;
      _sources = sources;
      _articles = articles;
      _total = total;
      _error = null;
    });
  }

  Future<void> _setPerDay(int n) async {
    await ref.read(preferencesRepositoryProvider).setStoriesPerDay(n);
    await _loadViews();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good News (Phase 4 harness)'),
        actions: [
          IconButton(
            tooltip: 'Force refresh',
            onPressed: _loading ? null : () => _refresh(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Text('Error: $_error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          Text('Stored articles: $_total', style: text.titleMedium),
          if (_report != null)
            Text('Last refresh: ${_report!.totalNew} new, ${_report!.failed} source(s) failed', style: text.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text("Today's picks (${_picks.length})", style: text.titleSmall)),
              IconButton(
                tooltip: 'Fewer stories per day',
                onPressed: _perDay > minStoriesPerDay ? () => _setPerDay(_perDay - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$_perDay / day'),
              IconButton(
                tooltip: 'More stories per day',
                onPressed: _perDay < maxStoriesPerDay ? () => _setPerDay(_perDay + 1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          for (final a in _picks)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(a.title),
              subtitle: Text(
                '${a.route} · ${(a.constructiveScore ?? 0).toStringAsFixed(2)}'
                '${a.topics.isEmpty ? '' : ' · ${a.topics.join(', ')}'}',
              ),
            ),
          const SizedBox(height: 12),
          Text('Sources', style: text.titleSmall),
          for (final s in _sources)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(s.name),
              subtitle: Text(s.lastStatus ?? 'not fetched yet'),
              trailing: Switch(
                value: s.userEnabled,
                onChanged: (v) async {
                  await ref.read(databaseProvider).setSourceEnabled(s.id, v);
                  await _refresh();
                },
              ),
            ),
          const SizedBox(height: 12),
          Text('Latest articles', style: text.titleSmall),
          for (final a in _articles)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(a.title),
              subtitle: Text(
                '${a.publishedAt.toUtc().toIso8601String().substring(0, 10)}'
                ' · ${a.route ?? 'unclassified'}'
                '${a.topics.isEmpty ? '' : ' · ${a.topics.join(', ')}'}',
              ),
            ),
        ],
      ),
    );
  }
}
