/// A curated feed source (bundled from `docs/source-allowlist.csv`).
class Source {
  const Source({
    required this.id,
    required this.name,
    required this.homepageUrl,
    required this.rssUrl,
    required this.tier,
    required this.trustScore,
    required this.language,
    required this.regions,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        id: json['id'] as String,
        name: json['name'] as String,
        homepageUrl: json['homepage_url'] as String,
        rssUrl: json['rss_url'] as String,
        tier: json['tier'] as int,
        trustScore: (json['trust_score'] as num).toDouble(),
        language: json['language'] as String,
        regions: List<String>.from(json['regions'] as List),
      );

  final String id;
  final String name;
  final String homepageUrl;
  final String rssUrl;
  final int tier;
  final double trustScore;
  final String language;
  final List<String> regions;
}
