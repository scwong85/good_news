// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homepageUrlMeta = const VerificationMeta(
    'homepageUrl',
  );
  @override
  late final GeneratedColumn<String> homepageUrl = GeneratedColumn<String>(
    'homepage_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rssUrlMeta = const VerificationMeta('rssUrl');
  @override
  late final GeneratedColumn<String> rssUrl = GeneratedColumn<String>(
    'rss_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<int> tier = GeneratedColumn<int>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trustScoreMeta = const VerificationMeta(
    'trustScore',
  );
  @override
  late final GeneratedColumn<double> trustScore = GeneratedColumn<double>(
    'trust_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> regions =
      GeneratedColumn<String>(
        'regions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($SourcesTable.$converterregions);
  static const VerificationMeta _userEnabledMeta = const VerificationMeta(
    'userEnabled',
  );
  @override
  late final GeneratedColumn<bool> userEnabled = GeneratedColumn<bool>(
    'user_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastStatusMeta = const VerificationMeta(
    'lastStatus',
  );
  @override
  late final GeneratedColumn<String> lastStatus = GeneratedColumn<String>(
    'last_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consecutiveFailuresMeta =
      const VerificationMeta('consecutiveFailures');
  @override
  late final GeneratedColumn<int> consecutiveFailures = GeneratedColumn<int>(
    'consecutive_failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _backoffUntilMeta = const VerificationMeta(
    'backoffUntil',
  );
  @override
  late final GeneratedColumn<DateTime> backoffUntil = GeneratedColumn<DateTime>(
    'backoff_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    homepageUrl,
    rssUrl,
    tier,
    trustScore,
    language,
    regions,
    userEnabled,
    etag,
    lastModified,
    lastFetchedAt,
    lastStatus,
    consecutiveFailures,
    backoffUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('homepage_url')) {
      context.handle(
        _homepageUrlMeta,
        homepageUrl.isAcceptableOrUnknown(
          data['homepage_url']!,
          _homepageUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_homepageUrlMeta);
    }
    if (data.containsKey('rss_url')) {
      context.handle(
        _rssUrlMeta,
        rssUrl.isAcceptableOrUnknown(data['rss_url']!, _rssUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_rssUrlMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('trust_score')) {
      context.handle(
        _trustScoreMeta,
        trustScore.isAcceptableOrUnknown(data['trust_score']!, _trustScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_trustScoreMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('user_enabled')) {
      context.handle(
        _userEnabledMeta,
        userEnabled.isAcceptableOrUnknown(
          data['user_enabled']!,
          _userEnabledMeta,
        ),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_status')) {
      context.handle(
        _lastStatusMeta,
        lastStatus.isAcceptableOrUnknown(data['last_status']!, _lastStatusMeta),
      );
    }
    if (data.containsKey('consecutive_failures')) {
      context.handle(
        _consecutiveFailuresMeta,
        consecutiveFailures.isAcceptableOrUnknown(
          data['consecutive_failures']!,
          _consecutiveFailuresMeta,
        ),
      );
    }
    if (data.containsKey('backoff_until')) {
      context.handle(
        _backoffUntilMeta,
        backoffUntil.isAcceptableOrUnknown(
          data['backoff_until']!,
          _backoffUntilMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      homepageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}homepage_url'],
      )!,
      rssUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rss_url'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tier'],
      )!,
      trustScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}trust_score'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      regions: $SourcesTable.$converterregions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}regions'],
        )!,
      ),
      userEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_enabled'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      ),
      lastStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_status'],
      ),
      consecutiveFailures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_failures'],
      )!,
      backoffUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}backoff_until'],
      ),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterregions =
      const StringListConverter();
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  final String id;
  final String name;
  final String homepageUrl;
  final String rssUrl;
  final int tier;
  final double trustScore;
  final String language;
  final List<String> regions;
  final bool userEnabled;
  final String etag;
  final String lastModified;
  final DateTime? lastFetchedAt;
  final String? lastStatus;
  final int consecutiveFailures;
  final DateTime? backoffUntil;
  const SourceRow({
    required this.id,
    required this.name,
    required this.homepageUrl,
    required this.rssUrl,
    required this.tier,
    required this.trustScore,
    required this.language,
    required this.regions,
    required this.userEnabled,
    required this.etag,
    required this.lastModified,
    this.lastFetchedAt,
    this.lastStatus,
    required this.consecutiveFailures,
    this.backoffUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['homepage_url'] = Variable<String>(homepageUrl);
    map['rss_url'] = Variable<String>(rssUrl);
    map['tier'] = Variable<int>(tier);
    map['trust_score'] = Variable<double>(trustScore);
    map['language'] = Variable<String>(language);
    {
      map['regions'] = Variable<String>(
        $SourcesTable.$converterregions.toSql(regions),
      );
    }
    map['user_enabled'] = Variable<bool>(userEnabled);
    map['etag'] = Variable<String>(etag);
    map['last_modified'] = Variable<String>(lastModified);
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    }
    if (!nullToAbsent || lastStatus != null) {
      map['last_status'] = Variable<String>(lastStatus);
    }
    map['consecutive_failures'] = Variable<int>(consecutiveFailures);
    if (!nullToAbsent || backoffUntil != null) {
      map['backoff_until'] = Variable<DateTime>(backoffUntil);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      name: Value(name),
      homepageUrl: Value(homepageUrl),
      rssUrl: Value(rssUrl),
      tier: Value(tier),
      trustScore: Value(trustScore),
      language: Value(language),
      regions: Value(regions),
      userEnabled: Value(userEnabled),
      etag: Value(etag),
      lastModified: Value(lastModified),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
      lastStatus: lastStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStatus),
      consecutiveFailures: Value(consecutiveFailures),
      backoffUntil: backoffUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(backoffUntil),
    );
  }

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      homepageUrl: serializer.fromJson<String>(json['homepageUrl']),
      rssUrl: serializer.fromJson<String>(json['rssUrl']),
      tier: serializer.fromJson<int>(json['tier']),
      trustScore: serializer.fromJson<double>(json['trustScore']),
      language: serializer.fromJson<String>(json['language']),
      regions: serializer.fromJson<List<String>>(json['regions']),
      userEnabled: serializer.fromJson<bool>(json['userEnabled']),
      etag: serializer.fromJson<String>(json['etag']),
      lastModified: serializer.fromJson<String>(json['lastModified']),
      lastFetchedAt: serializer.fromJson<DateTime?>(json['lastFetchedAt']),
      lastStatus: serializer.fromJson<String?>(json['lastStatus']),
      consecutiveFailures: serializer.fromJson<int>(
        json['consecutiveFailures'],
      ),
      backoffUntil: serializer.fromJson<DateTime?>(json['backoffUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'homepageUrl': serializer.toJson<String>(homepageUrl),
      'rssUrl': serializer.toJson<String>(rssUrl),
      'tier': serializer.toJson<int>(tier),
      'trustScore': serializer.toJson<double>(trustScore),
      'language': serializer.toJson<String>(language),
      'regions': serializer.toJson<List<String>>(regions),
      'userEnabled': serializer.toJson<bool>(userEnabled),
      'etag': serializer.toJson<String>(etag),
      'lastModified': serializer.toJson<String>(lastModified),
      'lastFetchedAt': serializer.toJson<DateTime?>(lastFetchedAt),
      'lastStatus': serializer.toJson<String?>(lastStatus),
      'consecutiveFailures': serializer.toJson<int>(consecutiveFailures),
      'backoffUntil': serializer.toJson<DateTime?>(backoffUntil),
    };
  }

  SourceRow copyWith({
    String? id,
    String? name,
    String? homepageUrl,
    String? rssUrl,
    int? tier,
    double? trustScore,
    String? language,
    List<String>? regions,
    bool? userEnabled,
    String? etag,
    String? lastModified,
    Value<DateTime?> lastFetchedAt = const Value.absent(),
    Value<String?> lastStatus = const Value.absent(),
    int? consecutiveFailures,
    Value<DateTime?> backoffUntil = const Value.absent(),
  }) => SourceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    homepageUrl: homepageUrl ?? this.homepageUrl,
    rssUrl: rssUrl ?? this.rssUrl,
    tier: tier ?? this.tier,
    trustScore: trustScore ?? this.trustScore,
    language: language ?? this.language,
    regions: regions ?? this.regions,
    userEnabled: userEnabled ?? this.userEnabled,
    etag: etag ?? this.etag,
    lastModified: lastModified ?? this.lastModified,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
    lastStatus: lastStatus.present ? lastStatus.value : this.lastStatus,
    consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    backoffUntil: backoffUntil.present ? backoffUntil.value : this.backoffUntil,
  );
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      homepageUrl: data.homepageUrl.present
          ? data.homepageUrl.value
          : this.homepageUrl,
      rssUrl: data.rssUrl.present ? data.rssUrl.value : this.rssUrl,
      tier: data.tier.present ? data.tier.value : this.tier,
      trustScore: data.trustScore.present
          ? data.trustScore.value
          : this.trustScore,
      language: data.language.present ? data.language.value : this.language,
      regions: data.regions.present ? data.regions.value : this.regions,
      userEnabled: data.userEnabled.present
          ? data.userEnabled.value
          : this.userEnabled,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
      lastStatus: data.lastStatus.present
          ? data.lastStatus.value
          : this.lastStatus,
      consecutiveFailures: data.consecutiveFailures.present
          ? data.consecutiveFailures.value
          : this.consecutiveFailures,
      backoffUntil: data.backoffUntil.present
          ? data.backoffUntil.value
          : this.backoffUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('homepageUrl: $homepageUrl, ')
          ..write('rssUrl: $rssUrl, ')
          ..write('tier: $tier, ')
          ..write('trustScore: $trustScore, ')
          ..write('language: $language, ')
          ..write('regions: $regions, ')
          ..write('userEnabled: $userEnabled, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastStatus: $lastStatus, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('backoffUntil: $backoffUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    homepageUrl,
    rssUrl,
    tier,
    trustScore,
    language,
    regions,
    userEnabled,
    etag,
    lastModified,
    lastFetchedAt,
    lastStatus,
    consecutiveFailures,
    backoffUntil,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.homepageUrl == this.homepageUrl &&
          other.rssUrl == this.rssUrl &&
          other.tier == this.tier &&
          other.trustScore == this.trustScore &&
          other.language == this.language &&
          other.regions == this.regions &&
          other.userEnabled == this.userEnabled &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified &&
          other.lastFetchedAt == this.lastFetchedAt &&
          other.lastStatus == this.lastStatus &&
          other.consecutiveFailures == this.consecutiveFailures &&
          other.backoffUntil == this.backoffUntil);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> homepageUrl;
  final Value<String> rssUrl;
  final Value<int> tier;
  final Value<double> trustScore;
  final Value<String> language;
  final Value<List<String>> regions;
  final Value<bool> userEnabled;
  final Value<String> etag;
  final Value<String> lastModified;
  final Value<DateTime?> lastFetchedAt;
  final Value<String?> lastStatus;
  final Value<int> consecutiveFailures;
  final Value<DateTime?> backoffUntil;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.homepageUrl = const Value.absent(),
    this.rssUrl = const Value.absent(),
    this.tier = const Value.absent(),
    this.trustScore = const Value.absent(),
    this.language = const Value.absent(),
    this.regions = const Value.absent(),
    this.userEnabled = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastStatus = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    this.backoffUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String name,
    required String homepageUrl,
    required String rssUrl,
    required int tier,
    required double trustScore,
    required String language,
    required List<String> regions,
    this.userEnabled = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastStatus = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    this.backoffUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       homepageUrl = Value(homepageUrl),
       rssUrl = Value(rssUrl),
       tier = Value(tier),
       trustScore = Value(trustScore),
       language = Value(language),
       regions = Value(regions);
  static Insertable<SourceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? homepageUrl,
    Expression<String>? rssUrl,
    Expression<int>? tier,
    Expression<double>? trustScore,
    Expression<String>? language,
    Expression<String>? regions,
    Expression<bool>? userEnabled,
    Expression<String>? etag,
    Expression<String>? lastModified,
    Expression<DateTime>? lastFetchedAt,
    Expression<String>? lastStatus,
    Expression<int>? consecutiveFailures,
    Expression<DateTime>? backoffUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (homepageUrl != null) 'homepage_url': homepageUrl,
      if (rssUrl != null) 'rss_url': rssUrl,
      if (tier != null) 'tier': tier,
      if (trustScore != null) 'trust_score': trustScore,
      if (language != null) 'language': language,
      if (regions != null) 'regions': regions,
      if (userEnabled != null) 'user_enabled': userEnabled,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (lastStatus != null) 'last_status': lastStatus,
      if (consecutiveFailures != null)
        'consecutive_failures': consecutiveFailures,
      if (backoffUntil != null) 'backoff_until': backoffUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? homepageUrl,
    Value<String>? rssUrl,
    Value<int>? tier,
    Value<double>? trustScore,
    Value<String>? language,
    Value<List<String>>? regions,
    Value<bool>? userEnabled,
    Value<String>? etag,
    Value<String>? lastModified,
    Value<DateTime?>? lastFetchedAt,
    Value<String?>? lastStatus,
    Value<int>? consecutiveFailures,
    Value<DateTime?>? backoffUntil,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      homepageUrl: homepageUrl ?? this.homepageUrl,
      rssUrl: rssUrl ?? this.rssUrl,
      tier: tier ?? this.tier,
      trustScore: trustScore ?? this.trustScore,
      language: language ?? this.language,
      regions: regions ?? this.regions,
      userEnabled: userEnabled ?? this.userEnabled,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastStatus: lastStatus ?? this.lastStatus,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      backoffUntil: backoffUntil ?? this.backoffUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (homepageUrl.present) {
      map['homepage_url'] = Variable<String>(homepageUrl.value);
    }
    if (rssUrl.present) {
      map['rss_url'] = Variable<String>(rssUrl.value);
    }
    if (tier.present) {
      map['tier'] = Variable<int>(tier.value);
    }
    if (trustScore.present) {
      map['trust_score'] = Variable<double>(trustScore.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (regions.present) {
      map['regions'] = Variable<String>(
        $SourcesTable.$converterregions.toSql(regions.value),
      );
    }
    if (userEnabled.present) {
      map['user_enabled'] = Variable<bool>(userEnabled.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    if (lastStatus.present) {
      map['last_status'] = Variable<String>(lastStatus.value);
    }
    if (consecutiveFailures.present) {
      map['consecutive_failures'] = Variable<int>(consecutiveFailures.value);
    }
    if (backoffUntil.present) {
      map['backoff_until'] = Variable<DateTime>(backoffUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('homepageUrl: $homepageUrl, ')
          ..write('rssUrl: $rssUrl, ')
          ..write('tier: $tier, ')
          ..write('trustScore: $trustScore, ')
          ..write('language: $language, ')
          ..write('regions: $regions, ')
          ..write('userEnabled: $userEnabled, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastStatus: $lastStatus, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('backoffUntil: $backoffUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArticlesTable extends Articles
    with TableInfo<$ArticlesTable, ArticleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _canonicalUrlMeta = const VerificationMeta(
    'canonicalUrl',
  );
  @override
  late final GeneratedColumn<String> canonicalUrl = GeneratedColumn<String>(
    'canonical_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excerptMeta = const VerificationMeta(
    'excerpt',
  );
  @override
  late final GeneratedColumn<String> excerpt = GeneratedColumn<String>(
    'excerpt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> regions =
      GeneratedColumn<String>(
        'regions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ArticlesTable.$converterregions);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> topics =
      GeneratedColumn<String>(
        'topics',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ArticlesTable.$convertertopics);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> storyTypes =
      GeneratedColumn<String>(
        'story_types',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($ArticlesTable.$converterstoryTypes);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  evidenceSignals = GeneratedColumn<String>(
    'evidence_signals',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($ArticlesTable.$converterevidenceSignals);
  static const VerificationMeta _constructiveScoreMeta = const VerificationMeta(
    'constructiveScore',
  );
  @override
  late final GeneratedColumn<double> constructiveScore =
      GeneratedColumn<double>(
        'constructive_score',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rulesVersionMeta = const VerificationMeta(
    'rulesVersion',
  );
  @override
  late final GeneratedColumn<String> rulesVersion = GeneratedColumn<String>(
    'rules_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<String> clusterId = GeneratedColumn<String>(
    'cluster_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    canonicalUrl,
    title,
    excerpt,
    publishedAt,
    fetchedAt,
    language,
    regions,
    topics,
    storyTypes,
    evidenceSignals,
    constructiveScore,
    route,
    explanation,
    rulesVersion,
    clusterId,
    hidden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('canonical_url')) {
      context.handle(
        _canonicalUrlMeta,
        canonicalUrl.isAcceptableOrUnknown(
          data['canonical_url']!,
          _canonicalUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalUrlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('excerpt')) {
      context.handle(
        _excerptMeta,
        excerpt.isAcceptableOrUnknown(data['excerpt']!, _excerptMeta),
      );
    } else if (isInserting) {
      context.missing(_excerptMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('constructive_score')) {
      context.handle(
        _constructiveScoreMeta,
        constructiveScore.isAcceptableOrUnknown(
          data['constructive_score']!,
          _constructiveScoreMeta,
        ),
      );
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
      );
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('rules_version')) {
      context.handle(
        _rulesVersionMeta,
        rulesVersion.isAcceptableOrUnknown(
          data['rules_version']!,
          _rulesVersionMeta,
        ),
      );
    }
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      canonicalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      excerpt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excerpt'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      regions: $ArticlesTable.$converterregions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}regions'],
        )!,
      ),
      topics: $ArticlesTable.$convertertopics.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}topics'],
        )!,
      ),
      storyTypes: $ArticlesTable.$converterstoryTypes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}story_types'],
        )!,
      ),
      evidenceSignals: $ArticlesTable.$converterevidenceSignals.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}evidence_signals'],
        )!,
      ),
      constructiveScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}constructive_score'],
      ),
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      ),
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      rulesVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rules_version'],
      ),
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cluster_id'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
    );
  }

  @override
  $ArticlesTable createAlias(String alias) {
    return $ArticlesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterregions =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertertopics =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterstoryTypes =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterevidenceSignals =
      const StringListConverter();
}

class ArticleRow extends DataClass implements Insertable<ArticleRow> {
  /// First 16 hex characters of sha1(canonicalUrl).
  final String id;
  final String sourceId;
  final String canonicalUrl;
  final String title;
  final String excerpt;
  final DateTime publishedAt;
  final DateTime fetchedAt;
  final String language;
  final List<String> regions;
  final List<String> topics;
  final List<String> storyTypes;
  final List<String> evidenceSignals;
  final double? constructiveScore;
  final String? route;
  final String? explanation;
  final String? rulesVersion;
  final String? clusterId;
  final bool hidden;
  const ArticleRow({
    required this.id,
    required this.sourceId,
    required this.canonicalUrl,
    required this.title,
    required this.excerpt,
    required this.publishedAt,
    required this.fetchedAt,
    required this.language,
    required this.regions,
    required this.topics,
    required this.storyTypes,
    required this.evidenceSignals,
    this.constructiveScore,
    this.route,
    this.explanation,
    this.rulesVersion,
    this.clusterId,
    required this.hidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['canonical_url'] = Variable<String>(canonicalUrl);
    map['title'] = Variable<String>(title);
    map['excerpt'] = Variable<String>(excerpt);
    map['published_at'] = Variable<DateTime>(publishedAt);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['language'] = Variable<String>(language);
    {
      map['regions'] = Variable<String>(
        $ArticlesTable.$converterregions.toSql(regions),
      );
    }
    {
      map['topics'] = Variable<String>(
        $ArticlesTable.$convertertopics.toSql(topics),
      );
    }
    {
      map['story_types'] = Variable<String>(
        $ArticlesTable.$converterstoryTypes.toSql(storyTypes),
      );
    }
    {
      map['evidence_signals'] = Variable<String>(
        $ArticlesTable.$converterevidenceSignals.toSql(evidenceSignals),
      );
    }
    if (!nullToAbsent || constructiveScore != null) {
      map['constructive_score'] = Variable<double>(constructiveScore);
    }
    if (!nullToAbsent || route != null) {
      map['route'] = Variable<String>(route);
    }
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || rulesVersion != null) {
      map['rules_version'] = Variable<String>(rulesVersion);
    }
    if (!nullToAbsent || clusterId != null) {
      map['cluster_id'] = Variable<String>(clusterId);
    }
    map['hidden'] = Variable<bool>(hidden);
    return map;
  }

  ArticlesCompanion toCompanion(bool nullToAbsent) {
    return ArticlesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      canonicalUrl: Value(canonicalUrl),
      title: Value(title),
      excerpt: Value(excerpt),
      publishedAt: Value(publishedAt),
      fetchedAt: Value(fetchedAt),
      language: Value(language),
      regions: Value(regions),
      topics: Value(topics),
      storyTypes: Value(storyTypes),
      evidenceSignals: Value(evidenceSignals),
      constructiveScore: constructiveScore == null && nullToAbsent
          ? const Value.absent()
          : Value(constructiveScore),
      route: route == null && nullToAbsent
          ? const Value.absent()
          : Value(route),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      rulesVersion: rulesVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(rulesVersion),
      clusterId: clusterId == null && nullToAbsent
          ? const Value.absent()
          : Value(clusterId),
      hidden: Value(hidden),
    );
  }

  factory ArticleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      canonicalUrl: serializer.fromJson<String>(json['canonicalUrl']),
      title: serializer.fromJson<String>(json['title']),
      excerpt: serializer.fromJson<String>(json['excerpt']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      language: serializer.fromJson<String>(json['language']),
      regions: serializer.fromJson<List<String>>(json['regions']),
      topics: serializer.fromJson<List<String>>(json['topics']),
      storyTypes: serializer.fromJson<List<String>>(json['storyTypes']),
      evidenceSignals: serializer.fromJson<List<String>>(
        json['evidenceSignals'],
      ),
      constructiveScore: serializer.fromJson<double?>(
        json['constructiveScore'],
      ),
      route: serializer.fromJson<String?>(json['route']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      rulesVersion: serializer.fromJson<String?>(json['rulesVersion']),
      clusterId: serializer.fromJson<String?>(json['clusterId']),
      hidden: serializer.fromJson<bool>(json['hidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'canonicalUrl': serializer.toJson<String>(canonicalUrl),
      'title': serializer.toJson<String>(title),
      'excerpt': serializer.toJson<String>(excerpt),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'language': serializer.toJson<String>(language),
      'regions': serializer.toJson<List<String>>(regions),
      'topics': serializer.toJson<List<String>>(topics),
      'storyTypes': serializer.toJson<List<String>>(storyTypes),
      'evidenceSignals': serializer.toJson<List<String>>(evidenceSignals),
      'constructiveScore': serializer.toJson<double?>(constructiveScore),
      'route': serializer.toJson<String?>(route),
      'explanation': serializer.toJson<String?>(explanation),
      'rulesVersion': serializer.toJson<String?>(rulesVersion),
      'clusterId': serializer.toJson<String?>(clusterId),
      'hidden': serializer.toJson<bool>(hidden),
    };
  }

  ArticleRow copyWith({
    String? id,
    String? sourceId,
    String? canonicalUrl,
    String? title,
    String? excerpt,
    DateTime? publishedAt,
    DateTime? fetchedAt,
    String? language,
    List<String>? regions,
    List<String>? topics,
    List<String>? storyTypes,
    List<String>? evidenceSignals,
    Value<double?> constructiveScore = const Value.absent(),
    Value<String?> route = const Value.absent(),
    Value<String?> explanation = const Value.absent(),
    Value<String?> rulesVersion = const Value.absent(),
    Value<String?> clusterId = const Value.absent(),
    bool? hidden,
  }) => ArticleRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    canonicalUrl: canonicalUrl ?? this.canonicalUrl,
    title: title ?? this.title,
    excerpt: excerpt ?? this.excerpt,
    publishedAt: publishedAt ?? this.publishedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    language: language ?? this.language,
    regions: regions ?? this.regions,
    topics: topics ?? this.topics,
    storyTypes: storyTypes ?? this.storyTypes,
    evidenceSignals: evidenceSignals ?? this.evidenceSignals,
    constructiveScore: constructiveScore.present
        ? constructiveScore.value
        : this.constructiveScore,
    route: route.present ? route.value : this.route,
    explanation: explanation.present ? explanation.value : this.explanation,
    rulesVersion: rulesVersion.present ? rulesVersion.value : this.rulesVersion,
    clusterId: clusterId.present ? clusterId.value : this.clusterId,
    hidden: hidden ?? this.hidden,
  );
  ArticleRow copyWithCompanion(ArticlesCompanion data) {
    return ArticleRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      canonicalUrl: data.canonicalUrl.present
          ? data.canonicalUrl.value
          : this.canonicalUrl,
      title: data.title.present ? data.title.value : this.title,
      excerpt: data.excerpt.present ? data.excerpt.value : this.excerpt,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      language: data.language.present ? data.language.value : this.language,
      regions: data.regions.present ? data.regions.value : this.regions,
      topics: data.topics.present ? data.topics.value : this.topics,
      storyTypes: data.storyTypes.present
          ? data.storyTypes.value
          : this.storyTypes,
      evidenceSignals: data.evidenceSignals.present
          ? data.evidenceSignals.value
          : this.evidenceSignals,
      constructiveScore: data.constructiveScore.present
          ? data.constructiveScore.value
          : this.constructiveScore,
      route: data.route.present ? data.route.value : this.route,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      rulesVersion: data.rulesVersion.present
          ? data.rulesVersion.value
          : this.rulesVersion,
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('canonicalUrl: $canonicalUrl, ')
          ..write('title: $title, ')
          ..write('excerpt: $excerpt, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('language: $language, ')
          ..write('regions: $regions, ')
          ..write('topics: $topics, ')
          ..write('storyTypes: $storyTypes, ')
          ..write('evidenceSignals: $evidenceSignals, ')
          ..write('constructiveScore: $constructiveScore, ')
          ..write('route: $route, ')
          ..write('explanation: $explanation, ')
          ..write('rulesVersion: $rulesVersion, ')
          ..write('clusterId: $clusterId, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    canonicalUrl,
    title,
    excerpt,
    publishedAt,
    fetchedAt,
    language,
    regions,
    topics,
    storyTypes,
    evidenceSignals,
    constructiveScore,
    route,
    explanation,
    rulesVersion,
    clusterId,
    hidden,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.canonicalUrl == this.canonicalUrl &&
          other.title == this.title &&
          other.excerpt == this.excerpt &&
          other.publishedAt == this.publishedAt &&
          other.fetchedAt == this.fetchedAt &&
          other.language == this.language &&
          other.regions == this.regions &&
          other.topics == this.topics &&
          other.storyTypes == this.storyTypes &&
          other.evidenceSignals == this.evidenceSignals &&
          other.constructiveScore == this.constructiveScore &&
          other.route == this.route &&
          other.explanation == this.explanation &&
          other.rulesVersion == this.rulesVersion &&
          other.clusterId == this.clusterId &&
          other.hidden == this.hidden);
}

class ArticlesCompanion extends UpdateCompanion<ArticleRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String> canonicalUrl;
  final Value<String> title;
  final Value<String> excerpt;
  final Value<DateTime> publishedAt;
  final Value<DateTime> fetchedAt;
  final Value<String> language;
  final Value<List<String>> regions;
  final Value<List<String>> topics;
  final Value<List<String>> storyTypes;
  final Value<List<String>> evidenceSignals;
  final Value<double?> constructiveScore;
  final Value<String?> route;
  final Value<String?> explanation;
  final Value<String?> rulesVersion;
  final Value<String?> clusterId;
  final Value<bool> hidden;
  final Value<int> rowid;
  const ArticlesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.canonicalUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.language = const Value.absent(),
    this.regions = const Value.absent(),
    this.topics = const Value.absent(),
    this.storyTypes = const Value.absent(),
    this.evidenceSignals = const Value.absent(),
    this.constructiveScore = const Value.absent(),
    this.route = const Value.absent(),
    this.explanation = const Value.absent(),
    this.rulesVersion = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArticlesCompanion.insert({
    required String id,
    required String sourceId,
    required String canonicalUrl,
    required String title,
    required String excerpt,
    required DateTime publishedAt,
    required DateTime fetchedAt,
    required String language,
    required List<String> regions,
    required List<String> topics,
    this.storyTypes = const Value.absent(),
    this.evidenceSignals = const Value.absent(),
    this.constructiveScore = const Value.absent(),
    this.route = const Value.absent(),
    this.explanation = const Value.absent(),
    this.rulesVersion = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       canonicalUrl = Value(canonicalUrl),
       title = Value(title),
       excerpt = Value(excerpt),
       publishedAt = Value(publishedAt),
       fetchedAt = Value(fetchedAt),
       language = Value(language),
       regions = Value(regions),
       topics = Value(topics);
  static Insertable<ArticleRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? canonicalUrl,
    Expression<String>? title,
    Expression<String>? excerpt,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? fetchedAt,
    Expression<String>? language,
    Expression<String>? regions,
    Expression<String>? topics,
    Expression<String>? storyTypes,
    Expression<String>? evidenceSignals,
    Expression<double>? constructiveScore,
    Expression<String>? route,
    Expression<String>? explanation,
    Expression<String>? rulesVersion,
    Expression<String>? clusterId,
    Expression<bool>? hidden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (canonicalUrl != null) 'canonical_url': canonicalUrl,
      if (title != null) 'title': title,
      if (excerpt != null) 'excerpt': excerpt,
      if (publishedAt != null) 'published_at': publishedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (language != null) 'language': language,
      if (regions != null) 'regions': regions,
      if (topics != null) 'topics': topics,
      if (storyTypes != null) 'story_types': storyTypes,
      if (evidenceSignals != null) 'evidence_signals': evidenceSignals,
      if (constructiveScore != null) 'constructive_score': constructiveScore,
      if (route != null) 'route': route,
      if (explanation != null) 'explanation': explanation,
      if (rulesVersion != null) 'rules_version': rulesVersion,
      if (clusterId != null) 'cluster_id': clusterId,
      if (hidden != null) 'hidden': hidden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArticlesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String>? canonicalUrl,
    Value<String>? title,
    Value<String>? excerpt,
    Value<DateTime>? publishedAt,
    Value<DateTime>? fetchedAt,
    Value<String>? language,
    Value<List<String>>? regions,
    Value<List<String>>? topics,
    Value<List<String>>? storyTypes,
    Value<List<String>>? evidenceSignals,
    Value<double?>? constructiveScore,
    Value<String?>? route,
    Value<String?>? explanation,
    Value<String?>? rulesVersion,
    Value<String?>? clusterId,
    Value<bool>? hidden,
    Value<int>? rowid,
  }) {
    return ArticlesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      publishedAt: publishedAt ?? this.publishedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      language: language ?? this.language,
      regions: regions ?? this.regions,
      topics: topics ?? this.topics,
      storyTypes: storyTypes ?? this.storyTypes,
      evidenceSignals: evidenceSignals ?? this.evidenceSignals,
      constructiveScore: constructiveScore ?? this.constructiveScore,
      route: route ?? this.route,
      explanation: explanation ?? this.explanation,
      rulesVersion: rulesVersion ?? this.rulesVersion,
      clusterId: clusterId ?? this.clusterId,
      hidden: hidden ?? this.hidden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (canonicalUrl.present) {
      map['canonical_url'] = Variable<String>(canonicalUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (excerpt.present) {
      map['excerpt'] = Variable<String>(excerpt.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (regions.present) {
      map['regions'] = Variable<String>(
        $ArticlesTable.$converterregions.toSql(regions.value),
      );
    }
    if (topics.present) {
      map['topics'] = Variable<String>(
        $ArticlesTable.$convertertopics.toSql(topics.value),
      );
    }
    if (storyTypes.present) {
      map['story_types'] = Variable<String>(
        $ArticlesTable.$converterstoryTypes.toSql(storyTypes.value),
      );
    }
    if (evidenceSignals.present) {
      map['evidence_signals'] = Variable<String>(
        $ArticlesTable.$converterevidenceSignals.toSql(evidenceSignals.value),
      );
    }
    if (constructiveScore.present) {
      map['constructive_score'] = Variable<double>(constructiveScore.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (rulesVersion.present) {
      map['rules_version'] = Variable<String>(rulesVersion.value);
    }
    if (clusterId.present) {
      map['cluster_id'] = Variable<String>(clusterId.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticlesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('canonicalUrl: $canonicalUrl, ')
          ..write('title: $title, ')
          ..write('excerpt: $excerpt, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('language: $language, ')
          ..write('regions: $regions, ')
          ..write('topics: $topics, ')
          ..write('storyTypes: $storyTypes, ')
          ..write('evidenceSignals: $evidenceSignals, ')
          ..write('constructiveScore: $constructiveScore, ')
          ..write('route: $route, ')
          ..write('explanation: $explanation, ')
          ..write('rulesVersion: $rulesVersion, ')
          ..write('clusterId: $clusterId, ')
          ..write('hidden: $hidden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyPicksTable extends DailyPicks
    with TableInfo<$DailyPicksTable, DailyPickRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPicksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES articles (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [day, position, articleId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_picks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPickRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, position};
  @override
  DailyPickRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPickRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      articleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_id'],
      )!,
    );
  }

  @override
  $DailyPicksTable createAlias(String alias) {
    return $DailyPicksTable(attachedDatabase, alias);
  }
}

class DailyPickRow extends DataClass implements Insertable<DailyPickRow> {
  /// Local date, `yyyy-MM-dd`.
  final String day;
  final int position;
  final String articleId;
  const DailyPickRow({
    required this.day,
    required this.position,
    required this.articleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['position'] = Variable<int>(position);
    map['article_id'] = Variable<String>(articleId);
    return map;
  }

  DailyPicksCompanion toCompanion(bool nullToAbsent) {
    return DailyPicksCompanion(
      day: Value(day),
      position: Value(position),
      articleId: Value(articleId),
    );
  }

  factory DailyPickRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPickRow(
      day: serializer.fromJson<String>(json['day']),
      position: serializer.fromJson<int>(json['position']),
      articleId: serializer.fromJson<String>(json['articleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'position': serializer.toJson<int>(position),
      'articleId': serializer.toJson<String>(articleId),
    };
  }

  DailyPickRow copyWith({String? day, int? position, String? articleId}) =>
      DailyPickRow(
        day: day ?? this.day,
        position: position ?? this.position,
        articleId: articleId ?? this.articleId,
      );
  DailyPickRow copyWithCompanion(DailyPicksCompanion data) {
    return DailyPickRow(
      day: data.day.present ? data.day.value : this.day,
      position: data.position.present ? data.position.value : this.position,
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPickRow(')
          ..write('day: $day, ')
          ..write('position: $position, ')
          ..write('articleId: $articleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, position, articleId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPickRow &&
          other.day == this.day &&
          other.position == this.position &&
          other.articleId == this.articleId);
}

class DailyPicksCompanion extends UpdateCompanion<DailyPickRow> {
  final Value<String> day;
  final Value<int> position;
  final Value<String> articleId;
  final Value<int> rowid;
  const DailyPicksCompanion({
    this.day = const Value.absent(),
    this.position = const Value.absent(),
    this.articleId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPicksCompanion.insert({
    required String day,
    required int position,
    required String articleId,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       position = Value(position),
       articleId = Value(articleId);
  static Insertable<DailyPickRow> custom({
    Expression<String>? day,
    Expression<int>? position,
    Expression<String>? articleId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (position != null) 'position': position,
      if (articleId != null) 'article_id': articleId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPicksCompanion copyWith({
    Value<String>? day,
    Value<int>? position,
    Value<String>? articleId,
    Value<int>? rowid,
  }) {
    return DailyPicksCompanion(
      day: day ?? this.day,
      position: position ?? this.position,
      articleId: articleId ?? this.articleId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPicksCompanion(')
          ..write('day: $day, ')
          ..write('position: $position, ')
          ..write('articleId: $articleId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeenTable extends Seen with TableInfo<$SeenTable, SeenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES articles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<DateTime> seenAt = GeneratedColumn<DateTime>(
    'seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [articleId, seenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seen';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeenRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_seenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {articleId};
  @override
  SeenRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeenRow(
      articleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_id'],
      )!,
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}seen_at'],
      )!,
    );
  }

  @override
  $SeenTable createAlias(String alias) {
    return $SeenTable(attachedDatabase, alias);
  }
}

class SeenRow extends DataClass implements Insertable<SeenRow> {
  final String articleId;
  final DateTime seenAt;
  const SeenRow({required this.articleId, required this.seenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['article_id'] = Variable<String>(articleId);
    map['seen_at'] = Variable<DateTime>(seenAt);
    return map;
  }

  SeenCompanion toCompanion(bool nullToAbsent) {
    return SeenCompanion(articleId: Value(articleId), seenAt: Value(seenAt));
  }

  factory SeenRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeenRow(
      articleId: serializer.fromJson<String>(json['articleId']),
      seenAt: serializer.fromJson<DateTime>(json['seenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'articleId': serializer.toJson<String>(articleId),
      'seenAt': serializer.toJson<DateTime>(seenAt),
    };
  }

  SeenRow copyWith({String? articleId, DateTime? seenAt}) => SeenRow(
    articleId: articleId ?? this.articleId,
    seenAt: seenAt ?? this.seenAt,
  );
  SeenRow copyWithCompanion(SeenCompanion data) {
    return SeenRow(
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeenRow(')
          ..write('articleId: $articleId, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(articleId, seenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeenRow &&
          other.articleId == this.articleId &&
          other.seenAt == this.seenAt);
}

class SeenCompanion extends UpdateCompanion<SeenRow> {
  final Value<String> articleId;
  final Value<DateTime> seenAt;
  final Value<int> rowid;
  const SeenCompanion({
    this.articleId = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeenCompanion.insert({
    required String articleId,
    required DateTime seenAt,
    this.rowid = const Value.absent(),
  }) : articleId = Value(articleId),
       seenAt = Value(seenAt);
  static Insertable<SeenRow> custom({
    Expression<String>? articleId,
    Expression<DateTime>? seenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (articleId != null) 'article_id': articleId,
      if (seenAt != null) 'seen_at': seenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeenCompanion copyWith({
    Value<String>? articleId,
    Value<DateTime>? seenAt,
    Value<int>? rowid,
  }) {
    return SeenCompanion(
      articleId: articleId ?? this.articleId,
      seenAt: seenAt ?? this.seenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<DateTime>(seenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeenCompanion(')
          ..write('articleId: $articleId, ')
          ..write('seenAt: $seenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferenceEntriesTable extends PreferenceEntries
    with TableInfo<$PreferenceEntriesTable, PreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferenceEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferenceEntriesTable createAlias(String alias) {
    return $PreferenceEntriesTable(attachedDatabase, alias);
  }
}

class PreferenceRow extends DataClass implements Insertable<PreferenceRow> {
  final String key;
  final String value;
  const PreferenceRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferenceEntriesCompanion toCompanion(bool nullToAbsent) {
    return PreferenceEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory PreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  PreferenceRow copyWith({String? key, String? value}) =>
      PreferenceRow(key: key ?? this.key, value: value ?? this.value);
  PreferenceRow copyWithCompanion(PreferenceEntriesCompanion data) {
    return PreferenceRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceRow &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferenceEntriesCompanion extends UpdateCompanion<PreferenceRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferenceEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferenceEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<PreferenceRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferenceEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferenceEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [articleId, savedAt, snapshot];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {articleId};
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      articleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_id'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final String articleId;
  final DateTime savedAt;

  /// JSON object, see `StorySnapshot`.
  final String snapshot;
  const BookmarkRow({
    required this.articleId,
    required this.savedAt,
    required this.snapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['article_id'] = Variable<String>(articleId);
    map['saved_at'] = Variable<DateTime>(savedAt);
    map['snapshot'] = Variable<String>(snapshot);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      articleId: Value(articleId),
      savedAt: Value(savedAt),
      snapshot: Value(snapshot),
    );
  }

  factory BookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      articleId: serializer.fromJson<String>(json['articleId']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'articleId': serializer.toJson<String>(articleId),
      'savedAt': serializer.toJson<DateTime>(savedAt),
      'snapshot': serializer.toJson<String>(snapshot),
    };
  }

  BookmarkRow copyWith({
    String? articleId,
    DateTime? savedAt,
    String? snapshot,
  }) => BookmarkRow(
    articleId: articleId ?? this.articleId,
    savedAt: savedAt ?? this.savedAt,
    snapshot: snapshot ?? this.snapshot,
  );
  BookmarkRow copyWithCompanion(BookmarksCompanion data) {
    return BookmarkRow(
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('articleId: $articleId, ')
          ..write('savedAt: $savedAt, ')
          ..write('snapshot: $snapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(articleId, savedAt, snapshot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.articleId == this.articleId &&
          other.savedAt == this.savedAt &&
          other.snapshot == this.snapshot);
}

class BookmarksCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<String> articleId;
  final Value<DateTime> savedAt;
  final Value<String> snapshot;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.articleId = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String articleId,
    required DateTime savedAt,
    required String snapshot,
    this.rowid = const Value.absent(),
  }) : articleId = Value(articleId),
       savedAt = Value(savedAt),
       snapshot = Value(snapshot);
  static Insertable<BookmarkRow> custom({
    Expression<String>? articleId,
    Expression<DateTime>? savedAt,
    Expression<String>? snapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (articleId != null) 'article_id': articleId,
      if (savedAt != null) 'saved_at': savedAt,
      if (snapshot != null) 'snapshot': snapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? articleId,
    Value<DateTime>? savedAt,
    Value<String>? snapshot,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      articleId: articleId ?? this.articleId,
      savedAt: savedAt ?? this.savedAt,
      snapshot: snapshot ?? this.snapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('articleId: $articleId, ')
          ..write('savedAt: $savedAt, ')
          ..write('snapshot: $snapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $ArticlesTable articles = $ArticlesTable(this);
  late final $DailyPicksTable dailyPicks = $DailyPicksTable(this);
  late final $SeenTable seen = $SeenTable(this);
  late final $PreferenceEntriesTable preferenceEntries =
      $PreferenceEntriesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final Index articlesRoutePublished = Index(
    'articles_route_published',
    'CREATE INDEX articles_route_published ON articles (route, published_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    articles,
    dailyPicks,
    seen,
    preferenceEntries,
    bookmarks,
    articlesRoutePublished,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'articles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('daily_picks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'articles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('seen', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SourcesTableCreateCompanionBuilder = SourcesCompanion Function({
  required String id,
  required String name,
  required String homepageUrl,
  required String rssUrl,
  required int tier,
  required double trustScore,
  required String language,
  required List<String> regions,
  Value<bool> userEnabled,
  Value<String> etag,
  Value<String> lastModified,
  Value<DateTime?> lastFetchedAt,
  Value<String?> lastStatus,
  Value<int> consecutiveFailures,
  Value<DateTime?> backoffUntil,
  Value<int> rowid,
});
typedef $$SourcesTableUpdateCompanionBuilder = SourcesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> homepageUrl,
  Value<String> rssUrl,
  Value<int> tier,
  Value<double> trustScore,
  Value<String> language,
  Value<List<String>> regions,
  Value<bool> userEnabled,
  Value<String> etag,
  Value<String> lastModified,
  Value<DateTime?> lastFetchedAt,
  Value<String?> lastStatus,
  Value<int> consecutiveFailures,
  Value<DateTime?> backoffUntil,
  Value<int> rowid,
});

final class $$SourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTable, SourceRow> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ArticlesTable, List<ArticleRow>>
  _articlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.articles,
    aliasName: 'sources__id__articles__source_id',
  );

  $$ArticlesTableProcessedTableManager get articlesRefs {
    final manager = $$ArticlesTableTableManager(
      $_db,
      $_db.articles,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_articlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homepageUrl => $composableBuilder(
    column: $table.homepageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rssUrl => $composableBuilder(
    column: $table.rssUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get trustScore => $composableBuilder(
    column: $table.trustScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get regions => $composableBuilder(
    column: $table.regions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get userEnabled => $composableBuilder(
    column: $table.userEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastStatus => $composableBuilder(
    column: $table.lastStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get backoffUntil => $composableBuilder(
    column: $table.backoffUntil,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> articlesRefs(
    Expression<bool> Function($$ArticlesTableFilterComposer f) f,
  ) {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableFilterComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homepageUrl => $composableBuilder(
    column: $table.homepageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rssUrl => $composableBuilder(
    column: $table.rssUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get trustScore => $composableBuilder(
    column: $table.trustScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regions => $composableBuilder(
    column: $table.regions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userEnabled => $composableBuilder(
    column: $table.userEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastStatus => $composableBuilder(
    column: $table.lastStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get backoffUntil => $composableBuilder(
    column: $table.backoffUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get homepageUrl => $composableBuilder(
    column: $table.homepageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rssUrl =>
      $composableBuilder(column: $table.rssUrl, builder: (column) => column);

  GeneratedColumn<int> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<double> get trustScore => $composableBuilder(
    column: $table.trustScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get regions =>
      $composableBuilder(column: $table.regions, builder: (column) => column);

  GeneratedColumn<bool> get userEnabled => $composableBuilder(
    column: $table.userEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastStatus => $composableBuilder(
    column: $table.lastStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get backoffUntil => $composableBuilder(
    column: $table.backoffUntil,
    builder: (column) => column,
  );

  Expression<T> articlesRefs<T extends Object>(
    Expression<T> Function($$ArticlesTableAnnotationComposer a) f,
  ) {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableAnnotationComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          SourceRow,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (SourceRow, $$SourcesTableReferences),
          SourceRow,
          PrefetchHooks Function({bool articlesRefs})
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> homepageUrl = const Value.absent(),
                Value<String> rssUrl = const Value.absent(),
                Value<int> tier = const Value.absent(),
                Value<double> trustScore = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<List<String>> regions = const Value.absent(),
                Value<bool> userEnabled = const Value.absent(),
                Value<String> etag = const Value.absent(),
                Value<String> lastModified = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastStatus = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                Value<DateTime?> backoffUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                homepageUrl: homepageUrl,
                rssUrl: rssUrl,
                tier: tier,
                trustScore: trustScore,
                language: language,
                regions: regions,
                userEnabled: userEnabled,
                etag: etag,
                lastModified: lastModified,
                lastFetchedAt: lastFetchedAt,
                lastStatus: lastStatus,
                consecutiveFailures: consecutiveFailures,
                backoffUntil: backoffUntil,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String homepageUrl,
                required String rssUrl,
                required int tier,
                required double trustScore,
                required String language,
                required List<String> regions,
                Value<bool> userEnabled = const Value.absent(),
                Value<String> etag = const Value.absent(),
                Value<String> lastModified = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastStatus = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                Value<DateTime?> backoffUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                homepageUrl: homepageUrl,
                rssUrl: rssUrl,
                tier: tier,
                trustScore: trustScore,
                language: language,
                regions: regions,
                userEnabled: userEnabled,
                etag: etag,
                lastModified: lastModified,
                lastFetchedAt: lastFetchedAt,
                lastStatus: lastStatus,
                consecutiveFailures: consecutiveFailures,
                backoffUntil: backoffUntil,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcesTable, SourceRow>(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({articlesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (articlesRefs) db.articles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (articlesRefs)
                    await $_getPrefetchedDataByColumns<
                      SourceRow,
                      $SourcesTable,
                      ArticleRow,
                      $ArticlesTable
                    >(
                      currentTable: table,
                      referencedTable: $$SourcesTableReferences
                          ._articlesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SourcesTableReferences(db, table, p0).articlesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'source_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      SourceRow,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (SourceRow, $$SourcesTableReferences),
      SourceRow,
      PrefetchHooks Function({bool articlesRefs})
    >;
typedef $$ArticlesTableCreateCompanionBuilder = ArticlesCompanion Function({
  required String id,
  required String sourceId,
  required String canonicalUrl,
  required String title,
  required String excerpt,
  required DateTime publishedAt,
  required DateTime fetchedAt,
  required String language,
  required List<String> regions,
  required List<String> topics,
  Value<List<String>> storyTypes,
  Value<List<String>> evidenceSignals,
  Value<double?> constructiveScore,
  Value<String?> route,
  Value<String?> explanation,
  Value<String?> rulesVersion,
  Value<String?> clusterId,
  Value<bool> hidden,
  Value<int> rowid,
});
typedef $$ArticlesTableUpdateCompanionBuilder = ArticlesCompanion Function({
  Value<String> id,
  Value<String> sourceId,
  Value<String> canonicalUrl,
  Value<String> title,
  Value<String> excerpt,
  Value<DateTime> publishedAt,
  Value<DateTime> fetchedAt,
  Value<String> language,
  Value<List<String>> regions,
  Value<List<String>> topics,
  Value<List<String>> storyTypes,
  Value<List<String>> evidenceSignals,
  Value<double?> constructiveScore,
  Value<String?> route,
  Value<String?> explanation,
  Value<String?> rulesVersion,
  Value<String?> clusterId,
  Value<bool> hidden,
  Value<int> rowid,
});

final class $$ArticlesTableReferences
    extends BaseReferences<_$AppDatabase, $ArticlesTable, ArticleRow> {
  $$ArticlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias('articles__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DailyPicksTable, List<DailyPickRow>>
  _dailyPicksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dailyPicks,
    aliasName: 'articles__id__daily_picks__article_id',
  );

  $$DailyPicksTableProcessedTableManager get dailyPicksRefs {
    final manager = $$DailyPicksTableTableManager(
      $_db,
      $_db.dailyPicks,
    ).filter((f) => f.articleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyPicksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeenTable, List<SeenRow>> _seenRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.seen,
    aliasName: 'articles__id__seen__article_id',
  );

  $$SeenTableProcessedTableManager get seenRefs {
    final manager = $$SeenTableTableManager(
      $_db,
      $_db.seen,
    ).filter((f) => f.articleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_seenRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get regions => $composableBuilder(
    column: $table.regions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get topics => $composableBuilder(
    column: $table.topics,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get storyTypes => $composableBuilder(
    column: $table.storyTypes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get evidenceSignals => $composableBuilder(
    column: $table.evidenceSignals,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get constructiveScore => $composableBuilder(
    column: $table.constructiveScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rulesVersion => $composableBuilder(
    column: $table.rulesVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> dailyPicksRefs(
    Expression<bool> Function($$DailyPicksTableFilterComposer f) f,
  ) {
    final $$DailyPicksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyPicks,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyPicksTableFilterComposer(
            $db: $db,
            $table: $db.dailyPicks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seenRefs(
    Expression<bool> Function($$SeenTableFilterComposer f) f,
  ) {
    final $$SeenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seen,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeenTableFilterComposer(
            $db: $db,
            $table: $db.seen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regions => $composableBuilder(
    column: $table.regions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topics => $composableBuilder(
    column: $table.topics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storyTypes => $composableBuilder(
    column: $table.storyTypes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceSignals => $composableBuilder(
    column: $table.evidenceSignals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get constructiveScore => $composableBuilder(
    column: $table.constructiveScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rulesVersion => $composableBuilder(
    column: $table.rulesVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get excerpt =>
      $composableBuilder(column: $table.excerpt, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get regions =>
      $composableBuilder(column: $table.regions, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get topics =>
      $composableBuilder(column: $table.topics, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get storyTypes =>
      $composableBuilder(
        column: $table.storyTypes,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get evidenceSignals =>
      $composableBuilder(
        column: $table.evidenceSignals,
        builder: (column) => column,
      );

  GeneratedColumn<double> get constructiveScore => $composableBuilder(
    column: $table.constructiveScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rulesVersion => $composableBuilder(
    column: $table.rulesVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clusterId =>
      $composableBuilder(column: $table.clusterId, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> dailyPicksRefs<T extends Object>(
    Expression<T> Function($$DailyPicksTableAnnotationComposer a) f,
  ) {
    final $$DailyPicksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyPicks,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyPicksTableAnnotationComposer(
            $db: $db,
            $table: $db.dailyPicks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seenRefs<T extends Object>(
    Expression<T> Function($$SeenTableAnnotationComposer a) f,
  ) {
    final $$SeenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seen,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeenTableAnnotationComposer(
            $db: $db,
            $table: $db.seen,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticlesTable,
          ArticleRow,
          $$ArticlesTableFilterComposer,
          $$ArticlesTableOrderingComposer,
          $$ArticlesTableAnnotationComposer,
          $$ArticlesTableCreateCompanionBuilder,
          $$ArticlesTableUpdateCompanionBuilder,
          (ArticleRow, $$ArticlesTableReferences),
          ArticleRow,
          PrefetchHooks Function({
            bool sourceId,
            bool dailyPicksRefs,
            bool seenRefs,
          })
        > {
  $$ArticlesTableTableManager(_$AppDatabase db, $ArticlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> canonicalUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> excerpt = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<List<String>> regions = const Value.absent(),
                Value<List<String>> topics = const Value.absent(),
                Value<List<String>> storyTypes = const Value.absent(),
                Value<List<String>> evidenceSignals = const Value.absent(),
                Value<double?> constructiveScore = const Value.absent(),
                Value<String?> route = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<String?> rulesVersion = const Value.absent(),
                Value<String?> clusterId = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticlesCompanion(
                id: id,
                sourceId: sourceId,
                canonicalUrl: canonicalUrl,
                title: title,
                excerpt: excerpt,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                language: language,
                regions: regions,
                topics: topics,
                storyTypes: storyTypes,
                evidenceSignals: evidenceSignals,
                constructiveScore: constructiveScore,
                route: route,
                explanation: explanation,
                rulesVersion: rulesVersion,
                clusterId: clusterId,
                hidden: hidden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required String canonicalUrl,
                required String title,
                required String excerpt,
                required DateTime publishedAt,
                required DateTime fetchedAt,
                required String language,
                required List<String> regions,
                required List<String> topics,
                Value<List<String>> storyTypes = const Value.absent(),
                Value<List<String>> evidenceSignals = const Value.absent(),
                Value<double?> constructiveScore = const Value.absent(),
                Value<String?> route = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<String?> rulesVersion = const Value.absent(),
                Value<String?> clusterId = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticlesCompanion.insert(
                id: id,
                sourceId: sourceId,
                canonicalUrl: canonicalUrl,
                title: title,
                excerpt: excerpt,
                publishedAt: publishedAt,
                fetchedAt: fetchedAt,
                language: language,
                regions: regions,
                topics: topics,
                storyTypes: storyTypes,
                evidenceSignals: evidenceSignals,
                constructiveScore: constructiveScore,
                route: route,
                explanation: explanation,
                rulesVersion: rulesVersion,
                clusterId: clusterId,
                hidden: hidden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArticlesTable, ArticleRow>(table),
                  $$ArticlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceId = false, dailyPicksRefs = false, seenRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dailyPicksRefs) db.dailyPicks,
                    if (seenRefs) db.seen,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: $$ArticlesTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: $$ArticlesTableReferences
                                ._sourceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dailyPicksRefs)
                        await $_getPrefetchedDataByColumns<
                          ArticleRow,
                          $ArticlesTable,
                          DailyPickRow,
                          $DailyPicksTable
                        >(
                          currentTable: table,
                          referencedTable: $$ArticlesTableReferences
                              ._dailyPicksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArticlesTableReferences(
                                db,
                                table,
                                p0,
                              ).dailyPicksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'article_id',
                          typedResults: items,
                        ),
                      if (seenRefs)
                        await $_getPrefetchedDataByColumns<
                          ArticleRow,
                          $ArticlesTable,
                          SeenRow,
                          $SeenTable
                        >(
                          currentTable: table,
                          referencedTable: $$ArticlesTableReferences
                              ._seenRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArticlesTableReferences(db, table, p0).seenRefs,
                          currentColumn: 'id',
                          referencedColumn: 'article_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticlesTable,
      ArticleRow,
      $$ArticlesTableFilterComposer,
      $$ArticlesTableOrderingComposer,
      $$ArticlesTableAnnotationComposer,
      $$ArticlesTableCreateCompanionBuilder,
      $$ArticlesTableUpdateCompanionBuilder,
      (ArticleRow, $$ArticlesTableReferences),
      ArticleRow,
      PrefetchHooks Function({
        bool sourceId,
        bool dailyPicksRefs,
        bool seenRefs,
      })
    >;
typedef $$DailyPicksTableCreateCompanionBuilder = DailyPicksCompanion Function({
  required String day,
  required int position,
  required String articleId,
  Value<int> rowid,
});
typedef $$DailyPicksTableUpdateCompanionBuilder = DailyPicksCompanion Function({
  Value<String> day,
  Value<int> position,
  Value<String> articleId,
  Value<int> rowid,
});

final class $$DailyPicksTableReferences
    extends BaseReferences<_$AppDatabase, $DailyPicksTable, DailyPickRow> {
  $$DailyPicksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArticlesTable _articleIdTable(_$AppDatabase db) =>
      db.articles.createAlias('daily_picks__article_id__articles__id');

  $$ArticlesTableProcessedTableManager get articleId {
    final $_column = $_itemColumn<String>('article_id')!;

    final manager = $$ArticlesTableTableManager(
      $_db,
      $_db.articles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_articleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyPicksTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPicksTable> {
  $$DailyPicksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ArticlesTableFilterComposer get articleId {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableFilterComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPicksTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPicksTable> {
  $$DailyPicksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArticlesTableOrderingComposer get articleId {
    final $$ArticlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableOrderingComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPicksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPicksTable> {
  $$DailyPicksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ArticlesTableAnnotationComposer get articleId {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableAnnotationComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPicksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPicksTable,
          DailyPickRow,
          $$DailyPicksTableFilterComposer,
          $$DailyPicksTableOrderingComposer,
          $$DailyPicksTableAnnotationComposer,
          $$DailyPicksTableCreateCompanionBuilder,
          $$DailyPicksTableUpdateCompanionBuilder,
          (DailyPickRow, $$DailyPicksTableReferences),
          DailyPickRow,
          PrefetchHooks Function({bool articleId})
        > {
  $$DailyPicksTableTableManager(_$AppDatabase db, $DailyPicksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPicksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPicksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPicksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> articleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPicksCompanion(
                day: day,
                position: position,
                articleId: articleId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required int position,
                required String articleId,
                Value<int> rowid = const Value.absent(),
              }) => DailyPicksCompanion.insert(
                day: day,
                position: position,
                articleId: articleId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyPicksTable, DailyPickRow>(table),
                  $$DailyPicksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({articleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (articleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.articleId,
                        referencedTable: $$DailyPicksTableReferences
                            ._articleIdTable(db),
                        referencedColumn: $$DailyPicksTableReferences
                            ._articleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DailyPicksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPicksTable,
      DailyPickRow,
      $$DailyPicksTableFilterComposer,
      $$DailyPicksTableOrderingComposer,
      $$DailyPicksTableAnnotationComposer,
      $$DailyPicksTableCreateCompanionBuilder,
      $$DailyPicksTableUpdateCompanionBuilder,
      (DailyPickRow, $$DailyPicksTableReferences),
      DailyPickRow,
      PrefetchHooks Function({bool articleId})
    >;
typedef $$SeenTableCreateCompanionBuilder = SeenCompanion Function({
  required String articleId,
  required DateTime seenAt,
  Value<int> rowid,
});
typedef $$SeenTableUpdateCompanionBuilder = SeenCompanion Function({
  Value<String> articleId,
  Value<DateTime> seenAt,
  Value<int> rowid,
});

final class $$SeenTableReferences
    extends BaseReferences<_$AppDatabase, $SeenTable, SeenRow> {
  $$SeenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArticlesTable _articleIdTable(_$AppDatabase db) =>
      db.articles.createAlias('seen__article_id__articles__id');

  $$ArticlesTableProcessedTableManager get articleId {
    final $_column = $_itemColumn<String>('article_id')!;

    final manager = $$ArticlesTableTableManager(
      $_db,
      $_db.articles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_articleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeenTableFilterComposer extends Composer<_$AppDatabase, $SeenTable> {
  $$SeenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ArticlesTableFilterComposer get articleId {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableFilterComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeenTableOrderingComposer extends Composer<_$AppDatabase, $SeenTable> {
  $$SeenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArticlesTableOrderingComposer get articleId {
    final $$ArticlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableOrderingComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeenTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeenTable> {
  $$SeenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);

  $$ArticlesTableAnnotationComposer get articleId {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableAnnotationComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeenTable,
          SeenRow,
          $$SeenTableFilterComposer,
          $$SeenTableOrderingComposer,
          $$SeenTableAnnotationComposer,
          $$SeenTableCreateCompanionBuilder,
          $$SeenTableUpdateCompanionBuilder,
          (SeenRow, $$SeenTableReferences),
          SeenRow,
          PrefetchHooks Function({bool articleId})
        > {
  $$SeenTableTableManager(_$AppDatabase db, $SeenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> articleId = const Value.absent(),
                Value<DateTime> seenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeenCompanion(
                articleId: articleId,
                seenAt: seenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String articleId,
                required DateTime seenAt,
                Value<int> rowid = const Value.absent(),
              }) => SeenCompanion.insert(
                articleId: articleId,
                seenAt: seenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeenTable, SeenRow>(table),
                  $$SeenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({articleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (articleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.articleId,
                        referencedTable: $$SeenTableReferences._articleIdTable(
                          db,
                        ),
                        referencedColumn: $$SeenTableReferences
                            ._articleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SeenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeenTable,
      SeenRow,
      $$SeenTableFilterComposer,
      $$SeenTableOrderingComposer,
      $$SeenTableAnnotationComposer,
      $$SeenTableCreateCompanionBuilder,
      $$SeenTableUpdateCompanionBuilder,
      (SeenRow, $$SeenTableReferences),
      SeenRow,
      PrefetchHooks Function({bool articleId})
    >;
typedef $$PreferenceEntriesTableCreateCompanionBuilder =
    PreferenceEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferenceEntriesTableUpdateCompanionBuilder =
    PreferenceEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferenceEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferenceEntriesTable> {
  $$PreferenceEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferenceEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferenceEntriesTable> {
  $$PreferenceEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferenceEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferenceEntriesTable> {
  $$PreferenceEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferenceEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferenceEntriesTable,
          PreferenceRow,
          $$PreferenceEntriesTableFilterComposer,
          $$PreferenceEntriesTableOrderingComposer,
          $$PreferenceEntriesTableAnnotationComposer,
          $$PreferenceEntriesTableCreateCompanionBuilder,
          $$PreferenceEntriesTableUpdateCompanionBuilder,
          (
            PreferenceRow,
            BaseReferences<
              _$AppDatabase,
              $PreferenceEntriesTable,
              PreferenceRow
            >,
          ),
          PreferenceRow,
          PrefetchHooks Function()
        > {
  $$PreferenceEntriesTableTableManager(
    _$AppDatabase db,
    $PreferenceEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferenceEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferenceEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferenceEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferenceEntriesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferenceEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferenceEntriesTable, PreferenceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PreferenceEntriesTable,
                    PreferenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferenceEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferenceEntriesTable,
      PreferenceRow,
      $$PreferenceEntriesTableFilterComposer,
      $$PreferenceEntriesTableOrderingComposer,
      $$PreferenceEntriesTableAnnotationComposer,
      $$PreferenceEntriesTableCreateCompanionBuilder,
      $$PreferenceEntriesTableUpdateCompanionBuilder,
      (
        PreferenceRow,
        BaseReferences<_$AppDatabase, $PreferenceEntriesTable, PreferenceRow>,
      ),
      PreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  required String articleId,
  required DateTime savedAt,
  required String snapshot,
  Value<int> rowid,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<String> articleId,
  Value<DateTime> savedAt,
  Value<String> snapshot,
  Value<int> rowid,
});

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get articleId => $composableBuilder(
    column: $table.articleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get articleId =>
      $composableBuilder(column: $table.articleId, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          BookmarkRow,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (
            BookmarkRow,
            BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
          ),
          BookmarkRow,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> articleId = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<String> snapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                articleId: articleId,
                savedAt: savedAt,
                snapshot: snapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String articleId,
                required DateTime savedAt,
                required String snapshot,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                articleId: articleId,
                savedAt: savedAt,
                snapshot: snapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, BookmarkRow>(table),
                  BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      BookmarkRow,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (
        BookmarkRow,
        BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
      ),
      BookmarkRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$ArticlesTableTableManager get articles =>
      $$ArticlesTableTableManager(_db, _db.articles);
  $$DailyPicksTableTableManager get dailyPicks =>
      $$DailyPicksTableTableManager(_db, _db.dailyPicks);
  $$SeenTableTableManager get seen => $$SeenTableTableManager(_db, _db.seen);
  $$PreferenceEntriesTableTableManager get preferenceEntries =>
      $$PreferenceEntriesTableTableManager(_db, _db.preferenceEntries);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
}
