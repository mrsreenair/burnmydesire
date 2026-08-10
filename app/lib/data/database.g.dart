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
          ..write('reflectionJson: $reflectionJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [items];
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
      Value<String?> reflectionJson,
    });

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

  ColumnFilters<String> get reflectionJson => $composableBuilder(
    column: $table.reflectionJson,
    builder: (column) => ColumnFilters(column),
  );
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

  GeneratedColumn<String> get reflectionJson => $composableBuilder(
    column: $table.reflectionJson,
    builder: (column) => column,
  );
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
          (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
          Item,
          PrefetchHooks Function()
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
                reflectionJson: reflectionJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
      Item,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
}
