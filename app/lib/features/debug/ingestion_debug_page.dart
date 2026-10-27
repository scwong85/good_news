import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../ingestion/ingestion_service.dart';

/// Phase 3 harness, not the product UI (Today/Explore/etc. arrive in Phase 5).
/// Opening it runs the fetch-on-open flow and shows what was stored.
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
  int _total = 0;

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
      final report = await ref.read(ingestionServiceProvider).refresh(force: force);
      final sources = await db.allSources();
      final articles = await db.latestArticles(limit: 50);
      final total = await db.articleCount();
      if (!mounted) return;
      setState(() {
        _report = report;
        _sources = sources;
        _articles = articles;
        _total = total;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good News (Phase 3 harness)'),
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
                '${a.topics.isEmpty ? '' : ' · ${a.topics.join(', ')}'}',
              ),
            ),
        ],
      ),
    );
  }
}
