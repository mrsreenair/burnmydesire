// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _imageFileMeta = const VerificationMeta(
    'imageFile',
  );
  @override
  late final GeneratedColumn<String> imageFile = GeneratedColumn<String>(
    'image_file',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceCentsMeta = const VerificationMeta(
    'priceCents',
  );
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
    'price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('purchase'),
  );
  static const VerificationMeta _monthlyCentsMeta = const VerificationMeta(
    'monthlyCents',
  );
  @override
  late final GeneratedColumn<int> monthlyCents = GeneratedColumn<int>(
    'monthly_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthsMeta = const VerificationMeta('months');
  @override
  late final GeneratedColumn<int> months = GeneratedColumn<int>(
    'months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resistanceCountMeta = const VerificationMeta(
    'resistanceCount',
  );
  @override
  late final GeneratedColumn<int> resistanceCount = GeneratedColumn<int>(
    'resistance_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastBurnedAtMeta = const VerificationMeta(
    'lastBurnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastBurnedAt = GeneratedColumn<DateTime>(
    'last_burned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destroyedAtMeta = const VerificationMeta(
    'destroyedAt',
  );
  @override
  late final GeneratedColumn<DateTime> destroyedAt = GeneratedColumn<DateTime>(
    'destroyed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movedAtMeta = const VerificationMeta(
    'movedAt',
  );
  @override
  late final GeneratedColumn<DateTime> movedAt = GeneratedColumn<DateTime>(
    'moved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boughtAtMeta = const VerificationMeta(
    'boughtAt',
  );
  @override
  late final GeneratedColumn<DateTime> boughtAt = GeneratedColumn<DateTime>(
    'bought_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parkedUntilMeta = const VerificationMeta(
    'parkedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> parkedUntil = GeneratedColumn<DateTime>(
    'parked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followUpAtMeta = const VerificationMeta(
    'followUpAt',
  );
  @override
  late final GeneratedColumn<DateTime> followUpAt = GeneratedColumn<DateTime>(
    'follow_up_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reflectionJsonMeta = const VerificationMeta(
    'reflectionJson',
  );
  @override
  late final GeneratedColumn<String> reflectionJson = GeneratedColumn<String>(
    'reflection_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imageFile,
    priceCents,
    category,
    monthlyCents,
    months,
    resistanceCount,
    createdAt,
    lastBurnedAt,
    destroyedAt,
    movedAt,
    boughtAt,
    parkedUntil,
    followUpAt,
    reflectionJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('image_file')) {
      context.handle(
        _imageFileMeta,
        imageFile.isAcceptableOrUnknown(data['image_file']!, _imageFileMeta),
      );
    } else if (isInserting) {
      context.missing(_imageFileMeta);
    }
    if (data.containsKey('price_cents')) {
      context.handle(
        _priceCentsMeta,
        priceCents.isAcceptableOrUnknown(data['price_cents']!, _priceCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_priceCentsMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('monthly_cents')) {
      context.handle(
        _monthlyCentsMeta,
        monthlyCents.isAcceptableOrUnknown(
          data['monthly_cents']!,
          _monthlyCentsMeta,
        ),
      );
    }
    if (data.containsKey('months')) {
      context.handle(
        _monthsMeta,
        months.isAcceptableOrUnknown(data['months']!, _monthsMeta),
      );
    }
    if (data.containsKey('resistance_count')) {
      context.handle(
        _resistanceCountMeta,
        resistanceCount.isAcceptableOrUnknown(
          data['resistance_count']!,
          _resistanceCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_burned_at')) {
      context.handle(
        _lastBurnedAtMeta,
        lastBurnedAt.isAcceptableOrUnknown(
          data['last_burned_at']!,
          _lastBurnedAtMeta,
        ),
      );
    }
    if (data.containsKey('destroyed_at')) {
      context.handle(
        _destroyedAtMeta,
        destroyedAt.isAcceptableOrUnknown(
          data['destroyed_at']!,
          _destroyedAtMeta,
        ),
      );
    }
    if (data.containsKey('moved_at')) {
      context.handle(
        _movedAtMeta,
        movedAt.isAcceptableOrUnknown(data['moved_at']!, _movedAtMeta),
      );
    }
    if (data.containsKey('bought_at')) {
      context.handle(
        _boughtAtMeta,
        boughtAt.isAcceptableOrUnknown(data['bought_at']!, _boughtAtMeta),
      );
    }
    if (data.containsKey('parked_until')) {
      context.handle(
        _parkedUntilMeta,
        parkedUntil.isAcceptableOrUnknown(
          data['parked_until']!,
          _parkedUntilMeta,
        ),
      );
    }
    if (data.containsKey('follow_up_at')) {
      context.handle(
        _followUpAtMeta,
        followUpAt.isAcceptableOrUnknown(
          data['follow_up_at']!,
          _followUpAtMeta,
        ),
      );
    }
    if (data.containsKey('reflection_json')) {
      context.handle(
        _reflectionJsonMeta,
        reflectionJson.isAcceptableOrUnknown(
          data['reflection_json']!,
          _reflectionJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      imageFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_file'],
      )!,
      priceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_cents'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      monthlyCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_cents'],
      ),
      months: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}months'],
      ),
      resistanceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resistance_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastBurnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_burned_at'],
      ),
      destroyedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}destroyed_at'],
      ),
      movedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}moved_at'],
      ),
      boughtAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bought_at'],
      ),
      parkedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}parked_until'],
      ),
      followUpAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}follow_up_at'],
      ),
      reflectionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reflection_json'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final int id;
  final String imageFile;
  final int priceCents;
  final String category;
  final int? monthlyCents;
  final int? months;
  final int resistanceCount;
  final DateTime createdAt;
  final DateTime? lastBurnedAt;

  /// Set when the item was final-burned. A destroyed item is a tombstone:
  /// the photo is deleted from disk (the craving trigger dies) but the row
  /// survives so "wealth protected" totals stay honest forever.
  final DateTime? destroyedAt;

  /// When the user confirmed they actually moved this money somewhere it
  /// can't be spent. Without this the app's headline number is a claim
  /// nobody's bank balance agrees with: resisting a €150 purchase doesn't
  /// protect €150 if it leaves on something else by Friday. Resisted and
  /// genuinely saved are different facts, so they're stored separately.
  final DateTime? movedAt;

  /// When the user admitted they bought it in the end. The honest
  /// counterweight to a total that otherwise only ever goes up — a burn
  /// isn't a saving until the craving stays dead.
  final DateTime? boughtAt;

  /// "Not now": the desire is parked until this moment, and a
  /// notification brings it back. The 24-hour rule is the best-evidenced
  /// intervention against impulse buying, and the app previously only
  /// offered forever.
  final DateTime? parkedUntil;

  /// When the user last answered a follow-up with "still resisted".
  /// Two questions per burn (3 days, then 14 — GROWTH.md M5); this is
  /// how the second knows the first was answered, and how a re-burn
  /// (which moves [lastBurnedAt] past it) starts the pair again.
  final DateTime? followUpAt;

  /// The purchase-interview answers, as JSON (see data/reflection.dart).
  /// Kept so a re-burn can show the user their own words from last time
  /// — "you said you'd wear it once" lands harder than any message we
  /// could write.
  final String? reflectionJson;
  const Item({
    required this.id,
    required this.imageFile,
    required this.priceCents,
    required this.category,
    this.monthlyCents,
    this.months,
    required this.resistanceCount,
    required this.createdAt,
    this.lastBurnedAt,
    this.destroyedAt,
    this.movedAt,
    this.boughtAt,
    this.parkedUntil,
    this.followUpAt,
    this.reflectionJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['image_file'] = Variable<String>(imageFile);
    map['price_cents'] = Variable<int>(priceCents);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || monthlyCents != null) {
      map['monthly_cents'] = Variable<int>(monthlyCents);
    }
    if (!nullToAbsent || months != null) {
      map['months'] = Variable<int>(months);
    }
    map['resistance_count'] = Variable<int>(resistanceCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastBurnedAt != null) {
      map['last_burned_at'] = Variable<DateTime>(lastBurnedAt);
    }
    if (!nullToAbsent || destroyedAt != null) {
      map['destroyed_at'] = Variable<DateTime>(destroyedAt);
    }
    if (!nullToAbsent || movedAt != null) {
      map['moved_at'] = Variable<DateTime>(movedAt);
    }
    if (!nullToAbsent || boughtAt != null) {
      map['bought_at'] = Variable<DateTime>(boughtAt);
    }
    if (!nullToAbsent || parkedUntil != null) {
      map['parked_until'] = Variable<DateTime>(parkedUntil);
    }
    if (!nullToAbsent || followUpAt != null) {
      map['follow_up_at'] = Variable<DateTime>(followUpAt);
    }
    if (!nullToAbsent || reflectionJson != null) {
      map['reflection_json'] = Variable<String>(reflectionJson);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      imageFile: Value(imageFile),
      priceCents: Value(priceCents),
      category: Value(category),
      monthlyCents: monthlyCents == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyCents),
      months: months == null && nullToAbsent
          ? const Value.absent()
          : Value(months),
      resistanceCount: Value(resistanceCount),
      createdAt: Value(createdAt),
      lastBurnedAt: lastBurnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBurnedAt),
      destroyedAt: destroyedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(destroyedAt),
      movedAt: movedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(movedAt),
      boughtAt: boughtAt == null && nullToAbsent
          ? const Value.absent()
          : Value(boughtAt),
      parkedUntil: parkedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(parkedUntil),
      followUpAt: followUpAt == null && nullToAbsent
          ? const Value.absent()
          : Value(followUpAt),
      reflectionJson: reflectionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reflectionJson),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<int>(json['id']),
      imageFile: serializer.fromJson<String>(json['imageFile']),
      priceCents: serializer.fromJson<int>(json['priceCents']),
      category: serializer.fromJson<String>(json['category']),
      monthlyCents: serializer.fromJson<int?>(json['monthlyCents']),
      months: serializer.fromJson<int?>(json['months']),
      resistanceCount: serializer.fromJson<int>(json['resistanceCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastBurnedAt: serializer.fromJson<DateTime?>(json['lastBurnedAt']),
      destroyedAt: serializer.fromJson<DateTime?>(json['destroyedAt']),
      movedAt: serializer.fromJson<DateTime?>(json['movedAt']),
      boughtAt: serializer.fromJson<DateTime?>(json['boughtAt']),
      parkedUntil: serializer.fromJson<DateTime?>(json['parkedUntil']),
      followUpAt: serializer.fromJson<DateTime?>(json['followUpAt']),
      reflectionJson: serializer.fromJson<String?>(json['reflectionJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'imageFile': serializer.toJson<String>(imageFile),
      'priceCents': serializer.toJson<int>(priceCents),
      'category': serializer.toJson<String>(category),
      'monthlyCents': serializer.toJson<int?>(monthlyCents),
      'months': serializer.toJson<int?>(months),
      'resistanceCount': serializer.toJson<int>(resistanceCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastBurnedAt': serializer.toJson<DateTime?>(lastBurnedAt),
      'destroyedAt': serializer.toJson<DateTime?>(destroyedAt),
      'movedAt': serializer.toJson<DateTime?>(movedAt),
      'boughtAt': serializer.toJson<DateTime?>(boughtAt),
      'parkedUntil': serializer.toJson<DateTime?>(parkedUntil),
      'followUpAt': serializer.toJson<DateTime?>(followUpAt),
      'reflectionJson': serializer.toJson<String?>(reflectionJson),
    };
  }

  Item copyWith({
    int? id,
    String? imageFile,
    int? priceCents,
    String? category,
    Value<int?> monthlyCents = const Value.absent(),
    Value<int?> months = const Value.absent(),
    int? resistanceCount,
    DateTime? createdAt,
    Value<DateTime?> lastBurnedAt = const Value.absent(),
    Value<DateTime?> destroyedAt = const Value.absent(),
    Value<DateTime?> movedAt = const Value.absent(),
    Value<DateTime?> boughtAt = const Value.absent(),
    Value<DateTime?> parkedUntil = const Value.absent(),
    Value<DateTime?> followUpAt = const Value.absent(),
    Value<String?> reflectionJson = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    imageFile: imageFile ?? this.imageFile,
    priceCents: priceCents ?? this.priceCents,
    category: category ?? this.category,
    monthlyCents: monthlyCents.present ? monthlyCents.value : this.monthlyCents,
    months: months.present ? months.value : this.months,
    resistanceCount: resistanceCount ?? this.resistanceCount,
    createdAt: createdAt ?? this.createdAt,
    lastBurnedAt: lastBurnedAt.present ? lastBurnedAt.value : this.lastBurnedAt,
    destroyedAt: destroyedAt.present ? destroyedAt.value : this.destroyedAt,
    movedAt: movedAt.present ? movedAt.value : this.movedAt,
    boughtAt: boughtAt.present ? boughtAt.value : this.boughtAt,
    parkedUntil: parkedUntil.present ? parkedUntil.value : this.parkedUntil,
    followUpAt: followUpAt.present ? followUpAt.value : this.followUpAt,
    reflectionJson: reflectionJson.present
        ? reflectionJson.value
        : this.reflectionJson,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      imageFile: data.imageFile.present ? data.imageFile.value : this.imageFile,
      priceCents: data.priceCents.present
          ? data.priceCents.value
          : this.priceCents,
      category: data.category.present ? data.category.value : this.category,
      monthlyCents: data.monthlyCents.present
          ? data.monthlyCents.value
          : this.monthlyCents,
      months: data.months.present ? data.months.value : this.months,
      resistanceCount: data.resistanceCount.present
          ? data.resistanceCount.value
          : this.resistanceCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastBurnedAt: data.lastBurnedAt.present
          ? data.lastBurnedAt.value
          : this.lastBurnedAt,
      destroyedAt: data.destroyedAt.present
          ? data.destroyedAt.value
          : this.destroyedAt,
      movedAt: data.movedAt.present ? data.movedAt.value : this.movedAt,
      boughtAt: data.boughtAt.present ? data.boughtAt.value : this.boughtAt,
      parkedUntil: data.parkedUntil.present
          ? data.parkedUntil.value
          : this.parkedUntil,
      followUpAt: data.followUpAt.present
          ? data.followUpAt.value
          : this.followUpAt,
      reflectionJson: data.reflectionJson.present
          ? data.reflectionJson.value
          : this.reflectionJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('imageFile: $imageFile, ')
          ..write('priceCents: $priceCents, ')
          ..write('category: $category, ')
          ..write('monthlyCents: $monthlyCents, ')
          ..write('months: $months, ')
          ..write('resistanceCount: $resistanceCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastBurnedAt: $lastBurnedAt, ')
          ..write('destroyedAt: $destroyedAt, ')
          ..write('movedAt: $movedAt, ')
          ..write('boughtAt: $boughtAt, ')
          ..write('parkedUntil: $parkedUntil, ')
          ..write('followUpAt: $followUpAt, ')
          ..write('reflectionJson: $reflectionJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    imageFile,
    priceCents,
    category,
    monthlyCents,
    months,
    resistanceCount,
    createdAt,
    lastBurnedAt,
    destroyedAt,
    movedAt,
    boughtAt,
    parkedUntil,
    followUpAt,
    reflectionJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.imageFile == this.imageFile &&
          other.priceCents == this.priceCents &&
          other.category == this.category &&
          other.monthlyCents == this.monthlyCents &&
          other.months == this.months &&
          other.resistanceCount == this.resistanceCount &&
          other.createdAt == this.createdAt &&
          other.lastBurnedAt == this.lastBurnedAt &&
          other.destroyedAt == this.destroyedAt &&
          other.movedAt == this.movedAt &&
          other.boughtAt == this.boughtAt &&
          other.parkedUntil == this.parkedUntil &&
          other.followUpAt == this.followUpAt &&
          other.reflectionJson == this.reflectionJson);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> id;
  final Value<String> imageFile;
  final Value<int> priceCents;
  final Value<String> category;
  final Value<int?> monthlyCents;
  final Value<int?> months;
  final Value<int> resistanceCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastBurnedAt;
  final Value<DateTime?> destroyedAt;
  final Value<DateTime?> movedAt;
  final Value<DateTime?> boughtAt;
  final Value<DateTime?> parkedUntil;
  final Value<DateTime?> followUpAt;
  final Value<String?> reflectionJson;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.imageFile = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.category = const Value.absent(),
    this.monthlyCents = const Value.absent(),
    this.months = const Value.absent(),
    this.resistanceCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastBurnedAt = const Value.absent(),
    this.destroyedAt = const Value.absent(),
    this.movedAt = const Value.absent(),
    this.boughtAt = const Value.absent(),
    this.parkedUntil = const Value.absent(),
    this.followUpAt = const Value.absent(),
    this.reflectionJson = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    required String imageFile,
    required int priceCents,
    this.category = const Value.absent(),
    this.monthlyCents = const Value.absent(),
    this.months = const Value.absent(),
    this.resistanceCount = const Value.absent(),
    required DateTime createdAt,
    this.lastBurnedAt = const Value.absent(),
    this.destroyedAt = const Value.absent(),
    this.movedAt = const Value.absent(),
    this.boughtAt = const Value.absent(),
    this.parkedUntil = const Value.absent(),
    this.followUpAt = const Value.absent(),
    this.reflectionJson = const Value.absent(),
  }) : imageFile = Value(imageFile),
       priceCents = Value(priceCents),
       createdAt = Value(createdAt);
  static Insertable<Item> custom({
    Expression<int>? id,
    Expression<String>? imageFile,
    Expression<int>? priceCents,
    Expression<String>? category,
    Expression<int>? monthlyCents,
    Expression<int>? months,
    Expression<int>? resistanceCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastBurnedAt,
    Expression<DateTime>? destroyedAt,
    Expression<DateTime>? movedAt,
    Expression<DateTime>? boughtAt,
    Expression<DateTime>? parkedUntil,
    Expression<DateTime>? followUpAt,
    Expression<String>? reflectionJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imageFile != null) 'image_file': imageFile,
      if (priceCents != null) 'price_cents': priceCents,
      if (category != null) 'category': category,
      if (monthlyCents != null) 'monthly_cents': monthlyCents,
      if (months != null) 'months': months,
      if (resistanceCount != null) 'resistance_count': resistanceCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastBurnedAt != null) 'last_burned_at': lastBurnedAt,
      if (destroyedAt != null) 'destroyed_at': destroyedAt,
      if (movedAt != null) 'moved_at': movedAt,
      if (boughtAt != null) 'bought_at': boughtAt,
      if (parkedUntil != null) 'parked_until': parkedUntil,
      if (followUpAt != null) 'follow_up_at': followUpAt,
      if (reflectionJson != null) 'reflection_json': reflectionJson,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? imageFile,
    Value<int>? priceCents,
    Value<String>? category,
    Value<int?>? monthlyCents,
    Value<int?>? months,
    Value<int>? resistanceCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastBurnedAt,
    Value<DateTime?>? destroyedAt,
    Value<DateTime?>? movedAt,
    Value<DateTime?>? boughtAt,
    Value<DateTime?>? parkedUntil,
    Value<DateTime?>? followUpAt,
    Value<String?>? reflectionJson,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      imageFile: imageFile ?? this.imageFile,
      priceCents: priceCents ?? this.priceCents,
      category: category ?? this.category,
      monthlyCents: monthlyCents ?? this.monthlyCents,
      months: months ?? this.months,
      resistanceCount: resistanceCount ?? this.resistanceCount,
      createdAt: createdAt ?? this.createdAt,
      lastBurnedAt: lastBurnedAt ?? this.lastBurnedAt,
      destroyedAt: destroyedAt ?? this.destroyedAt,
      movedAt: movedAt ?? this.movedAt,
      boughtAt: boughtAt ?? this.boughtAt,
      parkedUntil: parkedUntil ?? this.parkedUntil,
      followUpAt: followUpAt ?? this.followUpAt,
      reflectionJson: reflectionJson ?? this.reflectionJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (imageFile.present) {
      map['image_file'] = Variable<String>(imageFile.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (monthlyCents.present) {
      map['monthly_cents'] = Variable<int>(monthlyCents.value);
    }
    if (months.present) {
      map['months'] = Variable<int>(months.value);
    }
    if (resistanceCount.present) {
      map['resistance_count'] = Variable<int>(resistanceCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastBurnedAt.present) {
      map['last_burned_at'] = Variable<DateTime>(lastBurnedAt.value);
    }
    if (destroyedAt.present) {
      map['destroyed_at'] = Variable<DateTime>(destroyedAt.value);
    }
    if (movedAt.present) {
      map['moved_at'] = Variable<DateTime>(movedAt.value);
    }
    if (boughtAt.present) {
      map['bought_at'] = Variable<DateTime>(boughtAt.value);
    }
    if (parkedUntil.present) {
      map['parked_until'] = Variable<DateTime>(parkedUntil.value);
    }
    if (followUpAt.present) {
      map['follow_up_at'] = Variable<DateTime>(followUpAt.value);
    }
    if (reflectionJson.present) {
      map['reflection_json'] = Variable<String>(reflectionJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('imageFile: $imageFile, ')
          ..write('priceCents: $priceCents, ')
          ..write('category: $category, ')
          ..write('monthlyCents: $monthlyCents, ')
          ..write('months: $months, ')
          ..write('resistanceCount: $resistanceCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastBurnedAt: $lastBurnedAt, ')
          ..write('destroyedAt: $destroyedAt, ')
          ..write('movedAt: $movedAt, ')
          ..write('boughtAt: $boughtAt, ')
          ..write('parkedUntil: $parkedUntil, ')
          ..write('followUpAt: $followUpAt, ')
          ..write('reflectionJson: $reflectionJson')
          ..write(')'))
        .toString();
  }
}

class $BurnsTable extends Burns with TableInfo<$BurnsTable, Burn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BurnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceCentsMeta = const VerificationMeta(
    'priceCents',
  );
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
    'price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('purchase'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, itemId, at, priceCents, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'burns';
  @override
  VerificationContext validateIntegrity(
    Insertable<Burn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('price_cents')) {
      context.handle(
        _priceCentsMeta,
        priceCents.isAcceptableOrUnknown(data['price_cents']!, _priceCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_priceCentsMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Burn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Burn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      priceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_cents'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $BurnsTable createAlias(String alias) {
    return $BurnsTable(attachedDatabase, alias);
  }
}

class Burn extends DataClass implements Insertable<Burn> {
  final int id;
  final int itemId;
  final DateTime at;
  final int priceCents;
  final String category;
  const Burn({
    required this.id,
    required this.itemId,
    required this.at,
    required this.priceCents,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['at'] = Variable<DateTime>(at);
    map['price_cents'] = Variable<int>(priceCents);
    map['category'] = Variable<String>(category);
    return map;
  }

  BurnsCompanion toCompanion(bool nullToAbsent) {
    return BurnsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      at: Value(at),
      priceCents: Value(priceCents),
      category: Value(category),
    );
  }

  factory Burn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Burn(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      at: serializer.fromJson<DateTime>(json['at']),
      priceCents: serializer.fromJson<int>(json['priceCents']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'at': serializer.toJson<DateTime>(at),
      'priceCents': serializer.toJson<int>(priceCents),
      'category': serializer.toJson<String>(category),
    };
  }

  Burn copyWith({
    int? id,
    int? itemId,
    DateTime? at,
    int? priceCents,
    String? category,
  }) => Burn(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    at: at ?? this.at,
    priceCents: priceCents ?? this.priceCents,
    category: category ?? this.category,
  );
  Burn copyWithCompanion(BurnsCompanion data) {
    return Burn(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      at: data.at.present ? data.at.value : this.at,
      priceCents: data.priceCents.present
          ? data.priceCents.value
          : this.priceCents,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Burn(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('at: $at, ')
          ..write('priceCents: $priceCents, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, at, priceCents, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Burn &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.at == this.at &&
          other.priceCents == this.priceCents &&
          other.category == this.category);
}

class BurnsCompanion extends UpdateCompanion<Burn> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<DateTime> at;
  final Value<int> priceCents;
  final Value<String> category;
  const BurnsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.at = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.category = const Value.absent(),
  });
  BurnsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required DateTime at,
    required int priceCents,
    this.category = const Value.absent(),
  }) : itemId = Value(itemId),
       at = Value(at),
       priceCents = Value(priceCents);
  static Insertable<Burn> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<DateTime>? at,
    Expression<int>? priceCents,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (at != null) 'at': at,
      if (priceCents != null) 'price_cents': priceCents,
      if (category != null) 'category': category,
    });
  }

  BurnsCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<DateTime>? at,
    Value<int>? priceCents,
    Value<String>? category,
  }) {
    return BurnsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      at: at ?? this.at,
      priceCents: priceCents ?? this.priceCents,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BurnsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('at: $at, ')
          ..write('priceCents: $priceCents, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $BurnsTable burns = $BurnsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [items, burns];
}

typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> id,
      required String imageFile,
      required int priceCents,
      Value<String> category,
      Value<int?> monthlyCents,
      Value<int?> months,
      Value<int> resistanceCount,
      required DateTime createdAt,
      Value<DateTime?> lastBurnedAt,
      Value<DateTime?> destroyedAt,
      Value<DateTime?> movedAt,
      Value<DateTime?> boughtAt,
      Value<DateTime?> parkedUntil,
      Value<DateTime?> followUpAt,
      Value<String?> reflectionJson,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> id,
      Value<String> imageFile,
      Value<int> priceCents,
      Value<String> category,
      Value<int?> monthlyCents,
      Value<int?> months,
      Value<int> resistanceCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastBurnedAt,
      Value<DateTime?> destroyedAt,
      Value<DateTime?> movedAt,
      Value<DateTime?> boughtAt,
      Value<DateTime?> parkedUntil,
      Value<DateTime?> followUpAt,
      Value<String?> reflectionJson,
    });

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BurnsTable, List<Burn>> _burnsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.burns,
    aliasName: 'items__id__burns__item_id',
  );

  $$BurnsTableProcessedTableManager get burnsRefs {
    final manager = $$BurnsTableTableManager(
      $_db,
      $_db.burns,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_burnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageFile => $composableBuilder(
    column: $table.imageFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyCents => $composableBuilder(
    column: $table.monthlyCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get months => $composableBuilder(
    column: $table.months,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resistanceCount => $composableBuilder(
    column: $table.resistanceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastBurnedAt => $composableBuilder(
    column: $table.lastBurnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get destroyedAt => $composableBuilder(
    column: $table.destroyedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get movedAt => $composableBuilder(
    column: $table.movedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get boughtAt => $composableBuilder(
    column: $table.boughtAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get parkedUntil => $composableBuilder(
    column: $table.parkedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get followUpAt => $composableBuilder(
    column: $table.followUpAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reflectionJson => $composableBuilder(
    column: $table.reflectionJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> burnsRefs(
    Expression<bool> Function($$BurnsTableFilterComposer f) f,
  ) {
    final $$BurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.burns,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BurnsTableFilterComposer(
            $db: $db,
            $table: $db.burns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageFile => $composableBuilder(
    column: $table.imageFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyCents => $composableBuilder(
    column: $table.monthlyCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get months => $composableBuilder(
    column: $table.months,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resistanceCount => $composableBuilder(
    column: $table.resistanceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBurnedAt => $composableBuilder(
    column: $table.lastBurnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get destroyedAt => $composableBuilder(
    column: $table.destroyedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get movedAt => $composableBuilder(
    column: $table.movedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get boughtAt => $composableBuilder(
    column: $table.boughtAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get parkedUntil => $composableBuilder(
    column: $table.parkedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get followUpAt => $composableBuilder(
    column: $table.followUpAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflectionJson => $composableBuilder(
    column: $table.reflectionJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imageFile =>
      $composableBuilder(column: $table.imageFile, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get monthlyCents => $composableBuilder(
    column: $table.monthlyCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get months =>
      $composableBuilder(column: $table.months, builder: (column) => column);

  GeneratedColumn<int> get resistanceCount => $composableBuilder(
    column: $table.resistanceCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastBurnedAt => $composableBuilder(
    column: $table.lastBurnedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get destroyedAt => $composableBuilder(
    column: $table.destroyedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get movedAt =>
      $composableBuilder(column: $table.movedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get boughtAt =>
      $composableBuilder(column: $table.boughtAt, builder: (column) => column);

  GeneratedColumn<DateTime> get parkedUntil => $composableBuilder(
    column: $table.parkedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get followUpAt => $composableBuilder(
    column: $table.followUpAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reflectionJson => $composableBuilder(
    column: $table.reflectionJson,
    builder: (column) => column,
  );

  Expression<T> burnsRefs<T extends Object>(
    Expression<T> Function($$BurnsTableAnnotationComposer a) f,
  ) {
    final $$BurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.burns,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.burns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({bool burnsRefs})
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> imageFile = const Value.absent(),
                Value<int> priceCents = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int?> monthlyCents = const Value.absent(),
                Value<int?> months = const Value.absent(),
                Value<int> resistanceCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastBurnedAt = const Value.absent(),
                Value<DateTime?> destroyedAt = const Value.absent(),
                Value<DateTime?> movedAt = const Value.absent(),
                Value<DateTime?> boughtAt = const Value.absent(),
                Value<DateTime?> parkedUntil = const Value.absent(),
                Value<DateTime?> followUpAt = const Value.absent(),
                Value<String?> reflectionJson = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                imageFile: imageFile,
                priceCents: priceCents,
                category: category,
                monthlyCents: monthlyCents,
                months: months,
                resistanceCount: resistanceCount,
                createdAt: createdAt,
                lastBurnedAt: lastBurnedAt,
                destroyedAt: destroyedAt,
                movedAt: movedAt,
                boughtAt: boughtAt,
                parkedUntil: parkedUntil,
                followUpAt: followUpAt,
                reflectionJson: reflectionJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String imageFile,
                required int priceCents,
                Value<String> category = const Value.absent(),
                Value<int?> monthlyCents = const Value.absent(),
                Value<int?> months = const Value.absent(),
                Value<int> resistanceCount = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastBurnedAt = const Value.absent(),
                Value<DateTime?> destroyedAt = const Value.absent(),
                Value<DateTime?> movedAt = const Value.absent(),
                Value<DateTime?> boughtAt = const Value.absent(),
                Value<DateTime?> parkedUntil = const Value.absent(),
                Value<DateTime?> followUpAt = const Value.absent(),
                Value<String?> reflectionJson = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                imageFile: imageFile,
                priceCents: priceCents,
                category: category,
                monthlyCents: monthlyCents,
                months: months,
                resistanceCount: resistanceCount,
                createdAt: createdAt,
                lastBurnedAt: lastBurnedAt,
                destroyedAt: destroyedAt,
                movedAt: movedAt,
                boughtAt: boughtAt,
                parkedUntil: parkedUntil,
                followUpAt: followUpAt,
                reflectionJson: reflectionJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ItemsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({burnsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (burnsRefs) db.burns],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (burnsRefs)
                    await $_getPrefetchedData<Item, $ItemsTable, Burn>(
                      currentTable: table,
                      referencedTable: $$ItemsTableReferences._burnsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$ItemsTableReferences(db, table, p0).burnsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({bool burnsRefs})
    >;
typedef $$BurnsTableCreateCompanionBuilder =
    BurnsCompanion Function({
      Value<int> id,
      required int itemId,
      required DateTime at,
      required int priceCents,
      Value<String> category,
    });
typedef $$BurnsTableUpdateCompanionBuilder =
    BurnsCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<DateTime> at,
      Value<int> priceCents,
      Value<String> category,
    });

final class $$BurnsTableReferences
    extends BaseReferences<_$AppDatabase, $BurnsTable, Burn> {
  $$BurnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('burns__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BurnsTableFilterComposer extends Composer<_$AppDatabase, $BurnsTable> {
  $$BurnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BurnsTableOrderingComposer
    extends Composer<_$AppDatabase, $BurnsTable> {
  $$BurnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BurnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BurnsTable> {
  $$BurnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BurnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BurnsTable,
          Burn,
          $$BurnsTableFilterComposer,
          $$BurnsTableOrderingComposer,
          $$BurnsTableAnnotationComposer,
          $$BurnsTableCreateCompanionBuilder,
          $$BurnsTableUpdateCompanionBuilder,
          (Burn, $$BurnsTableReferences),
          Burn,
          PrefetchHooks Function({bool itemId})
        > {
  $$BurnsTableTableManager(_$AppDatabase db, $BurnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BurnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BurnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BurnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> priceCents = const Value.absent(),
                Value<String> category = const Value.absent(),
              }) => BurnsCompanion(
                id: id,
                itemId: itemId,
                at: at,
                priceCents: priceCents,
                category: category,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required DateTime at,
                required int priceCents,
                Value<String> category = const Value.absent(),
              }) => BurnsCompanion.insert(
                id: id,
                itemId: itemId,
                at: at,
                priceCents: priceCents,
                category: category,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BurnsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$BurnsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$BurnsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$BurnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BurnsTable,
      Burn,
      $$BurnsTableFilterComposer,
      $$BurnsTableOrderingComposer,
      $$BurnsTableAnnotationComposer,
      $$BurnsTableCreateCompanionBuilder,
      $$BurnsTableUpdateCompanionBuilder,
      (Burn, $$BurnsTableReferences),
      Burn,
      PrefetchHooks Function({bool itemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$BurnsTableTableManager get burns =>
      $$BurnsTableTableManager(_db, _db.burns);
}
