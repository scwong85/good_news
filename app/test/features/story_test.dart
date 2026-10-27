import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/features/shared/story.dart';

void main() {
  final story = Story(
    id: 'abc',
    title: 'Wetlands restored',
    excerpt: 'A short excerpt.',
    url: 'https://example.com/wet',
    sourceId: 's1',
    sourceName: 'Example News',
    publishedAt: DateTime.utc(2026, 10, 27, 7),
    topics: const ['environment'],
    storyTypes: const ['solution'],
    evidenceSignals: const ['data_cited'],
    route: 'today',
    score: 0.71,
    rulesVersion: '2026.11.2',
    explanationJson: '{"reason":"","rules":[]}',
  );

  test('a snapshot round-trips everything needed to show the story offline', () {
    final copy = Story.fromSnapshot(story.toSnapshot());
    expect(copy.id, story.id);
    expect(copy.title, story.title);
    expect(copy.excerpt, story.excerpt);
    expect(copy.url, story.url);
    expect(copy.sourceName, story.sourceName);
    expect(copy.publishedAt, story.publishedAt);
    expect(copy.topics, story.topics);
    expect(copy.route, 'today');
    expect(copy.score, 0.71);
    expect(copy.explanationJson, story.explanationJson);
    expect(copy.saved, isTrue);
    expect(copy.fromSnapshot, isTrue);
  });

  test('a snapshot holds only headline, short excerpt, attribution, link and the explanation', () {
    final keys = (jsonDecode(story.toSnapshot()) as Map<String, dynamic>).keys.toSet();
    expect(keys, {
      'id', 'title', 'excerpt', 'url', 'source_id', 'source_name', 'published_at', 'topics',
      'story_types', 'evidence_signals', 'route', 'score', 'rules_version', 'explanation', //
    });
  });

  test('an old or sparse snapshot still loads', () {
    final s = Story.fromSnapshot(jsonEncode({
      'id': 'x', 'title': 'T', 'url': 'https://e.com/x', 'published_at': '2026-10-01T00:00:00Z', //
    }));
    expect(s.excerpt, '');
    expect(s.sourceName, '');
    expect(s.topics, isEmpty);
    expect(s.route, isNull);
    expect(s.score, isNull);
  });

  test('copyWith changes only the saved flag', () {
    final saved = story.copyWith(saved: true);
    expect(saved.saved, isTrue);
    expect(saved.title, story.title);
    expect(story.saved, isFalse);
  });
}
