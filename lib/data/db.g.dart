// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $FoodItemsTable extends FoodItems
    with TableInfo<$FoodItemsTable, FoodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalPer100Meta = const VerificationMeta(
    'kcalPer100',
  );
  @override
  late final GeneratedColumn<double> kcalPer100 = GeneratedColumn<double>(
    'kcal_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100Meta = const VerificationMeta(
    'proteinPer100',
  );
  @override
  late final GeneratedColumn<double> proteinPer100 = GeneratedColumn<double>(
    'protein_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbPer100Meta = const VerificationMeta(
    'carbPer100',
  );
  @override
  late final GeneratedColumn<double> carbPer100 = GeneratedColumn<double>(
    'carb_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPer100Meta = const VerificationMeta(
    'fatPer100',
  );
  @override
  late final GeneratedColumn<double> fatPer100 = GeneratedColumn<double>(
    'fat_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alcoholPer100Meta = const VerificationMeta(
    'alcoholPer100',
  );
  @override
  late final GeneratedColumn<double> alcoholPer100 = GeneratedColumn<double>(
    'alcohol_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _fiberPer100Meta = const VerificationMeta(
    'fiberPer100',
  );
  @override
  late final GeneratedColumn<double> fiberPer100 = GeneratedColumn<double>(
    'fiber_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _sodiumMgPer100Meta = const VerificationMeta(
    'sodiumMgPer100',
  );
  @override
  late final GeneratedColumn<double> sodiumMgPer100 = GeneratedColumn<double>(
    'sodium_mg_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _sugarPer100Meta = const VerificationMeta(
    'sugarPer100',
  );
  @override
  late final GeneratedColumn<double> sugarPer100 = GeneratedColumn<double>(
    'sugar_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _saturatedFatPer100Meta =
      const VerificationMeta('saturatedFatPer100');
  @override
  late final GeneratedColumn<double> saturatedFatPer100 =
      GeneratedColumn<double>(
        'saturated_fat_per100',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _calciumMgPer100Meta = const VerificationMeta(
    'calciumMgPer100',
  );
  @override
  late final GeneratedColumn<double> calciumMgPer100 = GeneratedColumn<double>(
    'calcium_mg_per100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    kcalPer100,
    proteinPer100,
    carbPer100,
    fatPer100,
    alcoholPer100,
    fiberPer100,
    sodiumMgPer100,
    sugarPer100,
    saturatedFatPer100,
    calciumMgPer100,
    isCustom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('kcal_per100')) {
      context.handle(
        _kcalPer100Meta,
        kcalPer100.isAcceptableOrUnknown(data['kcal_per100']!, _kcalPer100Meta),
      );
    } else if (isInserting) {
      context.missing(_kcalPer100Meta);
    }
    if (data.containsKey('protein_per100')) {
      context.handle(
        _proteinPer100Meta,
        proteinPer100.isAcceptableOrUnknown(
          data['protein_per100']!,
          _proteinPer100Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPer100Meta);
    }
    if (data.containsKey('carb_per100')) {
      context.handle(
        _carbPer100Meta,
        carbPer100.isAcceptableOrUnknown(data['carb_per100']!, _carbPer100Meta),
      );
    } else if (isInserting) {
      context.missing(_carbPer100Meta);
    }
    if (data.containsKey('fat_per100')) {
      context.handle(
        _fatPer100Meta,
        fatPer100.isAcceptableOrUnknown(data['fat_per100']!, _fatPer100Meta),
      );
    } else if (isInserting) {
      context.missing(_fatPer100Meta);
    }
    if (data.containsKey('alcohol_per100')) {
      context.handle(
        _alcoholPer100Meta,
        alcoholPer100.isAcceptableOrUnknown(
          data['alcohol_per100']!,
          _alcoholPer100Meta,
        ),
      );
    }
    if (data.containsKey('fiber_per100')) {
      context.handle(
        _fiberPer100Meta,
        fiberPer100.isAcceptableOrUnknown(
          data['fiber_per100']!,
          _fiberPer100Meta,
        ),
      );
    }
    if (data.containsKey('sodium_mg_per100')) {
      context.handle(
        _sodiumMgPer100Meta,
        sodiumMgPer100.isAcceptableOrUnknown(
          data['sodium_mg_per100']!,
          _sodiumMgPer100Meta,
        ),
      );
    }
    if (data.containsKey('sugar_per100')) {
      context.handle(
        _sugarPer100Meta,
        sugarPer100.isAcceptableOrUnknown(
          data['sugar_per100']!,
          _sugarPer100Meta,
        ),
      );
    }
    if (data.containsKey('saturated_fat_per100')) {
      context.handle(
        _saturatedFatPer100Meta,
        saturatedFatPer100.isAcceptableOrUnknown(
          data['saturated_fat_per100']!,
          _saturatedFatPer100Meta,
        ),
      );
    }
    if (data.containsKey('calcium_mg_per100')) {
      context.handle(
        _calciumMgPer100Meta,
        calciumMgPer100.isAcceptableOrUnknown(
          data['calcium_mg_per100']!,
          _calciumMgPer100Meta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  FoodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      kcalPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal_per100'],
      )!,
      proteinPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100'],
      )!,
      carbPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_per100'],
      )!,
      fatPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100'],
      )!,
      alcoholPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alcohol_per100'],
      )!,
      fiberPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_per100'],
      )!,
      sodiumMgPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg_per100'],
      )!,
      sugarPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_per100'],
      )!,
      saturatedFatPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saturated_fat_per100'],
      )!,
      calciumMgPer100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calcium_mg_per100'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
    );
  }

  @override
  $FoodItemsTable createAlias(String alias) {
    return $FoodItemsTable(attachedDatabase, alias);
  }
}

class FoodItem extends DataClass implements Insertable<FoodItem> {
  final int id;
  final String name;
  final String category;
  final double kcalPer100;
  final double proteinPer100;
  final double carbPer100;
  final double fatPer100;

  /// Estimated alcohol g/100g (mainly beverages with residual energy).
  final double alcoholPer100;

  /// Dietary fiber g/100g (营养成分表常见项).
  final double fiberPer100;

  /// Sodium mg/100g.
  final double sodiumMgPer100;

  /// Sugars g/100g.
  final double sugarPer100;

  /// Saturated fat g/100g.
  final double saturatedFatPer100;

  /// Calcium mg/100g.
  final double calciumMgPer100;

  /// User-created foods survive seed sync deletion.
  final bool isCustom;
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbPer100,
    required this.fatPer100,
    required this.alcoholPer100,
    required this.fiberPer100,
    required this.sodiumMgPer100,
    required this.sugarPer100,
    required this.saturatedFatPer100,
    required this.calciumMgPer100,
    required this.isCustom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['kcal_per100'] = Variable<double>(kcalPer100);
    map['protein_per100'] = Variable<double>(proteinPer100);
    map['carb_per100'] = Variable<double>(carbPer100);
    map['fat_per100'] = Variable<double>(fatPer100);
    map['alcohol_per100'] = Variable<double>(alcoholPer100);
    map['fiber_per100'] = Variable<double>(fiberPer100);
    map['sodium_mg_per100'] = Variable<double>(sodiumMgPer100);
    map['sugar_per100'] = Variable<double>(sugarPer100);
    map['saturated_fat_per100'] = Variable<double>(saturatedFatPer100);
    map['calcium_mg_per100'] = Variable<double>(calciumMgPer100);
    map['is_custom'] = Variable<bool>(isCustom);
    return map;
  }

  FoodItemsCompanion toCompanion(bool nullToAbsent) {
    return FoodItemsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      kcalPer100: Value(kcalPer100),
      proteinPer100: Value(proteinPer100),
      carbPer100: Value(carbPer100),
      fatPer100: Value(fatPer100),
      alcoholPer100: Value(alcoholPer100),
      fiberPer100: Value(fiberPer100),
      sodiumMgPer100: Value(sodiumMgPer100),
      sugarPer100: Value(sugarPer100),
      saturatedFatPer100: Value(saturatedFatPer100),
      calciumMgPer100: Value(calciumMgPer100),
      isCustom: Value(isCustom),
    );
  }

  factory FoodItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodItem(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      kcalPer100: serializer.fromJson<double>(json['kcalPer100']),
      proteinPer100: serializer.fromJson<double>(json['proteinPer100']),
      carbPer100: serializer.fromJson<double>(json['carbPer100']),
      fatPer100: serializer.fromJson<double>(json['fatPer100']),
      alcoholPer100: serializer.fromJson<double>(json['alcoholPer100']),
      fiberPer100: serializer.fromJson<double>(json['fiberPer100']),
      sodiumMgPer100: serializer.fromJson<double>(json['sodiumMgPer100']),
      sugarPer100: serializer.fromJson<double>(json['sugarPer100']),
      saturatedFatPer100: serializer.fromJson<double>(
        json['saturatedFatPer100'],
      ),
      calciumMgPer100: serializer.fromJson<double>(json['calciumMgPer100']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'kcalPer100': serializer.toJson<double>(kcalPer100),
      'proteinPer100': serializer.toJson<double>(proteinPer100),
      'carbPer100': serializer.toJson<double>(carbPer100),
      'fatPer100': serializer.toJson<double>(fatPer100),
      'alcoholPer100': serializer.toJson<double>(alcoholPer100),
      'fiberPer100': serializer.toJson<double>(fiberPer100),
      'sodiumMgPer100': serializer.toJson<double>(sodiumMgPer100),
      'sugarPer100': serializer.toJson<double>(sugarPer100),
      'saturatedFatPer100': serializer.toJson<double>(saturatedFatPer100),
      'calciumMgPer100': serializer.toJson<double>(calciumMgPer100),
      'isCustom': serializer.toJson<bool>(isCustom),
    };
  }

  FoodItem copyWith({
    int? id,
    String? name,
    String? category,
    double? kcalPer100,
    double? proteinPer100,
    double? carbPer100,
    double? fatPer100,
    double? alcoholPer100,
    double? fiberPer100,
    double? sodiumMgPer100,
    double? sugarPer100,
    double? saturatedFatPer100,
    double? calciumMgPer100,
    bool? isCustom,
  }) => FoodItem(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    kcalPer100: kcalPer100 ?? this.kcalPer100,
    proteinPer100: proteinPer100 ?? this.proteinPer100,
    carbPer100: carbPer100 ?? this.carbPer100,
    fatPer100: fatPer100 ?? this.fatPer100,
    alcoholPer100: alcoholPer100 ?? this.alcoholPer100,
    fiberPer100: fiberPer100 ?? this.fiberPer100,
    sodiumMgPer100: sodiumMgPer100 ?? this.sodiumMgPer100,
    sugarPer100: sugarPer100 ?? this.sugarPer100,
    saturatedFatPer100: saturatedFatPer100 ?? this.saturatedFatPer100,
    calciumMgPer100: calciumMgPer100 ?? this.calciumMgPer100,
    isCustom: isCustom ?? this.isCustom,
  );
  FoodItem copyWithCompanion(FoodItemsCompanion data) {
    return FoodItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      kcalPer100: data.kcalPer100.present
          ? data.kcalPer100.value
          : this.kcalPer100,
      proteinPer100: data.proteinPer100.present
          ? data.proteinPer100.value
          : this.proteinPer100,
      carbPer100: data.carbPer100.present
          ? data.carbPer100.value
          : this.carbPer100,
      fatPer100: data.fatPer100.present ? data.fatPer100.value : this.fatPer100,
      alcoholPer100: data.alcoholPer100.present
          ? data.alcoholPer100.value
          : this.alcoholPer100,
      fiberPer100: data.fiberPer100.present
          ? data.fiberPer100.value
          : this.fiberPer100,
      sodiumMgPer100: data.sodiumMgPer100.present
          ? data.sodiumMgPer100.value
          : this.sodiumMgPer100,
      sugarPer100: data.sugarPer100.present
          ? data.sugarPer100.value
          : this.sugarPer100,
      saturatedFatPer100: data.saturatedFatPer100.present
          ? data.saturatedFatPer100.value
          : this.saturatedFatPer100,
      calciumMgPer100: data.calciumMgPer100.present
          ? data.calciumMgPer100.value
          : this.calciumMgPer100,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('kcalPer100: $kcalPer100, ')
          ..write('proteinPer100: $proteinPer100, ')
          ..write('carbPer100: $carbPer100, ')
          ..write('fatPer100: $fatPer100, ')
          ..write('alcoholPer100: $alcoholPer100, ')
          ..write('fiberPer100: $fiberPer100, ')
          ..write('sodiumMgPer100: $sodiumMgPer100, ')
          ..write('sugarPer100: $sugarPer100, ')
          ..write('saturatedFatPer100: $saturatedFatPer100, ')
          ..write('calciumMgPer100: $calciumMgPer100, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    kcalPer100,
    proteinPer100,
    carbPer100,
    fatPer100,
    alcoholPer100,
    fiberPer100,
    sodiumMgPer100,
    sugarPer100,
    saturatedFatPer100,
    calciumMgPer100,
    isCustom,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.kcalPer100 == this.kcalPer100 &&
          other.proteinPer100 == this.proteinPer100 &&
          other.carbPer100 == this.carbPer100 &&
          other.fatPer100 == this.fatPer100 &&
          other.alcoholPer100 == this.alcoholPer100 &&
          other.fiberPer100 == this.fiberPer100 &&
          other.sodiumMgPer100 == this.sodiumMgPer100 &&
          other.sugarPer100 == this.sugarPer100 &&
          other.saturatedFatPer100 == this.saturatedFatPer100 &&
          other.calciumMgPer100 == this.calciumMgPer100 &&
          other.isCustom == this.isCustom);
}

class FoodItemsCompanion extends UpdateCompanion<FoodItem> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> category;
  final Value<double> kcalPer100;
  final Value<double> proteinPer100;
  final Value<double> carbPer100;
  final Value<double> fatPer100;
  final Value<double> alcoholPer100;
  final Value<double> fiberPer100;
  final Value<double> sodiumMgPer100;
  final Value<double> sugarPer100;
  final Value<double> saturatedFatPer100;
  final Value<double> calciumMgPer100;
  final Value<bool> isCustom;
  const FoodItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.kcalPer100 = const Value.absent(),
    this.proteinPer100 = const Value.absent(),
    this.carbPer100 = const Value.absent(),
    this.fatPer100 = const Value.absent(),
    this.alcoholPer100 = const Value.absent(),
    this.fiberPer100 = const Value.absent(),
    this.sodiumMgPer100 = const Value.absent(),
    this.sugarPer100 = const Value.absent(),
    this.saturatedFatPer100 = const Value.absent(),
    this.calciumMgPer100 = const Value.absent(),
    this.isCustom = const Value.absent(),
  });
  FoodItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String category,
    required double kcalPer100,
    required double proteinPer100,
    required double carbPer100,
    required double fatPer100,
    this.alcoholPer100 = const Value.absent(),
    this.fiberPer100 = const Value.absent(),
    this.sodiumMgPer100 = const Value.absent(),
    this.sugarPer100 = const Value.absent(),
    this.saturatedFatPer100 = const Value.absent(),
    this.calciumMgPer100 = const Value.absent(),
    this.isCustom = const Value.absent(),
  }) : name = Value(name),
       category = Value(category),
       kcalPer100 = Value(kcalPer100),
       proteinPer100 = Value(proteinPer100),
       carbPer100 = Value(carbPer100),
       fatPer100 = Value(fatPer100);
  static Insertable<FoodItem> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<double>? kcalPer100,
    Expression<double>? proteinPer100,
    Expression<double>? carbPer100,
    Expression<double>? fatPer100,
    Expression<double>? alcoholPer100,
    Expression<double>? fiberPer100,
    Expression<double>? sodiumMgPer100,
    Expression<double>? sugarPer100,
    Expression<double>? saturatedFatPer100,
    Expression<double>? calciumMgPer100,
    Expression<bool>? isCustom,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (kcalPer100 != null) 'kcal_per100': kcalPer100,
      if (proteinPer100 != null) 'protein_per100': proteinPer100,
      if (carbPer100 != null) 'carb_per100': carbPer100,
      if (fatPer100 != null) 'fat_per100': fatPer100,
      if (alcoholPer100 != null) 'alcohol_per100': alcoholPer100,
      if (fiberPer100 != null) 'fiber_per100': fiberPer100,
      if (sodiumMgPer100 != null) 'sodium_mg_per100': sodiumMgPer100,
      if (sugarPer100 != null) 'sugar_per100': sugarPer100,
      if (saturatedFatPer100 != null)
        'saturated_fat_per100': saturatedFatPer100,
      if (calciumMgPer100 != null) 'calcium_mg_per100': calciumMgPer100,
      if (isCustom != null) 'is_custom': isCustom,
    });
  }

  FoodItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? category,
    Value<double>? kcalPer100,
    Value<double>? proteinPer100,
    Value<double>? carbPer100,
    Value<double>? fatPer100,
    Value<double>? alcoholPer100,
    Value<double>? fiberPer100,
    Value<double>? sodiumMgPer100,
    Value<double>? sugarPer100,
    Value<double>? saturatedFatPer100,
    Value<double>? calciumMgPer100,
    Value<bool>? isCustom,
  }) {
    return FoodItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      kcalPer100: kcalPer100 ?? this.kcalPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      carbPer100: carbPer100 ?? this.carbPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
      alcoholPer100: alcoholPer100 ?? this.alcoholPer100,
      fiberPer100: fiberPer100 ?? this.fiberPer100,
      sodiumMgPer100: sodiumMgPer100 ?? this.sodiumMgPer100,
      sugarPer100: sugarPer100 ?? this.sugarPer100,
      saturatedFatPer100: saturatedFatPer100 ?? this.saturatedFatPer100,
      calciumMgPer100: calciumMgPer100 ?? this.calciumMgPer100,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (kcalPer100.present) {
      map['kcal_per100'] = Variable<double>(kcalPer100.value);
    }
    if (proteinPer100.present) {
      map['protein_per100'] = Variable<double>(proteinPer100.value);
    }
    if (carbPer100.present) {
      map['carb_per100'] = Variable<double>(carbPer100.value);
    }
    if (fatPer100.present) {
      map['fat_per100'] = Variable<double>(fatPer100.value);
    }
    if (alcoholPer100.present) {
      map['alcohol_per100'] = Variable<double>(alcoholPer100.value);
    }
    if (fiberPer100.present) {
      map['fiber_per100'] = Variable<double>(fiberPer100.value);
    }
    if (sodiumMgPer100.present) {
      map['sodium_mg_per100'] = Variable<double>(sodiumMgPer100.value);
    }
    if (sugarPer100.present) {
      map['sugar_per100'] = Variable<double>(sugarPer100.value);
    }
    if (saturatedFatPer100.present) {
      map['saturated_fat_per100'] = Variable<double>(saturatedFatPer100.value);
    }
    if (calciumMgPer100.present) {
      map['calcium_mg_per100'] = Variable<double>(calciumMgPer100.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('kcalPer100: $kcalPer100, ')
          ..write('proteinPer100: $proteinPer100, ')
          ..write('carbPer100: $carbPer100, ')
          ..write('fatPer100: $fatPer100, ')
          ..write('alcoholPer100: $alcoholPer100, ')
          ..write('fiberPer100: $fiberPer100, ')
          ..write('sodiumMgPer100: $sodiumMgPer100, ')
          ..write('sugarPer100: $sugarPer100, ')
          ..write('saturatedFatPer100: $saturatedFatPer100, ')
          ..write('calciumMgPer100: $calciumMgPer100, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }
}

class $FoodServingsTable extends FoodServings
    with TableInfo<$FoodServingsTable, FoodServing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodServingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, foodId, label, grams];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_servings';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodServing> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodServing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodServing(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
    );
  }

  @override
  $FoodServingsTable createAlias(String alias) {
    return $FoodServingsTable(attachedDatabase, alias);
  }
}

class FoodServing extends DataClass implements Insertable<FoodServing> {
  final int id;
  final int foodId;
  final String label;

  /// Stored as grams; ml labels use ≈1 ml = 1 g.
  final double grams;
  const FoodServing({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['food_id'] = Variable<int>(foodId);
    map['label'] = Variable<String>(label);
    map['grams'] = Variable<double>(grams);
    return map;
  }

  FoodServingsCompanion toCompanion(bool nullToAbsent) {
    return FoodServingsCompanion(
      id: Value(id),
      foodId: Value(foodId),
      label: Value(label),
      grams: Value(grams),
    );
  }

  factory FoodServing.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodServing(
      id: serializer.fromJson<int>(json['id']),
      foodId: serializer.fromJson<int>(json['foodId']),
      label: serializer.fromJson<String>(json['label']),
      grams: serializer.fromJson<double>(json['grams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'foodId': serializer.toJson<int>(foodId),
      'label': serializer.toJson<String>(label),
      'grams': serializer.toJson<double>(grams),
    };
  }

  FoodServing copyWith({int? id, int? foodId, String? label, double? grams}) =>
      FoodServing(
        id: id ?? this.id,
        foodId: foodId ?? this.foodId,
        label: label ?? this.label,
        grams: grams ?? this.grams,
      );
  FoodServing copyWithCompanion(FoodServingsCompanion data) {
    return FoodServing(
      id: data.id.present ? data.id.value : this.id,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      label: data.label.present ? data.label.value : this.label,
      grams: data.grams.present ? data.grams.value : this.grams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodServing(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, foodId, label, grams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodServing &&
          other.id == this.id &&
          other.foodId == this.foodId &&
          other.label == this.label &&
          other.grams == this.grams);
}

class FoodServingsCompanion extends UpdateCompanion<FoodServing> {
  final Value<int> id;
  final Value<int> foodId;
  final Value<String> label;
  final Value<double> grams;
  const FoodServingsCompanion({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.label = const Value.absent(),
    this.grams = const Value.absent(),
  });
  FoodServingsCompanion.insert({
    this.id = const Value.absent(),
    required int foodId,
    required String label,
    required double grams,
  }) : foodId = Value(foodId),
       label = Value(label),
       grams = Value(grams);
  static Insertable<FoodServing> custom({
    Expression<int>? id,
    Expression<int>? foodId,
    Expression<String>? label,
    Expression<double>? grams,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (label != null) 'label': label,
      if (grams != null) 'grams': grams,
    });
  }

  FoodServingsCompanion copyWith({
    Value<int>? id,
    Value<int>? foodId,
    Value<String>? label,
    Value<double>? grams,
  }) {
    return FoodServingsCompanion(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      label: label ?? this.label,
      grams: grams ?? this.grams,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodServingsCompanion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }
}

class $FavoriteFoodsTable extends FavoriteFoods
    with TableInfo<$FavoriteFoodsTable, FavoriteFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [foodId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {foodId};
  @override
  FavoriteFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteFood(
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteFoodsTable createAlias(String alias) {
    return $FavoriteFoodsTable(attachedDatabase, alias);
  }
}

class FavoriteFood extends DataClass implements Insertable<FavoriteFood> {
  final int foodId;
  final DateTime createdAt;
  const FavoriteFood({required this.foodId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['food_id'] = Variable<int>(foodId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoriteFoodsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteFoodsCompanion(
      foodId: Value(foodId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteFood(
      foodId: serializer.fromJson<int>(json['foodId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'foodId': serializer.toJson<int>(foodId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteFood copyWith({int? foodId, DateTime? createdAt}) => FavoriteFood(
    foodId: foodId ?? this.foodId,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteFood copyWithCompanion(FavoriteFoodsCompanion data) {
    return FavoriteFood(
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFood(')
          ..write('foodId: $foodId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(foodId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteFood &&
          other.foodId == this.foodId &&
          other.createdAt == this.createdAt);
}

class FavoriteFoodsCompanion extends UpdateCompanion<FavoriteFood> {
  final Value<int> foodId;
  final Value<DateTime> createdAt;
  const FavoriteFoodsCompanion({
    this.foodId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoriteFoodsCompanion.insert({
    this.foodId = const Value.absent(),
    required DateTime createdAt,
  }) : createdAt = Value(createdAt);
  static Insertable<FavoriteFood> custom({
    Expression<int>? foodId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (foodId != null) 'food_id': foodId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoriteFoodsCompanion copyWith({
    Value<int>? foodId,
    Value<DateTime>? createdAt,
  }) {
    return FavoriteFoodsCompanion(
      foodId: foodId ?? this.foodId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFoodsCompanion(')
          ..write('foodId: $foodId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WeightLogsTable extends WeightLogs
    with TableInfo<$WeightLogsTable, WeightLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyFatPctMeta = const VerificationMeta(
    'bodyFatPct',
  );
  @override
  late final GeneratedColumn<double> bodyFatPct = GeneratedColumn<double>(
    'body_fat_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseMinutesMeta = const VerificationMeta(
    'exerciseMinutes',
  );
  @override
  late final GeneratedColumn<int> exerciseMinutes = GeneratedColumn<int>(
    'exercise_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    weightKg,
    bodyFatPct,
    exerciseMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('body_fat_pct')) {
      context.handle(
        _bodyFatPctMeta,
        bodyFatPct.isAcceptableOrUnknown(
          data['body_fat_pct']!,
          _bodyFatPctMeta,
        ),
      );
    }
    if (data.containsKey('exercise_minutes')) {
      context.handle(
        _exerciseMinutesMeta,
        exerciseMinutes.isAcceptableOrUnknown(
          data['exercise_minutes']!,
          _exerciseMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      bodyFatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_pct'],
      ),
      exerciseMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_minutes'],
      ),
    );
  }

  @override
  $WeightLogsTable createAlias(String alias) {
    return $WeightLogsTable(attachedDatabase, alias);
  }
}

class WeightLog extends DataClass implements Insertable<WeightLog> {
  final int id;
  final DateTime date;
  final double weightKg;
  final double? bodyFatPct;

  /// Daily exercise minutes for this log date (not per-session).
  final int? exerciseMinutes;
  const WeightLog({
    required this.id,
    required this.date,
    required this.weightKg,
    this.bodyFatPct,
    this.exerciseMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || bodyFatPct != null) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct);
    }
    if (!nullToAbsent || exerciseMinutes != null) {
      map['exercise_minutes'] = Variable<int>(exerciseMinutes);
    }
    return map;
  }

  WeightLogsCompanion toCompanion(bool nullToAbsent) {
    return WeightLogsCompanion(
      id: Value(id),
      date: Value(date),
      weightKg: Value(weightKg),
      bodyFatPct: bodyFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPct),
      exerciseMinutes: exerciseMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseMinutes),
    );
  }

  factory WeightLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      bodyFatPct: serializer.fromJson<double?>(json['bodyFatPct']),
      exerciseMinutes: serializer.fromJson<int?>(json['exerciseMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'weightKg': serializer.toJson<double>(weightKg),
      'bodyFatPct': serializer.toJson<double?>(bodyFatPct),
      'exerciseMinutes': serializer.toJson<int?>(exerciseMinutes),
    };
  }

  WeightLog copyWith({
    int? id,
    DateTime? date,
    double? weightKg,
    Value<double?> bodyFatPct = const Value.absent(),
    Value<int?> exerciseMinutes = const Value.absent(),
  }) => WeightLog(
    id: id ?? this.id,
    date: date ?? this.date,
    weightKg: weightKg ?? this.weightKg,
    bodyFatPct: bodyFatPct.present ? bodyFatPct.value : this.bodyFatPct,
    exerciseMinutes: exerciseMinutes.present
        ? exerciseMinutes.value
        : this.exerciseMinutes,
  );
  WeightLog copyWithCompanion(WeightLogsCompanion data) {
    return WeightLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      bodyFatPct: data.bodyFatPct.present
          ? data.bodyFatPct.value
          : this.bodyFatPct,
      exerciseMinutes: data.exerciseMinutes.present
          ? data.exerciseMinutes.value
          : this.exerciseMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('exerciseMinutes: $exerciseMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, weightKg, bodyFatPct, exerciseMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.weightKg == this.weightKg &&
          other.bodyFatPct == this.bodyFatPct &&
          other.exerciseMinutes == this.exerciseMinutes);
}

class WeightLogsCompanion extends UpdateCompanion<WeightLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> weightKg;
  final Value<double?> bodyFatPct;
  final Value<int?> exerciseMinutes;
  const WeightLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.exerciseMinutes = const Value.absent(),
  });
  WeightLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double weightKg,
    this.bodyFatPct = const Value.absent(),
    this.exerciseMinutes = const Value.absent(),
  }) : date = Value(date),
       weightKg = Value(weightKg);
  static Insertable<WeightLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? weightKg,
    Expression<double>? bodyFatPct,
    Expression<int>? exerciseMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
      if (exerciseMinutes != null) 'exercise_minutes': exerciseMinutes,
    });
  }

  WeightLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<double>? weightKg,
    Value<double?>? bodyFatPct,
    Value<int?>? exerciseMinutes,
  }) {
    return WeightLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (bodyFatPct.present) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct.value);
    }
    if (exerciseMinutes.present) {
      map['exercise_minutes'] = Variable<int>(exerciseMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('exerciseMinutes: $exerciseMinutes')
          ..write(')'))
        .toString();
  }
}

class $MealEntriesTable extends MealEntries
    with TableInfo<$MealEntriesTable, MealEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodNameMeta = const VerificationMeta(
    'foodName',
  );
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
    'food_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
    'carb_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alcoholGMeta = const VerificationMeta(
    'alcoholG',
  );
  @override
  late final GeneratedColumn<double> alcoholG = GeneratedColumn<double>(
    'alcohol_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  @override
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  @override
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _saturatedFatGMeta = const VerificationMeta(
    'saturatedFatG',
  );
  @override
  late final GeneratedColumn<double> saturatedFatG = GeneratedColumn<double>(
    'saturated_fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _calciumMgMeta = const VerificationMeta(
    'calciumMg',
  );
  @override
  late final GeneratedColumn<double> calciumMg = GeneratedColumn<double>(
    'calcium_mg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    mealType,
    foodId,
    foodName,
    grams,
    calories,
    proteinG,
    carbG,
    fatG,
    alcoholG,
    fiberG,
    sodiumMg,
    sugarG,
    saturatedFatG,
    calciumMg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(
        _foodNameMeta,
        foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta),
      );
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carb_g')) {
      context.handle(
        _carbGMeta,
        carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('alcohol_g')) {
      context.handle(
        _alcoholGMeta,
        alcoholG.isAcceptableOrUnknown(data['alcohol_g']!, _alcoholGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    }
    if (data.containsKey('saturated_fat_g')) {
      context.handle(
        _saturatedFatGMeta,
        saturatedFatG.isAcceptableOrUnknown(
          data['saturated_fat_g']!,
          _saturatedFatGMeta,
        ),
      );
    }
    if (data.containsKey('calcium_mg')) {
      context.handle(
        _calciumMgMeta,
        calciumMg.isAcceptableOrUnknown(data['calcium_mg']!, _calciumMgMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      mealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      foodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      alcoholG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alcohol_g'],
      )!,
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      )!,
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      )!,
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      )!,
      saturatedFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saturated_fat_g'],
      )!,
      calciumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calcium_mg'],
      )!,
    );
  }

  @override
  $MealEntriesTable createAlias(String alias) {
    return $MealEntriesTable(attachedDatabase, alias);
  }
}

class MealEntry extends DataClass implements Insertable<MealEntry> {
  final int id;
  final DateTime date;
  final String mealType;
  final int foodId;
  final String foodName;
  final double grams;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double alcoholG;
  final double fiberG;
  final double sodiumMg;
  final double sugarG;
  final double saturatedFatG;
  final double calciumMg;
  const MealEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.alcoholG,
    required this.fiberG,
    required this.sodiumMg,
    required this.sugarG,
    required this.saturatedFatG,
    required this.calciumMg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['meal_type'] = Variable<String>(mealType);
    map['food_id'] = Variable<int>(foodId);
    map['food_name'] = Variable<String>(foodName);
    map['grams'] = Variable<double>(grams);
    map['calories'] = Variable<double>(calories);
    map['protein_g'] = Variable<double>(proteinG);
    map['carb_g'] = Variable<double>(carbG);
    map['fat_g'] = Variable<double>(fatG);
    map['alcohol_g'] = Variable<double>(alcoholG);
    map['fiber_g'] = Variable<double>(fiberG);
    map['sodium_mg'] = Variable<double>(sodiumMg);
    map['sugar_g'] = Variable<double>(sugarG);
    map['saturated_fat_g'] = Variable<double>(saturatedFatG);
    map['calcium_mg'] = Variable<double>(calciumMg);
    return map;
  }

  MealEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealEntriesCompanion(
      id: Value(id),
      date: Value(date),
      mealType: Value(mealType),
      foodId: Value(foodId),
      foodName: Value(foodName),
      grams: Value(grams),
      calories: Value(calories),
      proteinG: Value(proteinG),
      carbG: Value(carbG),
      fatG: Value(fatG),
      alcoholG: Value(alcoholG),
      fiberG: Value(fiberG),
      sodiumMg: Value(sodiumMg),
      sugarG: Value(sugarG),
      saturatedFatG: Value(saturatedFatG),
      calciumMg: Value(calciumMg),
    );
  }

  factory MealEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      mealType: serializer.fromJson<String>(json['mealType']),
      foodId: serializer.fromJson<int>(json['foodId']),
      foodName: serializer.fromJson<String>(json['foodName']),
      grams: serializer.fromJson<double>(json['grams']),
      calories: serializer.fromJson<double>(json['calories']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbG: serializer.fromJson<double>(json['carbG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      alcoholG: serializer.fromJson<double>(json['alcoholG']),
      fiberG: serializer.fromJson<double>(json['fiberG']),
      sodiumMg: serializer.fromJson<double>(json['sodiumMg']),
      sugarG: serializer.fromJson<double>(json['sugarG']),
      saturatedFatG: serializer.fromJson<double>(json['saturatedFatG']),
      calciumMg: serializer.fromJson<double>(json['calciumMg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'mealType': serializer.toJson<String>(mealType),
      'foodId': serializer.toJson<int>(foodId),
      'foodName': serializer.toJson<String>(foodName),
      'grams': serializer.toJson<double>(grams),
      'calories': serializer.toJson<double>(calories),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbG': serializer.toJson<double>(carbG),
      'fatG': serializer.toJson<double>(fatG),
      'alcoholG': serializer.toJson<double>(alcoholG),
      'fiberG': serializer.toJson<double>(fiberG),
      'sodiumMg': serializer.toJson<double>(sodiumMg),
      'sugarG': serializer.toJson<double>(sugarG),
      'saturatedFatG': serializer.toJson<double>(saturatedFatG),
      'calciumMg': serializer.toJson<double>(calciumMg),
    };
  }

  MealEntry copyWith({
    int? id,
    DateTime? date,
    String? mealType,
    int? foodId,
    String? foodName,
    double? grams,
    double? calories,
    double? proteinG,
    double? carbG,
    double? fatG,
    double? alcoholG,
    double? fiberG,
    double? sodiumMg,
    double? sugarG,
    double? saturatedFatG,
    double? calciumMg,
  }) => MealEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    mealType: mealType ?? this.mealType,
    foodId: foodId ?? this.foodId,
    foodName: foodName ?? this.foodName,
    grams: grams ?? this.grams,
    calories: calories ?? this.calories,
    proteinG: proteinG ?? this.proteinG,
    carbG: carbG ?? this.carbG,
    fatG: fatG ?? this.fatG,
    alcoholG: alcoholG ?? this.alcoholG,
    fiberG: fiberG ?? this.fiberG,
    sodiumMg: sodiumMg ?? this.sodiumMg,
    sugarG: sugarG ?? this.sugarG,
    saturatedFatG: saturatedFatG ?? this.saturatedFatG,
    calciumMg: calciumMg ?? this.calciumMg,
  );
  MealEntry copyWithCompanion(MealEntriesCompanion data) {
    return MealEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      grams: data.grams.present ? data.grams.value : this.grams,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      alcoholG: data.alcoholG.present ? data.alcoholG.value : this.alcoholG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      saturatedFatG: data.saturatedFatG.present
          ? data.saturatedFatG.value
          : this.saturatedFatG,
      calciumMg: data.calciumMg.present ? data.calciumMg.value : this.calciumMg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('alcoholG: $alcoholG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('sugarG: $sugarG, ')
          ..write('saturatedFatG: $saturatedFatG, ')
          ..write('calciumMg: $calciumMg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    mealType,
    foodId,
    foodName,
    grams,
    calories,
    proteinG,
    carbG,
    fatG,
    alcoholG,
    fiberG,
    sodiumMg,
    sugarG,
    saturatedFatG,
    calciumMg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.mealType == this.mealType &&
          other.foodId == this.foodId &&
          other.foodName == this.foodName &&
          other.grams == this.grams &&
          other.calories == this.calories &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.alcoholG == this.alcoholG &&
          other.fiberG == this.fiberG &&
          other.sodiumMg == this.sodiumMg &&
          other.sugarG == this.sugarG &&
          other.saturatedFatG == this.saturatedFatG &&
          other.calciumMg == this.calciumMg);
}

class MealEntriesCompanion extends UpdateCompanion<MealEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> mealType;
  final Value<int> foodId;
  final Value<String> foodName;
  final Value<double> grams;
  final Value<double> calories;
  final Value<double> proteinG;
  final Value<double> carbG;
  final Value<double> fatG;
  final Value<double> alcoholG;
  final Value<double> fiberG;
  final Value<double> sodiumMg;
  final Value<double> sugarG;
  final Value<double> saturatedFatG;
  final Value<double> calciumMg;
  const MealEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mealType = const Value.absent(),
    this.foodId = const Value.absent(),
    this.foodName = const Value.absent(),
    this.grams = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.alcoholG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.saturatedFatG = const Value.absent(),
    this.calciumMg = const Value.absent(),
  });
  MealEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String mealType,
    required int foodId,
    required String foodName,
    required double grams,
    required double calories,
    required double proteinG,
    required double carbG,
    required double fatG,
    this.alcoholG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.saturatedFatG = const Value.absent(),
    this.calciumMg = const Value.absent(),
  }) : date = Value(date),
       mealType = Value(mealType),
       foodId = Value(foodId),
       foodName = Value(foodName),
       grams = Value(grams),
       calories = Value(calories),
       proteinG = Value(proteinG),
       carbG = Value(carbG),
       fatG = Value(fatG);
  static Insertable<MealEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? mealType,
    Expression<int>? foodId,
    Expression<String>? foodName,
    Expression<double>? grams,
    Expression<double>? calories,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<double>? alcoholG,
    Expression<double>? fiberG,
    Expression<double>? sodiumMg,
    Expression<double>? sugarG,
    Expression<double>? saturatedFatG,
    Expression<double>? calciumMg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      if (foodId != null) 'food_id': foodId,
      if (foodName != null) 'food_name': foodName,
      if (grams != null) 'grams': grams,
      if (calories != null) 'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (alcoholG != null) 'alcohol_g': alcoholG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (sugarG != null) 'sugar_g': sugarG,
      if (saturatedFatG != null) 'saturated_fat_g': saturatedFatG,
      if (calciumMg != null) 'calcium_mg': calciumMg,
    });
  }

  MealEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? mealType,
    Value<int>? foodId,
    Value<String>? foodName,
    Value<double>? grams,
    Value<double>? calories,
    Value<double>? proteinG,
    Value<double>? carbG,
    Value<double>? fatG,
    Value<double>? alcoholG,
    Value<double>? fiberG,
    Value<double>? sodiumMg,
    Value<double>? sugarG,
    Value<double>? saturatedFatG,
    Value<double>? calciumMg,
  }) {
    return MealEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      grams: grams ?? this.grams,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      alcoholG: alcoholG ?? this.alcoholG,
      fiberG: fiberG ?? this.fiberG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      sugarG: sugarG ?? this.sugarG,
      saturatedFatG: saturatedFatG ?? this.saturatedFatG,
      calciumMg: calciumMg ?? this.calciumMg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (alcoholG.present) {
      map['alcohol_g'] = Variable<double>(alcoholG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (saturatedFatG.present) {
      map['saturated_fat_g'] = Variable<double>(saturatedFatG.value);
    }
    if (calciumMg.present) {
      map['calcium_mg'] = Variable<double>(calciumMg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('alcoholG: $alcoholG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('sugarG: $sugarG, ')
          ..write('saturatedFatG: $saturatedFatG, ')
          ..write('calciumMg: $calciumMg')
          ..write(')'))
        .toString();
  }
}

class $MealPresetsTable extends MealPresets
    with TableInfo<$MealPresetsTable, MealPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPresetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MealPresetsTable createAlias(String alias) {
    return $MealPresetsTable(attachedDatabase, alias);
  }
}

class MealPreset extends DataClass implements Insertable<MealPreset> {
  final int id;
  final String name;
  final DateTime createdAt;
  const MealPreset({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MealPresetsCompanion toCompanion(bool nullToAbsent) {
    return MealPresetsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory MealPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPreset(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MealPreset copyWith({int? id, String? name, DateTime? createdAt}) =>
      MealPreset(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  MealPreset copyWithCompanion(MealPresetsCompanion data) {
    return MealPreset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPreset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPreset &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class MealPresetsCompanion extends UpdateCompanion<MealPreset> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const MealPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MealPresetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<MealPreset> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MealPresetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return MealPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MealPresetItemsTable extends MealPresetItems
    with TableInfo<$MealPresetItemsTable, MealPresetItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPresetItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<int> presetId = GeneratedColumn<int>(
    'preset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodNameMeta = const VerificationMeta(
    'foodName',
  );
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
    'food_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    presetId,
    foodId,
    foodName,
    grams,
    mealType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_preset_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealPresetItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_presetIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(
        _foodNameMeta,
        foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta),
      );
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPresetItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPresetItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preset_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      foodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      mealType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type'],
      )!,
    );
  }

  @override
  $MealPresetItemsTable createAlias(String alias) {
    return $MealPresetItemsTable(attachedDatabase, alias);
  }
}

class MealPresetItem extends DataClass implements Insertable<MealPresetItem> {
  final int id;
  final int presetId;
  final int foodId;
  final String foodName;
  final double grams;
  final String mealType;
  const MealPresetItem({
    required this.id,
    required this.presetId,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.mealType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['preset_id'] = Variable<int>(presetId);
    map['food_id'] = Variable<int>(foodId);
    map['food_name'] = Variable<String>(foodName);
    map['grams'] = Variable<double>(grams);
    map['meal_type'] = Variable<String>(mealType);
    return map;
  }

  MealPresetItemsCompanion toCompanion(bool nullToAbsent) {
    return MealPresetItemsCompanion(
      id: Value(id),
      presetId: Value(presetId),
      foodId: Value(foodId),
      foodName: Value(foodName),
      grams: Value(grams),
      mealType: Value(mealType),
    );
  }

  factory MealPresetItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPresetItem(
      id: serializer.fromJson<int>(json['id']),
      presetId: serializer.fromJson<int>(json['presetId']),
      foodId: serializer.fromJson<int>(json['foodId']),
      foodName: serializer.fromJson<String>(json['foodName']),
      grams: serializer.fromJson<double>(json['grams']),
      mealType: serializer.fromJson<String>(json['mealType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'presetId': serializer.toJson<int>(presetId),
      'foodId': serializer.toJson<int>(foodId),
      'foodName': serializer.toJson<String>(foodName),
      'grams': serializer.toJson<double>(grams),
      'mealType': serializer.toJson<String>(mealType),
    };
  }

  MealPresetItem copyWith({
    int? id,
    int? presetId,
    int? foodId,
    String? foodName,
    double? grams,
    String? mealType,
  }) => MealPresetItem(
    id: id ?? this.id,
    presetId: presetId ?? this.presetId,
    foodId: foodId ?? this.foodId,
    foodName: foodName ?? this.foodName,
    grams: grams ?? this.grams,
    mealType: mealType ?? this.mealType,
  );
  MealPresetItem copyWithCompanion(MealPresetItemsCompanion data) {
    return MealPresetItem(
      id: data.id.present ? data.id.value : this.id,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      grams: data.grams.present ? data.grams.value : this.grams,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPresetItem(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, presetId, foodId, foodName, grams, mealType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPresetItem &&
          other.id == this.id &&
          other.presetId == this.presetId &&
          other.foodId == this.foodId &&
          other.foodName == this.foodName &&
          other.grams == this.grams &&
          other.mealType == this.mealType);
}

class MealPresetItemsCompanion extends UpdateCompanion<MealPresetItem> {
  final Value<int> id;
  final Value<int> presetId;
  final Value<int> foodId;
  final Value<String> foodName;
  final Value<double> grams;
  final Value<String> mealType;
  const MealPresetItemsCompanion({
    this.id = const Value.absent(),
    this.presetId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.foodName = const Value.absent(),
    this.grams = const Value.absent(),
    this.mealType = const Value.absent(),
  });
  MealPresetItemsCompanion.insert({
    this.id = const Value.absent(),
    required int presetId,
    required int foodId,
    required String foodName,
    required double grams,
    required String mealType,
  }) : presetId = Value(presetId),
       foodId = Value(foodId),
       foodName = Value(foodName),
       grams = Value(grams),
       mealType = Value(mealType);
  static Insertable<MealPresetItem> custom({
    Expression<int>? id,
    Expression<int>? presetId,
    Expression<int>? foodId,
    Expression<String>? foodName,
    Expression<double>? grams,
    Expression<String>? mealType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (presetId != null) 'preset_id': presetId,
      if (foodId != null) 'food_id': foodId,
      if (foodName != null) 'food_name': foodName,
      if (grams != null) 'grams': grams,
      if (mealType != null) 'meal_type': mealType,
    });
  }

  MealPresetItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? presetId,
    Value<int>? foodId,
    Value<String>? foodName,
    Value<double>? grams,
    Value<String>? mealType,
  }) {
    return MealPresetItemsCompanion(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      grams: grams ?? this.grams,
      mealType: mealType ?? this.mealType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<int>(presetId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPresetItemsCompanion(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }
}

class $WaterLogsTable extends WaterLogs
    with TableInfo<$WaterLogsTable, WaterLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<int> ml = GeneratedColumn<int>(
    'ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, ml];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    } else if (isInserting) {
      context.missing(_mlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date},
  ];
  @override
  WaterLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      ml: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ml'],
      )!,
    );
  }

  @override
  $WaterLogsTable createAlias(String alias) {
    return $WaterLogsTable(attachedDatabase, alias);
  }
}

class WaterLog extends DataClass implements Insertable<WaterLog> {
  final int id;
  final DateTime date;
  final int ml;
  const WaterLog({required this.id, required this.date, required this.ml});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['ml'] = Variable<int>(ml);
    return map;
  }

  WaterLogsCompanion toCompanion(bool nullToAbsent) {
    return WaterLogsCompanion(id: Value(id), date: Value(date), ml: Value(ml));
  }

  factory WaterLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      ml: serializer.fromJson<int>(json['ml']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'ml': serializer.toJson<int>(ml),
    };
  }

  WaterLog copyWith({int? id, DateTime? date, int? ml}) =>
      WaterLog(id: id ?? this.id, date: date ?? this.date, ml: ml ?? this.ml);
  WaterLog copyWithCompanion(WaterLogsCompanion data) {
    return WaterLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      ml: data.ml.present ? data.ml.value : this.ml,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, ml);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.ml == this.ml);
}

class WaterLogsCompanion extends UpdateCompanion<WaterLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> ml;
  const WaterLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.ml = const Value.absent(),
  });
  WaterLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int ml,
  }) : date = Value(date),
       ml = Value(ml);
  static Insertable<WaterLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? ml,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (ml != null) 'ml': ml,
    });
  }

  WaterLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? ml,
  }) {
    return WaterLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      ml: ml ?? this.ml,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (ml.present) {
      map['ml'] = Variable<int>(ml.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }
}

class $StepLogsTable extends StepLogs with TableInfo<$StepLogsTable, StepLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, steps];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<StepLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date},
  ];
  @override
  StepLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
    );
  }

  @override
  $StepLogsTable createAlias(String alias) {
    return $StepLogsTable(attachedDatabase, alias);
  }
}

class StepLog extends DataClass implements Insertable<StepLog> {
  final int id;
  final DateTime date;
  final int steps;
  const StepLog({required this.id, required this.date, required this.steps});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['steps'] = Variable<int>(steps);
    return map;
  }

  StepLogsCompanion toCompanion(bool nullToAbsent) {
    return StepLogsCompanion(
      id: Value(id),
      date: Value(date),
      steps: Value(steps),
    );
  }

  factory StepLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      steps: serializer.fromJson<int>(json['steps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'steps': serializer.toJson<int>(steps),
    };
  }

  StepLog copyWith({int? id, DateTime? date, int? steps}) => StepLog(
    id: id ?? this.id,
    date: date ?? this.date,
    steps: steps ?? this.steps,
  );
  StepLog copyWithCompanion(StepLogsCompanion data) {
    return StepLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      steps: data.steps.present ? data.steps.value : this.steps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('steps: $steps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, steps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.steps == this.steps);
}

class StepLogsCompanion extends UpdateCompanion<StepLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> steps;
  const StepLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.steps = const Value.absent(),
  });
  StepLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int steps,
  }) : date = Value(date),
       steps = Value(steps);
  static Insertable<StepLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? steps,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (steps != null) 'steps': steps,
    });
  }

  StepLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? steps,
  }) {
    return StepLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('steps: $steps')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
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
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
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
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
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

  AppMetaData copyWith({String? key, String? value}) =>
      AppMetaData(key: key ?? this.key, value: value ?? this.value);
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
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
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaData> custom({
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

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
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
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    defaultValue: const Constant('other'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, unit, isCustom, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String name;
  final String unit;
  final bool isCustom;

  /// English category key: chest, back, legs, core, core_timed, cardio,
  /// shoulders_arms, custom, other.
  final String category;
  const Exercise({
    required this.id,
    required this.name,
    required this.unit,
    required this.isCustom,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['is_custom'] = Variable<bool>(isCustom);
    map['category'] = Variable<String>(category);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      isCustom: Value(isCustom),
      category: Value(category),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'isCustom': serializer.toJson<bool>(isCustom),
      'category': serializer.toJson<String>(category),
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    String? unit,
    bool? isCustom,
    String? category,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    isCustom: isCustom ?? this.isCustom,
    category: category ?? this.category,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('isCustom: $isCustom, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, unit, isCustom, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.isCustom == this.isCustom &&
          other.category == this.category);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<bool> isCustom;
  final Value<String> category;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.category = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String unit,
    this.isCustom = const Value.absent(),
    this.category = const Value.absent(),
  }) : name = Value(name),
       unit = Value(unit);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<bool>? isCustom,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (isCustom != null) 'is_custom': isCustom,
      if (category != null) 'category': category,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? unit,
    Value<bool>? isCustom,
    Value<String>? category,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      isCustom: isCustom ?? this.isCustom,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('isCustom: $isCustom, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $WorkoutPlansTable extends WorkoutPlans
    with TableInfo<$WorkoutPlansTable, WorkoutPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutPlansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkoutPlansTable createAlias(String alias) {
    return $WorkoutPlansTable(attachedDatabase, alias);
  }
}

class WorkoutPlan extends DataClass implements Insertable<WorkoutPlan> {
  final int id;
  final String name;
  final DateTime createdAt;
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkoutPlansCompanion toCompanion(bool nullToAbsent) {
    return WorkoutPlansCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory WorkoutPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutPlan(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkoutPlan copyWith({int? id, String? name, DateTime? createdAt}) =>
      WorkoutPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  WorkoutPlan copyWithCompanion(WorkoutPlansCompanion data) {
    return WorkoutPlan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutPlan &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class WorkoutPlansCompanion extends UpdateCompanion<WorkoutPlan> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const WorkoutPlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkoutPlansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<WorkoutPlan> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkoutPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return WorkoutPlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutPlanItemsTable extends WorkoutPlanItems
    with TableInfo<$WorkoutPlanItemsTable, WorkoutPlanItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutPlanItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    exerciseId,
    exerciseName,
    targetSets,
    targetReps,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_plan_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutPlanItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetSetsMeta);
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetRepsMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutPlanItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutPlanItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      )!,
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WorkoutPlanItemsTable createAlias(String alias) {
    return $WorkoutPlanItemsTable(attachedDatabase, alias);
  }
}

class WorkoutPlanItem extends DataClass implements Insertable<WorkoutPlanItem> {
  final int id;
  final int planId;
  final int exerciseId;
  final String exerciseName;
  final int targetSets;

  /// Target reps, or target seconds when the exercise unit is seconds.
  final int targetReps;
  final int sortOrder;
  const WorkoutPlanItem({
    required this.id,
    required this.planId,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['exercise_name'] = Variable<String>(exerciseName);
    map['target_sets'] = Variable<int>(targetSets);
    map['target_reps'] = Variable<int>(targetReps);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WorkoutPlanItemsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutPlanItemsCompanion(
      id: Value(id),
      planId: Value(planId),
      exerciseId: Value(exerciseId),
      exerciseName: Value(exerciseName),
      targetSets: Value(targetSets),
      targetReps: Value(targetReps),
      sortOrder: Value(sortOrder),
    );
  }

  factory WorkoutPlanItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutPlanItem(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int>(targetReps),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WorkoutPlanItem copyWith({
    int? id,
    int? planId,
    int? exerciseId,
    String? exerciseName,
    int? targetSets,
    int? targetReps,
    int? sortOrder,
  }) => WorkoutPlanItem(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps ?? this.targetReps,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WorkoutPlanItem copyWithCompanion(WorkoutPlanItemsCompanion data) {
    return WorkoutPlanItem(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlanItem(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    exerciseId,
    exerciseName,
    targetSets,
    targetReps,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutPlanItem &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.sortOrder == this.sortOrder);
}

class WorkoutPlanItemsCompanion extends UpdateCompanion<WorkoutPlanItem> {
  final Value<int> id;
  final Value<int> planId;
  final Value<int> exerciseId;
  final Value<String> exerciseName;
  final Value<int> targetSets;
  final Value<int> targetReps;
  final Value<int> sortOrder;
  const WorkoutPlanItemsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  WorkoutPlanItemsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required int exerciseId,
    required String exerciseName,
    required int targetSets,
    required int targetReps,
    this.sortOrder = const Value.absent(),
  }) : planId = Value(planId),
       exerciseId = Value(exerciseId),
       exerciseName = Value(exerciseName),
       targetSets = Value(targetSets),
       targetReps = Value(targetReps);
  static Insertable<WorkoutPlanItem> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<int>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  WorkoutPlanItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<int>? exerciseId,
    Value<String>? exerciseName,
    Value<int>? targetSets,
    Value<int>? targetReps,
    Value<int>? sortOrder,
  }) {
    return WorkoutPlanItemsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlanItemsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $DayWorkoutsTable extends DayWorkouts
    with TableInfo<$DayWorkoutsTable, DayWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayWorkoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planNameMeta = const VerificationMeta(
    'planName',
  );
  @override
  late final GeneratedColumn<String> planName = GeneratedColumn<String>(
    'plan_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, planId, planName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayWorkout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    }
    if (data.containsKey('plan_name')) {
      context.handle(
        _planNameMeta,
        planName.isAcceptableOrUnknown(data['plan_name']!, _planNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayWorkout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      ),
      planName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_name'],
      ),
    );
  }

  @override
  $DayWorkoutsTable createAlias(String alias) {
    return $DayWorkoutsTable(attachedDatabase, alias);
  }
}

class DayWorkout extends DataClass implements Insertable<DayWorkout> {
  final int id;
  final DateTime date;
  final int? planId;
  final String? planName;
  const DayWorkout({
    required this.id,
    required this.date,
    this.planId,
    this.planName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<int>(planId);
    }
    if (!nullToAbsent || planName != null) {
      map['plan_name'] = Variable<String>(planName);
    }
    return map;
  }

  DayWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return DayWorkoutsCompanion(
      id: Value(id),
      date: Value(date),
      planId: planId == null && nullToAbsent
          ? const Value.absent()
          : Value(planId),
      planName: planName == null && nullToAbsent
          ? const Value.absent()
          : Value(planName),
    );
  }

  factory DayWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayWorkout(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      planId: serializer.fromJson<int?>(json['planId']),
      planName: serializer.fromJson<String?>(json['planName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'planId': serializer.toJson<int?>(planId),
      'planName': serializer.toJson<String?>(planName),
    };
  }

  DayWorkout copyWith({
    int? id,
    DateTime? date,
    Value<int?> planId = const Value.absent(),
    Value<String?> planName = const Value.absent(),
  }) => DayWorkout(
    id: id ?? this.id,
    date: date ?? this.date,
    planId: planId.present ? planId.value : this.planId,
    planName: planName.present ? planName.value : this.planName,
  );
  DayWorkout copyWithCompanion(DayWorkoutsCompanion data) {
    return DayWorkout(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      planId: data.planId.present ? data.planId.value : this.planId,
      planName: data.planName.present ? data.planName.value : this.planName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayWorkout(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('planId: $planId, ')
          ..write('planName: $planName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, planId, planName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayWorkout &&
          other.id == this.id &&
          other.date == this.date &&
          other.planId == this.planId &&
          other.planName == this.planName);
}

class DayWorkoutsCompanion extends UpdateCompanion<DayWorkout> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int?> planId;
  final Value<String?> planName;
  const DayWorkoutsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.planId = const Value.absent(),
    this.planName = const Value.absent(),
  });
  DayWorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.planId = const Value.absent(),
    this.planName = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DayWorkout> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? planId,
    Expression<String>? planName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (planId != null) 'plan_id': planId,
      if (planName != null) 'plan_name': planName,
    });
  }

  DayWorkoutsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int?>? planId,
    Value<String?>? planName,
  }) {
    return DayWorkoutsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (planName.present) {
      map['plan_name'] = Variable<String>(planName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('planId: $planId, ')
          ..write('planName: $planName')
          ..write(')'))
        .toString();
  }
}

class $DayWorkoutItemsTable extends DayWorkoutItems
    with TableInfo<$DayWorkoutItemsTable, DayWorkoutItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayWorkoutItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayWorkoutIdMeta = const VerificationMeta(
    'dayWorkoutId',
  );
  @override
  late final GeneratedColumn<int> dayWorkoutId = GeneratedColumn<int>(
    'day_workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayWorkoutId,
    exerciseId,
    exerciseName,
    targetSets,
    targetReps,
    sortOrder,
    done,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_workout_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayWorkoutItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_workout_id')) {
      context.handle(
        _dayWorkoutIdMeta,
        dayWorkoutId.isAcceptableOrUnknown(
          data['day_workout_id']!,
          _dayWorkoutIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayWorkoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetSetsMeta);
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetRepsMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayWorkoutItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayWorkoutItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayWorkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_workout_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      )!,
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
    );
  }

  @override
  $DayWorkoutItemsTable createAlias(String alias) {
    return $DayWorkoutItemsTable(attachedDatabase, alias);
  }
}

class DayWorkoutItem extends DataClass implements Insertable<DayWorkoutItem> {
  final int id;
  final int dayWorkoutId;
  final int exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int sortOrder;
  final bool done;
  const DayWorkoutItem({
    required this.id,
    required this.dayWorkoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.sortOrder,
    required this.done,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_workout_id'] = Variable<int>(dayWorkoutId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['exercise_name'] = Variable<String>(exerciseName);
    map['target_sets'] = Variable<int>(targetSets);
    map['target_reps'] = Variable<int>(targetReps);
    map['sort_order'] = Variable<int>(sortOrder);
    map['done'] = Variable<bool>(done);
    return map;
  }

  DayWorkoutItemsCompanion toCompanion(bool nullToAbsent) {
    return DayWorkoutItemsCompanion(
      id: Value(id),
      dayWorkoutId: Value(dayWorkoutId),
      exerciseId: Value(exerciseId),
      exerciseName: Value(exerciseName),
      targetSets: Value(targetSets),
      targetReps: Value(targetReps),
      sortOrder: Value(sortOrder),
      done: Value(done),
    );
  }

  factory DayWorkoutItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayWorkoutItem(
      id: serializer.fromJson<int>(json['id']),
      dayWorkoutId: serializer.fromJson<int>(json['dayWorkoutId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      done: serializer.fromJson<bool>(json['done']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayWorkoutId': serializer.toJson<int>(dayWorkoutId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int>(targetReps),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'done': serializer.toJson<bool>(done),
    };
  }

  DayWorkoutItem copyWith({
    int? id,
    int? dayWorkoutId,
    int? exerciseId,
    String? exerciseName,
    int? targetSets,
    int? targetReps,
    int? sortOrder,
    bool? done,
  }) => DayWorkoutItem(
    id: id ?? this.id,
    dayWorkoutId: dayWorkoutId ?? this.dayWorkoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps ?? this.targetReps,
    sortOrder: sortOrder ?? this.sortOrder,
    done: done ?? this.done,
  );
  DayWorkoutItem copyWithCompanion(DayWorkoutItemsCompanion data) {
    return DayWorkoutItem(
      id: data.id.present ? data.id.value : this.id,
      dayWorkoutId: data.dayWorkoutId.present
          ? data.dayWorkoutId.value
          : this.dayWorkoutId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      done: data.done.present ? data.done.value : this.done,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayWorkoutItem(')
          ..write('id: $id, ')
          ..write('dayWorkoutId: $dayWorkoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayWorkoutId,
    exerciseId,
    exerciseName,
    targetSets,
    targetReps,
    sortOrder,
    done,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayWorkoutItem &&
          other.id == this.id &&
          other.dayWorkoutId == this.dayWorkoutId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.sortOrder == this.sortOrder &&
          other.done == this.done);
}

class DayWorkoutItemsCompanion extends UpdateCompanion<DayWorkoutItem> {
  final Value<int> id;
  final Value<int> dayWorkoutId;
  final Value<int> exerciseId;
  final Value<String> exerciseName;
  final Value<int> targetSets;
  final Value<int> targetReps;
  final Value<int> sortOrder;
  final Value<bool> done;
  const DayWorkoutItemsCompanion({
    this.id = const Value.absent(),
    this.dayWorkoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.done = const Value.absent(),
  });
  DayWorkoutItemsCompanion.insert({
    this.id = const Value.absent(),
    required int dayWorkoutId,
    required int exerciseId,
    required String exerciseName,
    required int targetSets,
    required int targetReps,
    this.sortOrder = const Value.absent(),
    this.done = const Value.absent(),
  }) : dayWorkoutId = Value(dayWorkoutId),
       exerciseId = Value(exerciseId),
       exerciseName = Value(exerciseName),
       targetSets = Value(targetSets),
       targetReps = Value(targetReps);
  static Insertable<DayWorkoutItem> custom({
    Expression<int>? id,
    Expression<int>? dayWorkoutId,
    Expression<int>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<int>? sortOrder,
    Expression<bool>? done,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayWorkoutId != null) 'day_workout_id': dayWorkoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (done != null) 'done': done,
    });
  }

  DayWorkoutItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? dayWorkoutId,
    Value<int>? exerciseId,
    Value<String>? exerciseName,
    Value<int>? targetSets,
    Value<int>? targetReps,
    Value<int>? sortOrder,
    Value<bool>? done,
  }) {
    return DayWorkoutItemsCompanion(
      id: id ?? this.id,
      dayWorkoutId: dayWorkoutId ?? this.dayWorkoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      sortOrder: sortOrder ?? this.sortOrder,
      done: done ?? this.done,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayWorkoutId.present) {
      map['day_workout_id'] = Variable<int>(dayWorkoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayWorkoutItemsCompanion(')
          ..write('id: $id, ')
          ..write('dayWorkoutId: $dayWorkoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetLogsTable extends WorkoutSetLogs
    with TableInfo<$WorkoutSetLogsTable, WorkoutSetLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayWorkoutItemIdMeta = const VerificationMeta(
    'dayWorkoutItemId',
  );
  @override
  late final GeneratedColumn<int> dayWorkoutItemId = GeneratedColumn<int>(
    'day_workout_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    exerciseId,
    exerciseName,
    setIndex,
    reps,
    durationSec,
    dayWorkoutItemId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_set_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSetLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('day_workout_item_id')) {
      context.handle(
        _dayWorkoutItemIdMeta,
        dayWorkoutItemId.isAcceptableOrUnknown(
          data['day_workout_item_id']!,
          _dayWorkoutItemIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSetLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSetLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      dayWorkoutItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_workout_item_id'],
      ),
    );
  }

  @override
  $WorkoutSetLogsTable createAlias(String alias) {
    return $WorkoutSetLogsTable(attachedDatabase, alias);
  }
}

class WorkoutSetLog extends DataClass implements Insertable<WorkoutSetLog> {
  final int id;
  final DateTime date;
  final int exerciseId;
  final String exerciseName;
  final int setIndex;
  final int? reps;
  final int? durationSec;
  final int? dayWorkoutItemId;
  const WorkoutSetLog({
    required this.id,
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.setIndex,
    this.reps,
    this.durationSec,
    this.dayWorkoutItemId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['exercise_name'] = Variable<String>(exerciseName);
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    if (!nullToAbsent || dayWorkoutItemId != null) {
      map['day_workout_item_id'] = Variable<int>(dayWorkoutItemId);
    }
    return map;
  }

  WorkoutSetLogsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetLogsCompanion(
      id: Value(id),
      date: Value(date),
      exerciseId: Value(exerciseId),
      exerciseName: Value(exerciseName),
      setIndex: Value(setIndex),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      dayWorkoutItemId: dayWorkoutItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(dayWorkoutItemId),
    );
  }

  factory WorkoutSetLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSetLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      reps: serializer.fromJson<int?>(json['reps']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      dayWorkoutItemId: serializer.fromJson<int?>(json['dayWorkoutItemId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'setIndex': serializer.toJson<int>(setIndex),
      'reps': serializer.toJson<int?>(reps),
      'durationSec': serializer.toJson<int?>(durationSec),
      'dayWorkoutItemId': serializer.toJson<int?>(dayWorkoutItemId),
    };
  }

  WorkoutSetLog copyWith({
    int? id,
    DateTime? date,
    int? exerciseId,
    String? exerciseName,
    int? setIndex,
    Value<int?> reps = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    Value<int?> dayWorkoutItemId = const Value.absent(),
  }) => WorkoutSetLog(
    id: id ?? this.id,
    date: date ?? this.date,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    setIndex: setIndex ?? this.setIndex,
    reps: reps.present ? reps.value : this.reps,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    dayWorkoutItemId: dayWorkoutItemId.present
        ? dayWorkoutItemId.value
        : this.dayWorkoutItemId,
  );
  WorkoutSetLog copyWithCompanion(WorkoutSetLogsCompanion data) {
    return WorkoutSetLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      reps: data.reps.present ? data.reps.value : this.reps,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      dayWorkoutItemId: data.dayWorkoutItemId.present
          ? data.dayWorkoutItemId.value
          : this.dayWorkoutItemId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('durationSec: $durationSec, ')
          ..write('dayWorkoutItemId: $dayWorkoutItemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    exerciseId,
    exerciseName,
    setIndex,
    reps,
    durationSec,
    dayWorkoutItemId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSetLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.setIndex == this.setIndex &&
          other.reps == this.reps &&
          other.durationSec == this.durationSec &&
          other.dayWorkoutItemId == this.dayWorkoutItemId);
}

class WorkoutSetLogsCompanion extends UpdateCompanion<WorkoutSetLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> exerciseId;
  final Value<String> exerciseName;
  final Value<int> setIndex;
  final Value<int?> reps;
  final Value<int?> durationSec;
  final Value<int?> dayWorkoutItemId;
  const WorkoutSetLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.dayWorkoutItemId = const Value.absent(),
  });
  WorkoutSetLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int exerciseId,
    required String exerciseName,
    required int setIndex,
    this.reps = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.dayWorkoutItemId = const Value.absent(),
  }) : date = Value(date),
       exerciseId = Value(exerciseId),
       exerciseName = Value(exerciseName),
       setIndex = Value(setIndex);
  static Insertable<WorkoutSetLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? setIndex,
    Expression<int>? reps,
    Expression<int>? durationSec,
    Expression<int>? dayWorkoutItemId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (setIndex != null) 'set_index': setIndex,
      if (reps != null) 'reps': reps,
      if (durationSec != null) 'duration_sec': durationSec,
      if (dayWorkoutItemId != null) 'day_workout_item_id': dayWorkoutItemId,
    });
  }

  WorkoutSetLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? exerciseId,
    Value<String>? exerciseName,
    Value<int>? setIndex,
    Value<int?>? reps,
    Value<int?>? durationSec,
    Value<int?>? dayWorkoutItemId,
  }) {
    return WorkoutSetLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      durationSec: durationSec ?? this.durationSec,
      dayWorkoutItemId: dayWorkoutItemId ?? this.dayWorkoutItemId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (dayWorkoutItemId.present) {
      map['day_workout_item_id'] = Variable<int>(dayWorkoutItemId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('durationSec: $durationSec, ')
          ..write('dayWorkoutItemId: $dayWorkoutItemId')
          ..write(')'))
        .toString();
  }
}

class $DailyNotesTable extends DailyNotes
    with TableInfo<$DailyNotesTable, DailyNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, content, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date},
  ];
  @override
  DailyNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DailyNotesTable createAlias(String alias) {
    return $DailyNotesTable(attachedDatabase, alias);
  }
}

class DailyNote extends DataClass implements Insertable<DailyNote> {
  final int id;
  final DateTime date;
  final String content;
  final DateTime updatedAt;
  const DailyNote({
    required this.id,
    required this.date,
    required this.content,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['content'] = Variable<String>(content);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyNotesCompanion toCompanion(bool nullToAbsent) {
    return DailyNotesCompanion(
      id: Value(id),
      date: Value(date),
      content: Value(content),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyNote(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      content: serializer.fromJson<String>(json['content']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'content': serializer.toJson<String>(content),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyNote copyWith({
    int? id,
    DateTime? date,
    String? content,
    DateTime? updatedAt,
  }) => DailyNote(
    id: id ?? this.id,
    date: date ?? this.date,
    content: content ?? this.content,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyNote copyWithCompanion(DailyNotesCompanion data) {
    return DailyNote(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      content: data.content.present ? data.content.value : this.content,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyNote(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, content, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNote &&
          other.id == this.id &&
          other.date == this.date &&
          other.content == this.content &&
          other.updatedAt == this.updatedAt);
}

class DailyNotesCompanion extends UpdateCompanion<DailyNote> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> content;
  final Value<DateTime> updatedAt;
  const DailyNotesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.content = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DailyNotesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String content,
    required DateTime updatedAt,
  }) : date = Value(date),
       content = Value(content),
       updatedAt = Value(updatedAt);
  static Insertable<DailyNote> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? content,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (content != null) 'content': content,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DailyNotesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? content,
    Value<DateTime>? updatedAt,
  }) {
    return DailyNotesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyNotesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DietStrategyPlansTable extends DietStrategyPlans
    with TableInfo<$DietStrategyPlansTable, DietStrategyPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietStrategyPlansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strategyMeta = const VerificationMeta(
    'strategy',
  );
  @override
  late final GeneratedColumn<String> strategy = GeneratedColumn<String>(
    'strategy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<String> effectiveFrom = GeneratedColumn<String>(
    'effective_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedOnMeta = const VerificationMeta(
    'endedOn',
  );
  @override
  late final GeneratedColumn<String> endedOn = GeneratedColumn<String>(
    'ended_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _referenceWeightKgMeta = const VerificationMeta(
    'referenceWeightKg',
  );
  @override
  late final GeneratedColumn<double> referenceWeightKg =
      GeneratedColumn<double>(
        'reference_weight_kg',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _estimatedTdeeMeta = const VerificationMeta(
    'estimatedTdee',
  );
  @override
  late final GeneratedColumn<double> estimatedTdee = GeneratedColumn<double>(
    'estimated_tdee',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deficitFractionMeta = const VerificationMeta(
    'deficitFraction',
  );
  @override
  late final GeneratedColumn<double> deficitFraction = GeneratedColumn<double>(
    'deficit_fraction',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPerKgMeta = const VerificationMeta(
    'proteinPerKg',
  );
  @override
  late final GeneratedColumn<double> proteinPerKg = GeneratedColumn<double>(
    'protein_per_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPerKgMeta = const VerificationMeta(
    'fatPerKg',
  );
  @override
  late final GeneratedColumn<double> fatPerKg = GeneratedColumn<double>(
    'fat_per_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseEnergyMeta = const VerificationMeta(
    'baseEnergy',
  );
  @override
  late final GeneratedColumn<double> baseEnergy = GeneratedColumn<double>(
    'base_energy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleMeta = const VerificationMeta(
    'schedule',
  );
  @override
  late final GeneratedColumn<String> schedule = GeneratedColumn<String>(
    'schedule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbAmplitudeGMeta = const VerificationMeta(
    'carbAmplitudeG',
  );
  @override
  late final GeneratedColumn<double> carbAmplitudeG = GeneratedColumn<double>(
    'carb_amplitude_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taperStageMeta = const VerificationMeta(
    'taperStage',
  );
  @override
  late final GeneratedColumn<int> taperStage = GeneratedColumn<int>(
    'taper_stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _observationStartMeta = const VerificationMeta(
    'observationStart',
  );
  @override
  late final GeneratedColumn<String> observationStart = GeneratedColumn<String>(
    'observation_start',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observationDaysMeta = const VerificationMeta(
    'observationDays',
  );
  @override
  late final GeneratedColumn<int> observationDays = GeneratedColumn<int>(
    'observation_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(14),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _legacyCaloriesMeta = const VerificationMeta(
    'legacyCalories',
  );
  @override
  late final GeneratedColumn<int> legacyCalories = GeneratedColumn<int>(
    'legacy_calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    strategy,
    status,
    effectiveFrom,
    endedOn,
    createdAt,
    referenceWeightKg,
    estimatedTdee,
    deficitFraction,
    proteinPerKg,
    fatPerKg,
    baseEnergy,
    schedule,
    carbAmplitudeG,
    taperStage,
    observationStart,
    observationDays,
    reason,
    legacyCalories,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_strategy_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietStrategyPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('strategy')) {
      context.handle(
        _strategyMeta,
        strategy.isAcceptableOrUnknown(data['strategy']!, _strategyMeta),
      );
    } else if (isInserting) {
      context.missing(_strategyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('ended_on')) {
      context.handle(
        _endedOnMeta,
        endedOn.isAcceptableOrUnknown(data['ended_on']!, _endedOnMeta),
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
    if (data.containsKey('reference_weight_kg')) {
      context.handle(
        _referenceWeightKgMeta,
        referenceWeightKg.isAcceptableOrUnknown(
          data['reference_weight_kg']!,
          _referenceWeightKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceWeightKgMeta);
    }
    if (data.containsKey('estimated_tdee')) {
      context.handle(
        _estimatedTdeeMeta,
        estimatedTdee.isAcceptableOrUnknown(
          data['estimated_tdee']!,
          _estimatedTdeeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_estimatedTdeeMeta);
    }
    if (data.containsKey('deficit_fraction')) {
      context.handle(
        _deficitFractionMeta,
        deficitFraction.isAcceptableOrUnknown(
          data['deficit_fraction']!,
          _deficitFractionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deficitFractionMeta);
    }
    if (data.containsKey('protein_per_kg')) {
      context.handle(
        _proteinPerKgMeta,
        proteinPerKg.isAcceptableOrUnknown(
          data['protein_per_kg']!,
          _proteinPerKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPerKgMeta);
    }
    if (data.containsKey('fat_per_kg')) {
      context.handle(
        _fatPerKgMeta,
        fatPerKg.isAcceptableOrUnknown(data['fat_per_kg']!, _fatPerKgMeta),
      );
    } else if (isInserting) {
      context.missing(_fatPerKgMeta);
    }
    if (data.containsKey('base_energy')) {
      context.handle(
        _baseEnergyMeta,
        baseEnergy.isAcceptableOrUnknown(data['base_energy']!, _baseEnergyMeta),
      );
    } else if (isInserting) {
      context.missing(_baseEnergyMeta);
    }
    if (data.containsKey('schedule')) {
      context.handle(
        _scheduleMeta,
        schedule.isAcceptableOrUnknown(data['schedule']!, _scheduleMeta),
      );
    }
    if (data.containsKey('carb_amplitude_g')) {
      context.handle(
        _carbAmplitudeGMeta,
        carbAmplitudeG.isAcceptableOrUnknown(
          data['carb_amplitude_g']!,
          _carbAmplitudeGMeta,
        ),
      );
    }
    if (data.containsKey('taper_stage')) {
      context.handle(
        _taperStageMeta,
        taperStage.isAcceptableOrUnknown(data['taper_stage']!, _taperStageMeta),
      );
    }
    if (data.containsKey('observation_start')) {
      context.handle(
        _observationStartMeta,
        observationStart.isAcceptableOrUnknown(
          data['observation_start']!,
          _observationStartMeta,
        ),
      );
    }
    if (data.containsKey('observation_days')) {
      context.handle(
        _observationDaysMeta,
        observationDays.isAcceptableOrUnknown(
          data['observation_days']!,
          _observationDaysMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('legacy_calories')) {
      context.handle(
        _legacyCaloriesMeta,
        legacyCalories.isAcceptableOrUnknown(
          data['legacy_calories']!,
          _legacyCaloriesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietStrategyPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietStrategyPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      strategy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strategy'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_from'],
      )!,
      endedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ended_on'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      referenceWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reference_weight_kg'],
      )!,
      estimatedTdee: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_tdee'],
      )!,
      deficitFraction: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deficit_fraction'],
      )!,
      proteinPerKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per_kg'],
      )!,
      fatPerKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per_kg'],
      )!,
      baseEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_energy'],
      )!,
      schedule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule'],
      ),
      carbAmplitudeG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_amplitude_g'],
      ),
      taperStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taper_stage'],
      )!,
      observationStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observation_start'],
      ),
      observationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observation_days'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      legacyCalories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_calories'],
      ),
    );
  }

  @override
  $DietStrategyPlansTable createAlias(String alias) {
    return $DietStrategyPlansTable(attachedDatabase, alias);
  }
}

class DietStrategyPlanRow extends DataClass
    implements Insertable<DietStrategyPlanRow> {
  final int id;
  final int version;
  final String strategy;
  final String status;
  final String effectiveFrom;
  final String? endedOn;
  final DateTime createdAt;
  final double referenceWeightKg;
  final double estimatedTdee;
  final double deficitFraction;
  final double proteinPerKg;
  final double fatPerKg;
  final double baseEnergy;

  /// 7-letter H/M/L code (Mon..Sun) for carb cycling.
  final String? schedule;
  final double? carbAmplitudeG;
  final int taperStage;
  final String? observationStart;
  final int observationDays;
  final String reason;
  final int? legacyCalories;
  const DietStrategyPlanRow({
    required this.id,
    required this.version,
    required this.strategy,
    required this.status,
    required this.effectiveFrom,
    this.endedOn,
    required this.createdAt,
    required this.referenceWeightKg,
    required this.estimatedTdee,
    required this.deficitFraction,
    required this.proteinPerKg,
    required this.fatPerKg,
    required this.baseEnergy,
    this.schedule,
    this.carbAmplitudeG,
    required this.taperStage,
    this.observationStart,
    required this.observationDays,
    required this.reason,
    this.legacyCalories,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['version'] = Variable<int>(version);
    map['strategy'] = Variable<String>(strategy);
    map['status'] = Variable<String>(status);
    map['effective_from'] = Variable<String>(effectiveFrom);
    if (!nullToAbsent || endedOn != null) {
      map['ended_on'] = Variable<String>(endedOn);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['reference_weight_kg'] = Variable<double>(referenceWeightKg);
    map['estimated_tdee'] = Variable<double>(estimatedTdee);
    map['deficit_fraction'] = Variable<double>(deficitFraction);
    map['protein_per_kg'] = Variable<double>(proteinPerKg);
    map['fat_per_kg'] = Variable<double>(fatPerKg);
    map['base_energy'] = Variable<double>(baseEnergy);
    if (!nullToAbsent || schedule != null) {
      map['schedule'] = Variable<String>(schedule);
    }
    if (!nullToAbsent || carbAmplitudeG != null) {
      map['carb_amplitude_g'] = Variable<double>(carbAmplitudeG);
    }
    map['taper_stage'] = Variable<int>(taperStage);
    if (!nullToAbsent || observationStart != null) {
      map['observation_start'] = Variable<String>(observationStart);
    }
    map['observation_days'] = Variable<int>(observationDays);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || legacyCalories != null) {
      map['legacy_calories'] = Variable<int>(legacyCalories);
    }
    return map;
  }

  DietStrategyPlansCompanion toCompanion(bool nullToAbsent) {
    return DietStrategyPlansCompanion(
      id: Value(id),
      version: Value(version),
      strategy: Value(strategy),
      status: Value(status),
      effectiveFrom: Value(effectiveFrom),
      endedOn: endedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endedOn),
      createdAt: Value(createdAt),
      referenceWeightKg: Value(referenceWeightKg),
      estimatedTdee: Value(estimatedTdee),
      deficitFraction: Value(deficitFraction),
      proteinPerKg: Value(proteinPerKg),
      fatPerKg: Value(fatPerKg),
      baseEnergy: Value(baseEnergy),
      schedule: schedule == null && nullToAbsent
          ? const Value.absent()
          : Value(schedule),
      carbAmplitudeG: carbAmplitudeG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbAmplitudeG),
      taperStage: Value(taperStage),
      observationStart: observationStart == null && nullToAbsent
          ? const Value.absent()
          : Value(observationStart),
      observationDays: Value(observationDays),
      reason: Value(reason),
      legacyCalories: legacyCalories == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyCalories),
    );
  }

  factory DietStrategyPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietStrategyPlanRow(
      id: serializer.fromJson<int>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      strategy: serializer.fromJson<String>(json['strategy']),
      status: serializer.fromJson<String>(json['status']),
      effectiveFrom: serializer.fromJson<String>(json['effectiveFrom']),
      endedOn: serializer.fromJson<String?>(json['endedOn']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      referenceWeightKg: serializer.fromJson<double>(json['referenceWeightKg']),
      estimatedTdee: serializer.fromJson<double>(json['estimatedTdee']),
      deficitFraction: serializer.fromJson<double>(json['deficitFraction']),
      proteinPerKg: serializer.fromJson<double>(json['proteinPerKg']),
      fatPerKg: serializer.fromJson<double>(json['fatPerKg']),
      baseEnergy: serializer.fromJson<double>(json['baseEnergy']),
      schedule: serializer.fromJson<String?>(json['schedule']),
      carbAmplitudeG: serializer.fromJson<double?>(json['carbAmplitudeG']),
      taperStage: serializer.fromJson<int>(json['taperStage']),
      observationStart: serializer.fromJson<String?>(json['observationStart']),
      observationDays: serializer.fromJson<int>(json['observationDays']),
      reason: serializer.fromJson<String>(json['reason']),
      legacyCalories: serializer.fromJson<int?>(json['legacyCalories']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'version': serializer.toJson<int>(version),
      'strategy': serializer.toJson<String>(strategy),
      'status': serializer.toJson<String>(status),
      'effectiveFrom': serializer.toJson<String>(effectiveFrom),
      'endedOn': serializer.toJson<String?>(endedOn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'referenceWeightKg': serializer.toJson<double>(referenceWeightKg),
      'estimatedTdee': serializer.toJson<double>(estimatedTdee),
      'deficitFraction': serializer.toJson<double>(deficitFraction),
      'proteinPerKg': serializer.toJson<double>(proteinPerKg),
      'fatPerKg': serializer.toJson<double>(fatPerKg),
      'baseEnergy': serializer.toJson<double>(baseEnergy),
      'schedule': serializer.toJson<String?>(schedule),
      'carbAmplitudeG': serializer.toJson<double?>(carbAmplitudeG),
      'taperStage': serializer.toJson<int>(taperStage),
      'observationStart': serializer.toJson<String?>(observationStart),
      'observationDays': serializer.toJson<int>(observationDays),
      'reason': serializer.toJson<String>(reason),
      'legacyCalories': serializer.toJson<int?>(legacyCalories),
    };
  }

  DietStrategyPlanRow copyWith({
    int? id,
    int? version,
    String? strategy,
    String? status,
    String? effectiveFrom,
    Value<String?> endedOn = const Value.absent(),
    DateTime? createdAt,
    double? referenceWeightKg,
    double? estimatedTdee,
    double? deficitFraction,
    double? proteinPerKg,
    double? fatPerKg,
    double? baseEnergy,
    Value<String?> schedule = const Value.absent(),
    Value<double?> carbAmplitudeG = const Value.absent(),
    int? taperStage,
    Value<String?> observationStart = const Value.absent(),
    int? observationDays,
    String? reason,
    Value<int?> legacyCalories = const Value.absent(),
  }) => DietStrategyPlanRow(
    id: id ?? this.id,
    version: version ?? this.version,
    strategy: strategy ?? this.strategy,
    status: status ?? this.status,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    endedOn: endedOn.present ? endedOn.value : this.endedOn,
    createdAt: createdAt ?? this.createdAt,
    referenceWeightKg: referenceWeightKg ?? this.referenceWeightKg,
    estimatedTdee: estimatedTdee ?? this.estimatedTdee,
    deficitFraction: deficitFraction ?? this.deficitFraction,
    proteinPerKg: proteinPerKg ?? this.proteinPerKg,
    fatPerKg: fatPerKg ?? this.fatPerKg,
    baseEnergy: baseEnergy ?? this.baseEnergy,
    schedule: schedule.present ? schedule.value : this.schedule,
    carbAmplitudeG: carbAmplitudeG.present
        ? carbAmplitudeG.value
        : this.carbAmplitudeG,
    taperStage: taperStage ?? this.taperStage,
    observationStart: observationStart.present
        ? observationStart.value
        : this.observationStart,
    observationDays: observationDays ?? this.observationDays,
    reason: reason ?? this.reason,
    legacyCalories: legacyCalories.present
        ? legacyCalories.value
        : this.legacyCalories,
  );
  DietStrategyPlanRow copyWithCompanion(DietStrategyPlansCompanion data) {
    return DietStrategyPlanRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      strategy: data.strategy.present ? data.strategy.value : this.strategy,
      status: data.status.present ? data.status.value : this.status,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      endedOn: data.endedOn.present ? data.endedOn.value : this.endedOn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      referenceWeightKg: data.referenceWeightKg.present
          ? data.referenceWeightKg.value
          : this.referenceWeightKg,
      estimatedTdee: data.estimatedTdee.present
          ? data.estimatedTdee.value
          : this.estimatedTdee,
      deficitFraction: data.deficitFraction.present
          ? data.deficitFraction.value
          : this.deficitFraction,
      proteinPerKg: data.proteinPerKg.present
          ? data.proteinPerKg.value
          : this.proteinPerKg,
      fatPerKg: data.fatPerKg.present ? data.fatPerKg.value : this.fatPerKg,
      baseEnergy: data.baseEnergy.present
          ? data.baseEnergy.value
          : this.baseEnergy,
      schedule: data.schedule.present ? data.schedule.value : this.schedule,
      carbAmplitudeG: data.carbAmplitudeG.present
          ? data.carbAmplitudeG.value
          : this.carbAmplitudeG,
      taperStage: data.taperStage.present
          ? data.taperStage.value
          : this.taperStage,
      observationStart: data.observationStart.present
          ? data.observationStart.value
          : this.observationStart,
      observationDays: data.observationDays.present
          ? data.observationDays.value
          : this.observationDays,
      reason: data.reason.present ? data.reason.value : this.reason,
      legacyCalories: data.legacyCalories.present
          ? data.legacyCalories.value
          : this.legacyCalories,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietStrategyPlanRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('strategy: $strategy, ')
          ..write('status: $status, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('endedOn: $endedOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('referenceWeightKg: $referenceWeightKg, ')
          ..write('estimatedTdee: $estimatedTdee, ')
          ..write('deficitFraction: $deficitFraction, ')
          ..write('proteinPerKg: $proteinPerKg, ')
          ..write('fatPerKg: $fatPerKg, ')
          ..write('baseEnergy: $baseEnergy, ')
          ..write('schedule: $schedule, ')
          ..write('carbAmplitudeG: $carbAmplitudeG, ')
          ..write('taperStage: $taperStage, ')
          ..write('observationStart: $observationStart, ')
          ..write('observationDays: $observationDays, ')
          ..write('reason: $reason, ')
          ..write('legacyCalories: $legacyCalories')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    version,
    strategy,
    status,
    effectiveFrom,
    endedOn,
    createdAt,
    referenceWeightKg,
    estimatedTdee,
    deficitFraction,
    proteinPerKg,
    fatPerKg,
    baseEnergy,
    schedule,
    carbAmplitudeG,
    taperStage,
    observationStart,
    observationDays,
    reason,
    legacyCalories,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietStrategyPlanRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.strategy == this.strategy &&
          other.status == this.status &&
          other.effectiveFrom == this.effectiveFrom &&
          other.endedOn == this.endedOn &&
          other.createdAt == this.createdAt &&
          other.referenceWeightKg == this.referenceWeightKg &&
          other.estimatedTdee == this.estimatedTdee &&
          other.deficitFraction == this.deficitFraction &&
          other.proteinPerKg == this.proteinPerKg &&
          other.fatPerKg == this.fatPerKg &&
          other.baseEnergy == this.baseEnergy &&
          other.schedule == this.schedule &&
          other.carbAmplitudeG == this.carbAmplitudeG &&
          other.taperStage == this.taperStage &&
          other.observationStart == this.observationStart &&
          other.observationDays == this.observationDays &&
          other.reason == this.reason &&
          other.legacyCalories == this.legacyCalories);
}

class DietStrategyPlansCompanion extends UpdateCompanion<DietStrategyPlanRow> {
  final Value<int> id;
  final Value<int> version;
  final Value<String> strategy;
  final Value<String> status;
  final Value<String> effectiveFrom;
  final Value<String?> endedOn;
  final Value<DateTime> createdAt;
  final Value<double> referenceWeightKg;
  final Value<double> estimatedTdee;
  final Value<double> deficitFraction;
  final Value<double> proteinPerKg;
  final Value<double> fatPerKg;
  final Value<double> baseEnergy;
  final Value<String?> schedule;
  final Value<double?> carbAmplitudeG;
  final Value<int> taperStage;
  final Value<String?> observationStart;
  final Value<int> observationDays;
  final Value<String> reason;
  final Value<int?> legacyCalories;
  const DietStrategyPlansCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.strategy = const Value.absent(),
    this.status = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.endedOn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.referenceWeightKg = const Value.absent(),
    this.estimatedTdee = const Value.absent(),
    this.deficitFraction = const Value.absent(),
    this.proteinPerKg = const Value.absent(),
    this.fatPerKg = const Value.absent(),
    this.baseEnergy = const Value.absent(),
    this.schedule = const Value.absent(),
    this.carbAmplitudeG = const Value.absent(),
    this.taperStage = const Value.absent(),
    this.observationStart = const Value.absent(),
    this.observationDays = const Value.absent(),
    this.reason = const Value.absent(),
    this.legacyCalories = const Value.absent(),
  });
  DietStrategyPlansCompanion.insert({
    this.id = const Value.absent(),
    required int version,
    required String strategy,
    required String status,
    required String effectiveFrom,
    this.endedOn = const Value.absent(),
    required DateTime createdAt,
    required double referenceWeightKg,
    required double estimatedTdee,
    required double deficitFraction,
    required double proteinPerKg,
    required double fatPerKg,
    required double baseEnergy,
    this.schedule = const Value.absent(),
    this.carbAmplitudeG = const Value.absent(),
    this.taperStage = const Value.absent(),
    this.observationStart = const Value.absent(),
    this.observationDays = const Value.absent(),
    this.reason = const Value.absent(),
    this.legacyCalories = const Value.absent(),
  }) : version = Value(version),
       strategy = Value(strategy),
       status = Value(status),
       effectiveFrom = Value(effectiveFrom),
       createdAt = Value(createdAt),
       referenceWeightKg = Value(referenceWeightKg),
       estimatedTdee = Value(estimatedTdee),
       deficitFraction = Value(deficitFraction),
       proteinPerKg = Value(proteinPerKg),
       fatPerKg = Value(fatPerKg),
       baseEnergy = Value(baseEnergy);
  static Insertable<DietStrategyPlanRow> custom({
    Expression<int>? id,
    Expression<int>? version,
    Expression<String>? strategy,
    Expression<String>? status,
    Expression<String>? effectiveFrom,
    Expression<String>? endedOn,
    Expression<DateTime>? createdAt,
    Expression<double>? referenceWeightKg,
    Expression<double>? estimatedTdee,
    Expression<double>? deficitFraction,
    Expression<double>? proteinPerKg,
    Expression<double>? fatPerKg,
    Expression<double>? baseEnergy,
    Expression<String>? schedule,
    Expression<double>? carbAmplitudeG,
    Expression<int>? taperStage,
    Expression<String>? observationStart,
    Expression<int>? observationDays,
    Expression<String>? reason,
    Expression<int>? legacyCalories,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (strategy != null) 'strategy': strategy,
      if (status != null) 'status': status,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (endedOn != null) 'ended_on': endedOn,
      if (createdAt != null) 'created_at': createdAt,
      if (referenceWeightKg != null) 'reference_weight_kg': referenceWeightKg,
      if (estimatedTdee != null) 'estimated_tdee': estimatedTdee,
      if (deficitFraction != null) 'deficit_fraction': deficitFraction,
      if (proteinPerKg != null) 'protein_per_kg': proteinPerKg,
      if (fatPerKg != null) 'fat_per_kg': fatPerKg,
      if (baseEnergy != null) 'base_energy': baseEnergy,
      if (schedule != null) 'schedule': schedule,
      if (carbAmplitudeG != null) 'carb_amplitude_g': carbAmplitudeG,
      if (taperStage != null) 'taper_stage': taperStage,
      if (observationStart != null) 'observation_start': observationStart,
      if (observationDays != null) 'observation_days': observationDays,
      if (reason != null) 'reason': reason,
      if (legacyCalories != null) 'legacy_calories': legacyCalories,
    });
  }

  DietStrategyPlansCompanion copyWith({
    Value<int>? id,
    Value<int>? version,
    Value<String>? strategy,
    Value<String>? status,
    Value<String>? effectiveFrom,
    Value<String?>? endedOn,
    Value<DateTime>? createdAt,
    Value<double>? referenceWeightKg,
    Value<double>? estimatedTdee,
    Value<double>? deficitFraction,
    Value<double>? proteinPerKg,
    Value<double>? fatPerKg,
    Value<double>? baseEnergy,
    Value<String?>? schedule,
    Value<double?>? carbAmplitudeG,
    Value<int>? taperStage,
    Value<String?>? observationStart,
    Value<int>? observationDays,
    Value<String>? reason,
    Value<int?>? legacyCalories,
  }) {
    return DietStrategyPlansCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      strategy: strategy ?? this.strategy,
      status: status ?? this.status,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      endedOn: endedOn ?? this.endedOn,
      createdAt: createdAt ?? this.createdAt,
      referenceWeightKg: referenceWeightKg ?? this.referenceWeightKg,
      estimatedTdee: estimatedTdee ?? this.estimatedTdee,
      deficitFraction: deficitFraction ?? this.deficitFraction,
      proteinPerKg: proteinPerKg ?? this.proteinPerKg,
      fatPerKg: fatPerKg ?? this.fatPerKg,
      baseEnergy: baseEnergy ?? this.baseEnergy,
      schedule: schedule ?? this.schedule,
      carbAmplitudeG: carbAmplitudeG ?? this.carbAmplitudeG,
      taperStage: taperStage ?? this.taperStage,
      observationStart: observationStart ?? this.observationStart,
      observationDays: observationDays ?? this.observationDays,
      reason: reason ?? this.reason,
      legacyCalories: legacyCalories ?? this.legacyCalories,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (strategy.present) {
      map['strategy'] = Variable<String>(strategy.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<String>(effectiveFrom.value);
    }
    if (endedOn.present) {
      map['ended_on'] = Variable<String>(endedOn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (referenceWeightKg.present) {
      map['reference_weight_kg'] = Variable<double>(referenceWeightKg.value);
    }
    if (estimatedTdee.present) {
      map['estimated_tdee'] = Variable<double>(estimatedTdee.value);
    }
    if (deficitFraction.present) {
      map['deficit_fraction'] = Variable<double>(deficitFraction.value);
    }
    if (proteinPerKg.present) {
      map['protein_per_kg'] = Variable<double>(proteinPerKg.value);
    }
    if (fatPerKg.present) {
      map['fat_per_kg'] = Variable<double>(fatPerKg.value);
    }
    if (baseEnergy.present) {
      map['base_energy'] = Variable<double>(baseEnergy.value);
    }
    if (schedule.present) {
      map['schedule'] = Variable<String>(schedule.value);
    }
    if (carbAmplitudeG.present) {
      map['carb_amplitude_g'] = Variable<double>(carbAmplitudeG.value);
    }
    if (taperStage.present) {
      map['taper_stage'] = Variable<int>(taperStage.value);
    }
    if (observationStart.present) {
      map['observation_start'] = Variable<String>(observationStart.value);
    }
    if (observationDays.present) {
      map['observation_days'] = Variable<int>(observationDays.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (legacyCalories.present) {
      map['legacy_calories'] = Variable<int>(legacyCalories.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietStrategyPlansCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('strategy: $strategy, ')
          ..write('status: $status, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('endedOn: $endedOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('referenceWeightKg: $referenceWeightKg, ')
          ..write('estimatedTdee: $estimatedTdee, ')
          ..write('deficitFraction: $deficitFraction, ')
          ..write('proteinPerKg: $proteinPerKg, ')
          ..write('fatPerKg: $fatPerKg, ')
          ..write('baseEnergy: $baseEnergy, ')
          ..write('schedule: $schedule, ')
          ..write('carbAmplitudeG: $carbAmplitudeG, ')
          ..write('taperStage: $taperStage, ')
          ..write('observationStart: $observationStart, ')
          ..write('observationDays: $observationDays, ')
          ..write('reason: $reason, ')
          ..write('legacyCalories: $legacyCalories')
          ..write(')'))
        .toString();
  }
}

class $DailyNutritionTargetsTable extends DailyNutritionTargets
    with TableInfo<$DailyNutritionTargetsTable, DailyNutritionTargetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyNutritionTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planVersionMeta = const VerificationMeta(
    'planVersion',
  );
  @override
  late final GeneratedColumn<int> planVersion = GeneratedColumn<int>(
    'plan_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strategyMeta = const VerificationMeta(
    'strategy',
  );
  @override
  late final GeneratedColumn<String> strategy = GeneratedColumn<String>(
    'strategy',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayTypeMeta = const VerificationMeta(
    'dayType',
  );
  @override
  late final GeneratedColumn<String> dayType = GeneratedColumn<String>(
    'day_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
    'carb_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimatedTdeeMeta = const VerificationMeta(
    'estimatedTdee',
  );
  @override
  late final GeneratedColumn<double> estimatedTdee = GeneratedColumn<double>(
    'estimated_tdee',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('confirmed'),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    planId,
    planVersion,
    strategy,
    dayType,
    calories,
    proteinG,
    carbG,
    fatG,
    estimatedTdee,
    source,
    status,
    reason,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_nutrition_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyNutritionTargetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    }
    if (data.containsKey('plan_version')) {
      context.handle(
        _planVersionMeta,
        planVersion.isAcceptableOrUnknown(
          data['plan_version']!,
          _planVersionMeta,
        ),
      );
    }
    if (data.containsKey('strategy')) {
      context.handle(
        _strategyMeta,
        strategy.isAcceptableOrUnknown(data['strategy']!, _strategyMeta),
      );
    }
    if (data.containsKey('day_type')) {
      context.handle(
        _dayTypeMeta,
        dayType.isAcceptableOrUnknown(data['day_type']!, _dayTypeMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carb_g')) {
      context.handle(
        _carbGMeta,
        carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('estimated_tdee')) {
      context.handle(
        _estimatedTdeeMeta,
        estimatedTdee.isAcceptableOrUnknown(
          data['estimated_tdee']!,
          _estimatedTdeeMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyNutritionTargetRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyNutritionTargetRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      ),
      planVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_version'],
      ),
      strategy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strategy'],
      ),
      dayType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_type'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      estimatedTdee: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_tdee'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DailyNutritionTargetsTable createAlias(String alias) {
    return $DailyNutritionTargetsTable(attachedDatabase, alias);
  }
}

class DailyNutritionTargetRow extends DataClass
    implements Insertable<DailyNutritionTargetRow> {
  final String date;
  final int? planId;
  final int? planVersion;
  final String? strategy;
  final String? dayType;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double? estimatedTdee;
  final String source;
  final String status;
  final String? reason;
  final DateTime updatedAt;
  const DailyNutritionTargetRow({
    required this.date,
    this.planId,
    this.planVersion,
    this.strategy,
    this.dayType,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.estimatedTdee,
    required this.source,
    required this.status,
    this.reason,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<int>(planId);
    }
    if (!nullToAbsent || planVersion != null) {
      map['plan_version'] = Variable<int>(planVersion);
    }
    if (!nullToAbsent || strategy != null) {
      map['strategy'] = Variable<String>(strategy);
    }
    if (!nullToAbsent || dayType != null) {
      map['day_type'] = Variable<String>(dayType);
    }
    map['calories'] = Variable<double>(calories);
    map['protein_g'] = Variable<double>(proteinG);
    map['carb_g'] = Variable<double>(carbG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || estimatedTdee != null) {
      map['estimated_tdee'] = Variable<double>(estimatedTdee);
    }
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyNutritionTargetsCompanion toCompanion(bool nullToAbsent) {
    return DailyNutritionTargetsCompanion(
      date: Value(date),
      planId: planId == null && nullToAbsent
          ? const Value.absent()
          : Value(planId),
      planVersion: planVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(planVersion),
      strategy: strategy == null && nullToAbsent
          ? const Value.absent()
          : Value(strategy),
      dayType: dayType == null && nullToAbsent
          ? const Value.absent()
          : Value(dayType),
      calories: Value(calories),
      proteinG: Value(proteinG),
      carbG: Value(carbG),
      fatG: Value(fatG),
      estimatedTdee: estimatedTdee == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedTdee),
      source: Value(source),
      status: Value(status),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyNutritionTargetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyNutritionTargetRow(
      date: serializer.fromJson<String>(json['date']),
      planId: serializer.fromJson<int?>(json['planId']),
      planVersion: serializer.fromJson<int?>(json['planVersion']),
      strategy: serializer.fromJson<String?>(json['strategy']),
      dayType: serializer.fromJson<String?>(json['dayType']),
      calories: serializer.fromJson<double>(json['calories']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbG: serializer.fromJson<double>(json['carbG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      estimatedTdee: serializer.fromJson<double?>(json['estimatedTdee']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      reason: serializer.fromJson<String?>(json['reason']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'planId': serializer.toJson<int?>(planId),
      'planVersion': serializer.toJson<int?>(planVersion),
      'strategy': serializer.toJson<String?>(strategy),
      'dayType': serializer.toJson<String?>(dayType),
      'calories': serializer.toJson<double>(calories),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbG': serializer.toJson<double>(carbG),
      'fatG': serializer.toJson<double>(fatG),
      'estimatedTdee': serializer.toJson<double?>(estimatedTdee),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'reason': serializer.toJson<String?>(reason),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyNutritionTargetRow copyWith({
    String? date,
    Value<int?> planId = const Value.absent(),
    Value<int?> planVersion = const Value.absent(),
    Value<String?> strategy = const Value.absent(),
    Value<String?> dayType = const Value.absent(),
    double? calories,
    double? proteinG,
    double? carbG,
    double? fatG,
    Value<double?> estimatedTdee = const Value.absent(),
    String? source,
    String? status,
    Value<String?> reason = const Value.absent(),
    DateTime? updatedAt,
  }) => DailyNutritionTargetRow(
    date: date ?? this.date,
    planId: planId.present ? planId.value : this.planId,
    planVersion: planVersion.present ? planVersion.value : this.planVersion,
    strategy: strategy.present ? strategy.value : this.strategy,
    dayType: dayType.present ? dayType.value : this.dayType,
    calories: calories ?? this.calories,
    proteinG: proteinG ?? this.proteinG,
    carbG: carbG ?? this.carbG,
    fatG: fatG ?? this.fatG,
    estimatedTdee: estimatedTdee.present
        ? estimatedTdee.value
        : this.estimatedTdee,
    source: source ?? this.source,
    status: status ?? this.status,
    reason: reason.present ? reason.value : this.reason,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyNutritionTargetRow copyWithCompanion(
    DailyNutritionTargetsCompanion data,
  ) {
    return DailyNutritionTargetRow(
      date: data.date.present ? data.date.value : this.date,
      planId: data.planId.present ? data.planId.value : this.planId,
      planVersion: data.planVersion.present
          ? data.planVersion.value
          : this.planVersion,
      strategy: data.strategy.present ? data.strategy.value : this.strategy,
      dayType: data.dayType.present ? data.dayType.value : this.dayType,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      estimatedTdee: data.estimatedTdee.present
          ? data.estimatedTdee.value
          : this.estimatedTdee,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      reason: data.reason.present ? data.reason.value : this.reason,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionTargetRow(')
          ..write('date: $date, ')
          ..write('planId: $planId, ')
          ..write('planVersion: $planVersion, ')
          ..write('strategy: $strategy, ')
          ..write('dayType: $dayType, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('estimatedTdee: $estimatedTdee, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('reason: $reason, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    planId,
    planVersion,
    strategy,
    dayType,
    calories,
    proteinG,
    carbG,
    fatG,
    estimatedTdee,
    source,
    status,
    reason,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNutritionTargetRow &&
          other.date == this.date &&
          other.planId == this.planId &&
          other.planVersion == this.planVersion &&
          other.strategy == this.strategy &&
          other.dayType == this.dayType &&
          other.calories == this.calories &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.estimatedTdee == this.estimatedTdee &&
          other.source == this.source &&
          other.status == this.status &&
          other.reason == this.reason &&
          other.updatedAt == this.updatedAt);
}

class DailyNutritionTargetsCompanion
    extends UpdateCompanion<DailyNutritionTargetRow> {
  final Value<String> date;
  final Value<int?> planId;
  final Value<int?> planVersion;
  final Value<String?> strategy;
  final Value<String?> dayType;
  final Value<double> calories;
  final Value<double> proteinG;
  final Value<double> carbG;
  final Value<double> fatG;
  final Value<double?> estimatedTdee;
  final Value<String> source;
  final Value<String> status;
  final Value<String?> reason;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyNutritionTargetsCompanion({
    this.date = const Value.absent(),
    this.planId = const Value.absent(),
    this.planVersion = const Value.absent(),
    this.strategy = const Value.absent(),
    this.dayType = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.estimatedTdee = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.reason = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyNutritionTargetsCompanion.insert({
    required String date,
    this.planId = const Value.absent(),
    this.planVersion = const Value.absent(),
    this.strategy = const Value.absent(),
    this.dayType = const Value.absent(),
    required double calories,
    required double proteinG,
    required double carbG,
    required double fatG,
    this.estimatedTdee = const Value.absent(),
    required String source,
    this.status = const Value.absent(),
    this.reason = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       calories = Value(calories),
       proteinG = Value(proteinG),
       carbG = Value(carbG),
       fatG = Value(fatG),
       source = Value(source),
       updatedAt = Value(updatedAt);
  static Insertable<DailyNutritionTargetRow> custom({
    Expression<String>? date,
    Expression<int>? planId,
    Expression<int>? planVersion,
    Expression<String>? strategy,
    Expression<String>? dayType,
    Expression<double>? calories,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<double>? estimatedTdee,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? reason,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (planId != null) 'plan_id': planId,
      if (planVersion != null) 'plan_version': planVersion,
      if (strategy != null) 'strategy': strategy,
      if (dayType != null) 'day_type': dayType,
      if (calories != null) 'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (estimatedTdee != null) 'estimated_tdee': estimatedTdee,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (reason != null) 'reason': reason,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyNutritionTargetsCompanion copyWith({
    Value<String>? date,
    Value<int?>? planId,
    Value<int?>? planVersion,
    Value<String?>? strategy,
    Value<String?>? dayType,
    Value<double>? calories,
    Value<double>? proteinG,
    Value<double>? carbG,
    Value<double>? fatG,
    Value<double?>? estimatedTdee,
    Value<String>? source,
    Value<String>? status,
    Value<String?>? reason,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DailyNutritionTargetsCompanion(
      date: date ?? this.date,
      planId: planId ?? this.planId,
      planVersion: planVersion ?? this.planVersion,
      strategy: strategy ?? this.strategy,
      dayType: dayType ?? this.dayType,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      estimatedTdee: estimatedTdee ?? this.estimatedTdee,
      source: source ?? this.source,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (planVersion.present) {
      map['plan_version'] = Variable<int>(planVersion.value);
    }
    if (strategy.present) {
      map['strategy'] = Variable<String>(strategy.value);
    }
    if (dayType.present) {
      map['day_type'] = Variable<String>(dayType.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (estimatedTdee.present) {
      map['estimated_tdee'] = Variable<double>(estimatedTdee.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionTargetsCompanion(')
          ..write('date: $date, ')
          ..write('planId: $planId, ')
          ..write('planVersion: $planVersion, ')
          ..write('strategy: $strategy, ')
          ..write('dayType: $dayType, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('estimatedTdee: $estimatedTdee, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('reason: $reason, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayDietConfirmationsTable extends DayDietConfirmations
    with TableInfo<$DayDietConfirmationsTable, DayDietConfirmationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayDietConfirmationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, complete, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_diet_confirmations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayDietConfirmationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    } else if (isInserting) {
      context.missing(_completeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayDietConfirmationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayDietConfirmationRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DayDietConfirmationsTable createAlias(String alias) {
    return $DayDietConfirmationsTable(attachedDatabase, alias);
  }
}

class DayDietConfirmationRow extends DataClass
    implements Insertable<DayDietConfirmationRow> {
  final String date;
  final bool complete;
  final DateTime updatedAt;
  const DayDietConfirmationRow({
    required this.date,
    required this.complete,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['complete'] = Variable<bool>(complete);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DayDietConfirmationsCompanion toCompanion(bool nullToAbsent) {
    return DayDietConfirmationsCompanion(
      date: Value(date),
      complete: Value(complete),
      updatedAt: Value(updatedAt),
    );
  }

  factory DayDietConfirmationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayDietConfirmationRow(
      date: serializer.fromJson<String>(json['date']),
      complete: serializer.fromJson<bool>(json['complete']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'complete': serializer.toJson<bool>(complete),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DayDietConfirmationRow copyWith({
    String? date,
    bool? complete,
    DateTime? updatedAt,
  }) => DayDietConfirmationRow(
    date: date ?? this.date,
    complete: complete ?? this.complete,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DayDietConfirmationRow copyWithCompanion(DayDietConfirmationsCompanion data) {
    return DayDietConfirmationRow(
      date: data.date.present ? data.date.value : this.date,
      complete: data.complete.present ? data.complete.value : this.complete,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayDietConfirmationRow(')
          ..write('date: $date, ')
          ..write('complete: $complete, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, complete, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayDietConfirmationRow &&
          other.date == this.date &&
          other.complete == this.complete &&
          other.updatedAt == this.updatedAt);
}

class DayDietConfirmationsCompanion
    extends UpdateCompanion<DayDietConfirmationRow> {
  final Value<String> date;
  final Value<bool> complete;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DayDietConfirmationsCompanion({
    this.date = const Value.absent(),
    this.complete = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayDietConfirmationsCompanion.insert({
    required String date,
    required bool complete,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       complete = Value(complete),
       updatedAt = Value(updatedAt);
  static Insertable<DayDietConfirmationRow> custom({
    Expression<String>? date,
    Expression<bool>? complete,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (complete != null) 'complete': complete,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayDietConfirmationsCompanion copyWith({
    Value<String>? date,
    Value<bool>? complete,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DayDietConfirmationsCompanion(
      date: date ?? this.date,
      complete: complete ?? this.complete,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayDietConfirmationsCompanion(')
          ..write('date: $date, ')
          ..write('complete: $complete, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodItemsTable foodItems = $FoodItemsTable(this);
  late final $FoodServingsTable foodServings = $FoodServingsTable(this);
  late final $FavoriteFoodsTable favoriteFoods = $FavoriteFoodsTable(this);
  late final $WeightLogsTable weightLogs = $WeightLogsTable(this);
  late final $MealEntriesTable mealEntries = $MealEntriesTable(this);
  late final $MealPresetsTable mealPresets = $MealPresetsTable(this);
  late final $MealPresetItemsTable mealPresetItems = $MealPresetItemsTable(
    this,
  );
  late final $WaterLogsTable waterLogs = $WaterLogsTable(this);
  late final $StepLogsTable stepLogs = $StepLogsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutPlansTable workoutPlans = $WorkoutPlansTable(this);
  late final $WorkoutPlanItemsTable workoutPlanItems = $WorkoutPlanItemsTable(
    this,
  );
  late final $DayWorkoutsTable dayWorkouts = $DayWorkoutsTable(this);
  late final $DayWorkoutItemsTable dayWorkoutItems = $DayWorkoutItemsTable(
    this,
  );
  late final $WorkoutSetLogsTable workoutSetLogs = $WorkoutSetLogsTable(this);
  late final $DailyNotesTable dailyNotes = $DailyNotesTable(this);
  late final $DietStrategyPlansTable dietStrategyPlans =
      $DietStrategyPlansTable(this);
  late final $DailyNutritionTargetsTable dailyNutritionTargets =
      $DailyNutritionTargetsTable(this);
  late final $DayDietConfirmationsTable dayDietConfirmations =
      $DayDietConfirmationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodItems,
    foodServings,
    favoriteFoods,
    weightLogs,
    mealEntries,
    mealPresets,
    mealPresetItems,
    waterLogs,
    stepLogs,
    appMeta,
    exercises,
    workoutPlans,
    workoutPlanItems,
    dayWorkouts,
    dayWorkoutItems,
    workoutSetLogs,
    dailyNotes,
    dietStrategyPlans,
    dailyNutritionTargets,
    dayDietConfirmations,
  ];
}

typedef $$FoodItemsTableCreateCompanionBuilder =
    FoodItemsCompanion Function({
      Value<int> id,
      required String name,
      required String category,
      required double kcalPer100,
      required double proteinPer100,
      required double carbPer100,
      required double fatPer100,
      Value<double> alcoholPer100,
      Value<double> fiberPer100,
      Value<double> sodiumMgPer100,
      Value<double> sugarPer100,
      Value<double> saturatedFatPer100,
      Value<double> calciumMgPer100,
      Value<bool> isCustom,
    });
typedef $$FoodItemsTableUpdateCompanionBuilder =
    FoodItemsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> category,
      Value<double> kcalPer100,
      Value<double> proteinPer100,
      Value<double> carbPer100,
      Value<double> fatPer100,
      Value<double> alcoholPer100,
      Value<double> fiberPer100,
      Value<double> sodiumMgPer100,
      Value<double> sugarPer100,
      Value<double> saturatedFatPer100,
      Value<double> calciumMgPer100,
      Value<bool> isCustom,
    });

class $$FoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbPer100 => $composableBuilder(
    column: $table.carbPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100 => $composableBuilder(
    column: $table.fatPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alcoholPer100 => $composableBuilder(
    column: $table.alcoholPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberPer100 => $composableBuilder(
    column: $table.fiberPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMgPer100 => $composableBuilder(
    column: $table.sodiumMgPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarPer100 => $composableBuilder(
    column: $table.sugarPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saturatedFatPer100 => $composableBuilder(
    column: $table.saturatedFatPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calciumMgPer100 => $composableBuilder(
    column: $table.calciumMgPer100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbPer100 => $composableBuilder(
    column: $table.carbPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100 => $composableBuilder(
    column: $table.fatPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alcoholPer100 => $composableBuilder(
    column: $table.alcoholPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberPer100 => $composableBuilder(
    column: $table.fiberPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMgPer100 => $composableBuilder(
    column: $table.sodiumMgPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarPer100 => $composableBuilder(
    column: $table.sugarPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saturatedFatPer100 => $composableBuilder(
    column: $table.saturatedFatPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calciumMgPer100 => $composableBuilder(
    column: $table.calciumMgPer100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbPer100 => $composableBuilder(
    column: $table.carbPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100 =>
      $composableBuilder(column: $table.fatPer100, builder: (column) => column);

  GeneratedColumn<double> get alcoholPer100 => $composableBuilder(
    column: $table.alcoholPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fiberPer100 => $composableBuilder(
    column: $table.fiberPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sodiumMgPer100 => $composableBuilder(
    column: $table.sodiumMgPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sugarPer100 => $composableBuilder(
    column: $table.sugarPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get saturatedFatPer100 => $composableBuilder(
    column: $table.saturatedFatPer100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calciumMgPer100 => $composableBuilder(
    column: $table.calciumMgPer100,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);
}

class $$FoodItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodItemsTable,
          FoodItem,
          $$FoodItemsTableFilterComposer,
          $$FoodItemsTableOrderingComposer,
          $$FoodItemsTableAnnotationComposer,
          $$FoodItemsTableCreateCompanionBuilder,
          $$FoodItemsTableUpdateCompanionBuilder,
          (FoodItem, BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem>),
          FoodItem,
          PrefetchHooks Function()
        > {
  $$FoodItemsTableTableManager(_$AppDatabase db, $FoodItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> kcalPer100 = const Value.absent(),
                Value<double> proteinPer100 = const Value.absent(),
                Value<double> carbPer100 = const Value.absent(),
                Value<double> fatPer100 = const Value.absent(),
                Value<double> alcoholPer100 = const Value.absent(),
                Value<double> fiberPer100 = const Value.absent(),
                Value<double> sodiumMgPer100 = const Value.absent(),
                Value<double> sugarPer100 = const Value.absent(),
                Value<double> saturatedFatPer100 = const Value.absent(),
                Value<double> calciumMgPer100 = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
              }) => FoodItemsCompanion(
                id: id,
                name: name,
                category: category,
                kcalPer100: kcalPer100,
                proteinPer100: proteinPer100,
                carbPer100: carbPer100,
                fatPer100: fatPer100,
                alcoholPer100: alcoholPer100,
                fiberPer100: fiberPer100,
                sodiumMgPer100: sodiumMgPer100,
                sugarPer100: sugarPer100,
                saturatedFatPer100: saturatedFatPer100,
                calciumMgPer100: calciumMgPer100,
                isCustom: isCustom,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String category,
                required double kcalPer100,
                required double proteinPer100,
                required double carbPer100,
                required double fatPer100,
                Value<double> alcoholPer100 = const Value.absent(),
                Value<double> fiberPer100 = const Value.absent(),
                Value<double> sodiumMgPer100 = const Value.absent(),
                Value<double> sugarPer100 = const Value.absent(),
                Value<double> saturatedFatPer100 = const Value.absent(),
                Value<double> calciumMgPer100 = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
              }) => FoodItemsCompanion.insert(
                id: id,
                name: name,
                category: category,
                kcalPer100: kcalPer100,
                proteinPer100: proteinPer100,
                carbPer100: carbPer100,
                fatPer100: fatPer100,
                alcoholPer100: alcoholPer100,
                fiberPer100: fiberPer100,
                sodiumMgPer100: sodiumMgPer100,
                sugarPer100: sugarPer100,
                saturatedFatPer100: saturatedFatPer100,
                calciumMgPer100: calciumMgPer100,
                isCustom: isCustom,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodItemsTable,
      FoodItem,
      $$FoodItemsTableFilterComposer,
      $$FoodItemsTableOrderingComposer,
      $$FoodItemsTableAnnotationComposer,
      $$FoodItemsTableCreateCompanionBuilder,
      $$FoodItemsTableUpdateCompanionBuilder,
      (FoodItem, BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem>),
      FoodItem,
      PrefetchHooks Function()
    >;
typedef $$FoodServingsTableCreateCompanionBuilder =
    FoodServingsCompanion Function({
      Value<int> id,
      required int foodId,
      required String label,
      required double grams,
    });
typedef $$FoodServingsTableUpdateCompanionBuilder =
    FoodServingsCompanion Function({
      Value<int> id,
      Value<int> foodId,
      Value<String> label,
      Value<double> grams,
    });

class $$FoodServingsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodServingsTable> {
  $$FoodServingsTableFilterComposer({
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

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodServingsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodServingsTable> {
  $$FoodServingsTableOrderingComposer({
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

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodServingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodServingsTable> {
  $$FoodServingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);
}

class $$FoodServingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodServingsTable,
          FoodServing,
          $$FoodServingsTableFilterComposer,
          $$FoodServingsTableOrderingComposer,
          $$FoodServingsTableAnnotationComposer,
          $$FoodServingsTableCreateCompanionBuilder,
          $$FoodServingsTableUpdateCompanionBuilder,
          (
            FoodServing,
            BaseReferences<_$AppDatabase, $FoodServingsTable, FoodServing>,
          ),
          FoodServing,
          PrefetchHooks Function()
        > {
  $$FoodServingsTableTableManager(_$AppDatabase db, $FoodServingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodServingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodServingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodServingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> grams = const Value.absent(),
              }) => FoodServingsCompanion(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int foodId,
                required String label,
                required double grams,
              }) => FoodServingsCompanion.insert(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodServingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodServingsTable,
      FoodServing,
      $$FoodServingsTableFilterComposer,
      $$FoodServingsTableOrderingComposer,
      $$FoodServingsTableAnnotationComposer,
      $$FoodServingsTableCreateCompanionBuilder,
      $$FoodServingsTableUpdateCompanionBuilder,
      (
        FoodServing,
        BaseReferences<_$AppDatabase, $FoodServingsTable, FoodServing>,
      ),
      FoodServing,
      PrefetchHooks Function()
    >;
typedef $$FavoriteFoodsTableCreateCompanionBuilder =
    FavoriteFoodsCompanion Function({
      Value<int> foodId,
      required DateTime createdAt,
    });
typedef $$FavoriteFoodsTableUpdateCompanionBuilder =
    FavoriteFoodsCompanion Function({
      Value<int> foodId,
      Value<DateTime> createdAt,
    });

class $$FavoriteFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoriteFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoriteFoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteFoodsTable,
          FavoriteFood,
          $$FavoriteFoodsTableFilterComposer,
          $$FavoriteFoodsTableOrderingComposer,
          $$FavoriteFoodsTableAnnotationComposer,
          $$FavoriteFoodsTableCreateCompanionBuilder,
          $$FavoriteFoodsTableUpdateCompanionBuilder,
          (
            FavoriteFood,
            BaseReferences<_$AppDatabase, $FavoriteFoodsTable, FavoriteFood>,
          ),
          FavoriteFood,
          PrefetchHooks Function()
        > {
  $$FavoriteFoodsTableTableManager(_$AppDatabase db, $FavoriteFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> foodId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) =>
                  FavoriteFoodsCompanion(foodId: foodId, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> foodId = const Value.absent(),
                required DateTime createdAt,
              }) => FavoriteFoodsCompanion.insert(
                foodId: foodId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteFoodsTable,
      FavoriteFood,
      $$FavoriteFoodsTableFilterComposer,
      $$FavoriteFoodsTableOrderingComposer,
      $$FavoriteFoodsTableAnnotationComposer,
      $$FavoriteFoodsTableCreateCompanionBuilder,
      $$FavoriteFoodsTableUpdateCompanionBuilder,
      (
        FavoriteFood,
        BaseReferences<_$AppDatabase, $FavoriteFoodsTable, FavoriteFood>,
      ),
      FavoriteFood,
      PrefetchHooks Function()
    >;
typedef $$WeightLogsTableCreateCompanionBuilder =
    WeightLogsCompanion Function({
      Value<int> id,
      required DateTime date,
      required double weightKg,
      Value<double?> bodyFatPct,
      Value<int?> exerciseMinutes,
    });
typedef $$WeightLogsTableUpdateCompanionBuilder =
    WeightLogsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<double> weightKg,
      Value<double?> bodyFatPct,
      Value<int?> exerciseMinutes,
    });

class $$WeightLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseMinutes => $composableBuilder(
    column: $table.exerciseMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseMinutes => $composableBuilder(
    column: $table.exerciseMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exerciseMinutes => $composableBuilder(
    column: $table.exerciseMinutes,
    builder: (column) => column,
  );
}

class $$WeightLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightLogsTable,
          WeightLog,
          $$WeightLogsTableFilterComposer,
          $$WeightLogsTableOrderingComposer,
          $$WeightLogsTableAnnotationComposer,
          $$WeightLogsTableCreateCompanionBuilder,
          $$WeightLogsTableUpdateCompanionBuilder,
          (
            WeightLog,
            BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLog>,
          ),
          WeightLog,
          PrefetchHooks Function()
        > {
  $$WeightLogsTableTableManager(_$AppDatabase db, $WeightLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<int?> exerciseMinutes = const Value.absent(),
              }) => WeightLogsCompanion(
                id: id,
                date: date,
                weightKg: weightKg,
                bodyFatPct: bodyFatPct,
                exerciseMinutes: exerciseMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required double weightKg,
                Value<double?> bodyFatPct = const Value.absent(),
                Value<int?> exerciseMinutes = const Value.absent(),
              }) => WeightLogsCompanion.insert(
                id: id,
                date: date,
                weightKg: weightKg,
                bodyFatPct: bodyFatPct,
                exerciseMinutes: exerciseMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightLogsTable,
      WeightLog,
      $$WeightLogsTableFilterComposer,
      $$WeightLogsTableOrderingComposer,
      $$WeightLogsTableAnnotationComposer,
      $$WeightLogsTableCreateCompanionBuilder,
      $$WeightLogsTableUpdateCompanionBuilder,
      (WeightLog, BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLog>),
      WeightLog,
      PrefetchHooks Function()
    >;
typedef $$MealEntriesTableCreateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required String mealType,
      required int foodId,
      required String foodName,
      required double grams,
      required double calories,
      required double proteinG,
      required double carbG,
      required double fatG,
      Value<double> alcoholG,
      Value<double> fiberG,
      Value<double> sodiumMg,
      Value<double> sugarG,
      Value<double> saturatedFatG,
      Value<double> calciumMg,
    });
typedef $$MealEntriesTableUpdateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> mealType,
      Value<int> foodId,
      Value<String> foodName,
      Value<double> grams,
      Value<double> calories,
      Value<double> proteinG,
      Value<double> carbG,
      Value<double> fatG,
      Value<double> alcoholG,
      Value<double> fiberG,
      Value<double> sodiumMg,
      Value<double> sugarG,
      Value<double> saturatedFatG,
      Value<double> calciumMg,
    });

class $$MealEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alcoholG => $composableBuilder(
    column: $table.alcoholG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saturatedFatG => $composableBuilder(
    column: $table.saturatedFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alcoholG => $composableBuilder(
    column: $table.alcoholG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saturatedFatG => $composableBuilder(
    column: $table.saturatedFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get alcoholG =>
      $composableBuilder(column: $table.alcoholG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get saturatedFatG => $composableBuilder(
    column: $table.saturatedFatG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calciumMg =>
      $composableBuilder(column: $table.calciumMg, builder: (column) => column);
}

class $$MealEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealEntriesTable,
          MealEntry,
          $$MealEntriesTableFilterComposer,
          $$MealEntriesTableOrderingComposer,
          $$MealEntriesTableAnnotationComposer,
          $$MealEntriesTableCreateCompanionBuilder,
          $$MealEntriesTableUpdateCompanionBuilder,
          (
            MealEntry,
            BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry>,
          ),
          MealEntry,
          PrefetchHooks Function()
        > {
  $$MealEntriesTableTableManager(_$AppDatabase db, $MealEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> mealType = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<String> foodName = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<double> alcoholG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                Value<double> sodiumMg = const Value.absent(),
                Value<double> sugarG = const Value.absent(),
                Value<double> saturatedFatG = const Value.absent(),
                Value<double> calciumMg = const Value.absent(),
              }) => MealEntriesCompanion(
                id: id,
                date: date,
                mealType: mealType,
                foodId: foodId,
                foodName: foodName,
                grams: grams,
                calories: calories,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                alcoholG: alcoholG,
                fiberG: fiberG,
                sodiumMg: sodiumMg,
                sugarG: sugarG,
                saturatedFatG: saturatedFatG,
                calciumMg: calciumMg,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String mealType,
                required int foodId,
                required String foodName,
                required double grams,
                required double calories,
                required double proteinG,
                required double carbG,
                required double fatG,
                Value<double> alcoholG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                Value<double> sodiumMg = const Value.absent(),
                Value<double> sugarG = const Value.absent(),
                Value<double> saturatedFatG = const Value.absent(),
                Value<double> calciumMg = const Value.absent(),
              }) => MealEntriesCompanion.insert(
                id: id,
                date: date,
                mealType: mealType,
                foodId: foodId,
                foodName: foodName,
                grams: grams,
                calories: calories,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                alcoholG: alcoholG,
                fiberG: fiberG,
                sodiumMg: sodiumMg,
                sugarG: sugarG,
                saturatedFatG: saturatedFatG,
                calciumMg: calciumMg,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealEntriesTable,
      MealEntry,
      $$MealEntriesTableFilterComposer,
      $$MealEntriesTableOrderingComposer,
      $$MealEntriesTableAnnotationComposer,
      $$MealEntriesTableCreateCompanionBuilder,
      $$MealEntriesTableUpdateCompanionBuilder,
      (MealEntry, BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry>),
      MealEntry,
      PrefetchHooks Function()
    >;
typedef $$MealPresetsTableCreateCompanionBuilder =
    MealPresetsCompanion Function({
      Value<int> id,
      required String name,
      required DateTime createdAt,
    });
typedef $$MealPresetsTableUpdateCompanionBuilder =
    MealPresetsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

class $$MealPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $MealPresetsTable> {
  $$MealPresetsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPresetsTable> {
  $$MealPresetsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPresetsTable> {
  $$MealPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MealPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealPresetsTable,
          MealPreset,
          $$MealPresetsTableFilterComposer,
          $$MealPresetsTableOrderingComposer,
          $$MealPresetsTableAnnotationComposer,
          $$MealPresetsTableCreateCompanionBuilder,
          $$MealPresetsTableUpdateCompanionBuilder,
          (
            MealPreset,
            BaseReferences<_$AppDatabase, $MealPresetsTable, MealPreset>,
          ),
          MealPreset,
          PrefetchHooks Function()
        > {
  $$MealPresetsTableTableManager(_$AppDatabase db, $MealPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MealPresetsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime createdAt,
              }) => MealPresetsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealPresetsTable,
      MealPreset,
      $$MealPresetsTableFilterComposer,
      $$MealPresetsTableOrderingComposer,
      $$MealPresetsTableAnnotationComposer,
      $$MealPresetsTableCreateCompanionBuilder,
      $$MealPresetsTableUpdateCompanionBuilder,
      (
        MealPreset,
        BaseReferences<_$AppDatabase, $MealPresetsTable, MealPreset>,
      ),
      MealPreset,
      PrefetchHooks Function()
    >;
typedef $$MealPresetItemsTableCreateCompanionBuilder =
    MealPresetItemsCompanion Function({
      Value<int> id,
      required int presetId,
      required int foodId,
      required String foodName,
      required double grams,
      required String mealType,
    });
typedef $$MealPresetItemsTableUpdateCompanionBuilder =
    MealPresetItemsCompanion Function({
      Value<int> id,
      Value<int> presetId,
      Value<int> foodId,
      Value<String> foodName,
      Value<double> grams,
      Value<String> mealType,
    });

class $$MealPresetItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MealPresetItemsTable> {
  $$MealPresetItemsTableFilterComposer({
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

  ColumnFilters<int> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealPresetItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPresetItemsTable> {
  $$MealPresetItemsTableOrderingComposer({
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

  ColumnOrderings<int> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealPresetItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPresetItemsTable> {
  $$MealPresetItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);
}

class $$MealPresetItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealPresetItemsTable,
          MealPresetItem,
          $$MealPresetItemsTableFilterComposer,
          $$MealPresetItemsTableOrderingComposer,
          $$MealPresetItemsTableAnnotationComposer,
          $$MealPresetItemsTableCreateCompanionBuilder,
          $$MealPresetItemsTableUpdateCompanionBuilder,
          (
            MealPresetItem,
            BaseReferences<
              _$AppDatabase,
              $MealPresetItemsTable,
              MealPresetItem
            >,
          ),
          MealPresetItem,
          PrefetchHooks Function()
        > {
  $$MealPresetItemsTableTableManager(
    _$AppDatabase db,
    $MealPresetItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPresetItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPresetItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPresetItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> presetId = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<String> foodName = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<String> mealType = const Value.absent(),
              }) => MealPresetItemsCompanion(
                id: id,
                presetId: presetId,
                foodId: foodId,
                foodName: foodName,
                grams: grams,
                mealType: mealType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int presetId,
                required int foodId,
                required String foodName,
                required double grams,
                required String mealType,
              }) => MealPresetItemsCompanion.insert(
                id: id,
                presetId: presetId,
                foodId: foodId,
                foodName: foodName,
                grams: grams,
                mealType: mealType,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealPresetItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealPresetItemsTable,
      MealPresetItem,
      $$MealPresetItemsTableFilterComposer,
      $$MealPresetItemsTableOrderingComposer,
      $$MealPresetItemsTableAnnotationComposer,
      $$MealPresetItemsTableCreateCompanionBuilder,
      $$MealPresetItemsTableUpdateCompanionBuilder,
      (
        MealPresetItem,
        BaseReferences<_$AppDatabase, $MealPresetItemsTable, MealPresetItem>,
      ),
      MealPresetItem,
      PrefetchHooks Function()
    >;
typedef $$WaterLogsTableCreateCompanionBuilder =
    WaterLogsCompanion Function({
      Value<int> id,
      required DateTime date,
      required int ml,
    });
typedef $$WaterLogsTableUpdateCompanionBuilder =
    WaterLogsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> ml,
    });

class $$WaterLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get ml =>
      $composableBuilder(column: $table.ml, builder: (column) => column);
}

class $$WaterLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterLogsTable,
          WaterLog,
          $$WaterLogsTableFilterComposer,
          $$WaterLogsTableOrderingComposer,
          $$WaterLogsTableAnnotationComposer,
          $$WaterLogsTableCreateCompanionBuilder,
          $$WaterLogsTableUpdateCompanionBuilder,
          (WaterLog, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>),
          WaterLog,
          PrefetchHooks Function()
        > {
  $$WaterLogsTableTableManager(_$AppDatabase db, $WaterLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> ml = const Value.absent(),
              }) => WaterLogsCompanion(id: id, date: date, ml: ml),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int ml,
              }) => WaterLogsCompanion.insert(id: id, date: date, ml: ml),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterLogsTable,
      WaterLog,
      $$WaterLogsTableFilterComposer,
      $$WaterLogsTableOrderingComposer,
      $$WaterLogsTableAnnotationComposer,
      $$WaterLogsTableCreateCompanionBuilder,
      $$WaterLogsTableUpdateCompanionBuilder,
      (WaterLog, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>),
      WaterLog,
      PrefetchHooks Function()
    >;
typedef $$StepLogsTableCreateCompanionBuilder =
    StepLogsCompanion Function({
      Value<int> id,
      required DateTime date,
      required int steps,
    });
typedef $$StepLogsTableUpdateCompanionBuilder =
    StepLogsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> steps,
    });

class $$StepLogsTableFilterComposer
    extends Composer<_$AppDatabase, $StepLogsTable> {
  $$StepLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StepLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepLogsTable> {
  $$StepLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StepLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepLogsTable> {
  $$StepLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);
}

class $$StepLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepLogsTable,
          StepLog,
          $$StepLogsTableFilterComposer,
          $$StepLogsTableOrderingComposer,
          $$StepLogsTableAnnotationComposer,
          $$StepLogsTableCreateCompanionBuilder,
          $$StepLogsTableUpdateCompanionBuilder,
          (StepLog, BaseReferences<_$AppDatabase, $StepLogsTable, StepLog>),
          StepLog,
          PrefetchHooks Function()
        > {
  $$StepLogsTableTableManager(_$AppDatabase db, $StepLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> steps = const Value.absent(),
              }) => StepLogsCompanion(id: id, date: date, steps: steps),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int steps,
              }) => StepLogsCompanion.insert(id: id, date: date, steps: steps),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StepLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepLogsTable,
      StepLog,
      $$StepLogsTableFilterComposer,
      $$StepLogsTableOrderingComposer,
      $$StepLogsTableAnnotationComposer,
      $$StepLogsTableCreateCompanionBuilder,
      $$StepLogsTableUpdateCompanionBuilder,
      (StepLog, BaseReferences<_$AppDatabase, $StepLogsTable, StepLog>),
      StepLog,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
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

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
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

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
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

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaData,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaData,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>,
          ),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaData,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      required String name,
      required String unit,
      Value<bool> isCustom,
      Value<String> category,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> unit,
      Value<bool> isCustom,
      Value<String> category,
    });

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
          Exercise,
          PrefetchHooks Function()
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String> category = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                unit: unit,
                isCustom: isCustom,
                category: category,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String unit,
                Value<bool> isCustom = const Value.absent(),
                Value<String> category = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                unit: unit,
                isCustom: isCustom,
                category: category,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
      Exercise,
      PrefetchHooks Function()
    >;
typedef $$WorkoutPlansTableCreateCompanionBuilder =
    WorkoutPlansCompanion Function({
      Value<int> id,
      required String name,
      required DateTime createdAt,
    });
typedef $$WorkoutPlansTableUpdateCompanionBuilder =
    WorkoutPlansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

class $$WorkoutPlansTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutPlansTable> {
  $$WorkoutPlansTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutPlansTable> {
  $$WorkoutPlansTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutPlansTable> {
  $$WorkoutPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WorkoutPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutPlansTable,
          WorkoutPlan,
          $$WorkoutPlansTableFilterComposer,
          $$WorkoutPlansTableOrderingComposer,
          $$WorkoutPlansTableAnnotationComposer,
          $$WorkoutPlansTableCreateCompanionBuilder,
          $$WorkoutPlansTableUpdateCompanionBuilder,
          (
            WorkoutPlan,
            BaseReferences<_$AppDatabase, $WorkoutPlansTable, WorkoutPlan>,
          ),
          WorkoutPlan,
          PrefetchHooks Function()
        > {
  $$WorkoutPlansTableTableManager(_$AppDatabase db, $WorkoutPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WorkoutPlansCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime createdAt,
              }) => WorkoutPlansCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutPlansTable,
      WorkoutPlan,
      $$WorkoutPlansTableFilterComposer,
      $$WorkoutPlansTableOrderingComposer,
      $$WorkoutPlansTableAnnotationComposer,
      $$WorkoutPlansTableCreateCompanionBuilder,
      $$WorkoutPlansTableUpdateCompanionBuilder,
      (
        WorkoutPlan,
        BaseReferences<_$AppDatabase, $WorkoutPlansTable, WorkoutPlan>,
      ),
      WorkoutPlan,
      PrefetchHooks Function()
    >;
typedef $$WorkoutPlanItemsTableCreateCompanionBuilder =
    WorkoutPlanItemsCompanion Function({
      Value<int> id,
      required int planId,
      required int exerciseId,
      required String exerciseName,
      required int targetSets,
      required int targetReps,
      Value<int> sortOrder,
    });
typedef $$WorkoutPlanItemsTableUpdateCompanionBuilder =
    WorkoutPlanItemsCompanion Function({
      Value<int> id,
      Value<int> planId,
      Value<int> exerciseId,
      Value<String> exerciseName,
      Value<int> targetSets,
      Value<int> targetReps,
      Value<int> sortOrder,
    });

class $$WorkoutPlanItemsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutPlanItemsTable> {
  $$WorkoutPlanItemsTableFilterComposer({
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

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutPlanItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutPlanItemsTable> {
  $$WorkoutPlanItemsTableOrderingComposer({
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

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutPlanItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutPlanItemsTable> {
  $$WorkoutPlanItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WorkoutPlanItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutPlanItemsTable,
          WorkoutPlanItem,
          $$WorkoutPlanItemsTableFilterComposer,
          $$WorkoutPlanItemsTableOrderingComposer,
          $$WorkoutPlanItemsTableAnnotationComposer,
          $$WorkoutPlanItemsTableCreateCompanionBuilder,
          $$WorkoutPlanItemsTableUpdateCompanionBuilder,
          (
            WorkoutPlanItem,
            BaseReferences<
              _$AppDatabase,
              $WorkoutPlanItemsTable,
              WorkoutPlanItem
            >,
          ),
          WorkoutPlanItem,
          PrefetchHooks Function()
        > {
  $$WorkoutPlanItemsTableTableManager(
    _$AppDatabase db,
    $WorkoutPlanItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutPlanItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutPlanItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutPlanItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int> targetReps = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => WorkoutPlanItemsCompanion(
                id: id,
                planId: planId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                targetSets: targetSets,
                targetReps: targetReps,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required int exerciseId,
                required String exerciseName,
                required int targetSets,
                required int targetReps,
                Value<int> sortOrder = const Value.absent(),
              }) => WorkoutPlanItemsCompanion.insert(
                id: id,
                planId: planId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                targetSets: targetSets,
                targetReps: targetReps,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutPlanItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutPlanItemsTable,
      WorkoutPlanItem,
      $$WorkoutPlanItemsTableFilterComposer,
      $$WorkoutPlanItemsTableOrderingComposer,
      $$WorkoutPlanItemsTableAnnotationComposer,
      $$WorkoutPlanItemsTableCreateCompanionBuilder,
      $$WorkoutPlanItemsTableUpdateCompanionBuilder,
      (
        WorkoutPlanItem,
        BaseReferences<_$AppDatabase, $WorkoutPlanItemsTable, WorkoutPlanItem>,
      ),
      WorkoutPlanItem,
      PrefetchHooks Function()
    >;
typedef $$DayWorkoutsTableCreateCompanionBuilder =
    DayWorkoutsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<int?> planId,
      Value<String?> planName,
    });
typedef $$DayWorkoutsTableUpdateCompanionBuilder =
    DayWorkoutsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int?> planId,
      Value<String?> planName,
    });

class $$DayWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $DayWorkoutsTable> {
  $$DayWorkoutsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planName => $composableBuilder(
    column: $table.planName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayWorkoutsTable> {
  $$DayWorkoutsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planName => $composableBuilder(
    column: $table.planName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayWorkoutsTable> {
  $$DayWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get planName =>
      $composableBuilder(column: $table.planName, builder: (column) => column);
}

class $$DayWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayWorkoutsTable,
          DayWorkout,
          $$DayWorkoutsTableFilterComposer,
          $$DayWorkoutsTableOrderingComposer,
          $$DayWorkoutsTableAnnotationComposer,
          $$DayWorkoutsTableCreateCompanionBuilder,
          $$DayWorkoutsTableUpdateCompanionBuilder,
          (
            DayWorkout,
            BaseReferences<_$AppDatabase, $DayWorkoutsTable, DayWorkout>,
          ),
          DayWorkout,
          PrefetchHooks Function()
        > {
  $$DayWorkoutsTableTableManager(_$AppDatabase db, $DayWorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int?> planId = const Value.absent(),
                Value<String?> planName = const Value.absent(),
              }) => DayWorkoutsCompanion(
                id: id,
                date: date,
                planId: planId,
                planName: planName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<int?> planId = const Value.absent(),
                Value<String?> planName = const Value.absent(),
              }) => DayWorkoutsCompanion.insert(
                id: id,
                date: date,
                planId: planId,
                planName: planName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayWorkoutsTable,
      DayWorkout,
      $$DayWorkoutsTableFilterComposer,
      $$DayWorkoutsTableOrderingComposer,
      $$DayWorkoutsTableAnnotationComposer,
      $$DayWorkoutsTableCreateCompanionBuilder,
      $$DayWorkoutsTableUpdateCompanionBuilder,
      (
        DayWorkout,
        BaseReferences<_$AppDatabase, $DayWorkoutsTable, DayWorkout>,
      ),
      DayWorkout,
      PrefetchHooks Function()
    >;
typedef $$DayWorkoutItemsTableCreateCompanionBuilder =
    DayWorkoutItemsCompanion Function({
      Value<int> id,
      required int dayWorkoutId,
      required int exerciseId,
      required String exerciseName,
      required int targetSets,
      required int targetReps,
      Value<int> sortOrder,
      Value<bool> done,
    });
typedef $$DayWorkoutItemsTableUpdateCompanionBuilder =
    DayWorkoutItemsCompanion Function({
      Value<int> id,
      Value<int> dayWorkoutId,
      Value<int> exerciseId,
      Value<String> exerciseName,
      Value<int> targetSets,
      Value<int> targetReps,
      Value<int> sortOrder,
      Value<bool> done,
    });

class $$DayWorkoutItemsTableFilterComposer
    extends Composer<_$AppDatabase, $DayWorkoutItemsTable> {
  $$DayWorkoutItemsTableFilterComposer({
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

  ColumnFilters<int> get dayWorkoutId => $composableBuilder(
    column: $table.dayWorkoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayWorkoutItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayWorkoutItemsTable> {
  $$DayWorkoutItemsTableOrderingComposer({
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

  ColumnOrderings<int> get dayWorkoutId => $composableBuilder(
    column: $table.dayWorkoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayWorkoutItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayWorkoutItemsTable> {
  $$DayWorkoutItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayWorkoutId => $composableBuilder(
    column: $table.dayWorkoutId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);
}

class $$DayWorkoutItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayWorkoutItemsTable,
          DayWorkoutItem,
          $$DayWorkoutItemsTableFilterComposer,
          $$DayWorkoutItemsTableOrderingComposer,
          $$DayWorkoutItemsTableAnnotationComposer,
          $$DayWorkoutItemsTableCreateCompanionBuilder,
          $$DayWorkoutItemsTableUpdateCompanionBuilder,
          (
            DayWorkoutItem,
            BaseReferences<
              _$AppDatabase,
              $DayWorkoutItemsTable,
              DayWorkoutItem
            >,
          ),
          DayWorkoutItem,
          PrefetchHooks Function()
        > {
  $$DayWorkoutItemsTableTableManager(
    _$AppDatabase db,
    $DayWorkoutItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayWorkoutItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayWorkoutItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayWorkoutItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayWorkoutId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int> targetReps = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => DayWorkoutItemsCompanion(
                id: id,
                dayWorkoutId: dayWorkoutId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                targetSets: targetSets,
                targetReps: targetReps,
                sortOrder: sortOrder,
                done: done,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayWorkoutId,
                required int exerciseId,
                required String exerciseName,
                required int targetSets,
                required int targetReps,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => DayWorkoutItemsCompanion.insert(
                id: id,
                dayWorkoutId: dayWorkoutId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                targetSets: targetSets,
                targetReps: targetReps,
                sortOrder: sortOrder,
                done: done,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayWorkoutItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayWorkoutItemsTable,
      DayWorkoutItem,
      $$DayWorkoutItemsTableFilterComposer,
      $$DayWorkoutItemsTableOrderingComposer,
      $$DayWorkoutItemsTableAnnotationComposer,
      $$DayWorkoutItemsTableCreateCompanionBuilder,
      $$DayWorkoutItemsTableUpdateCompanionBuilder,
      (
        DayWorkoutItem,
        BaseReferences<_$AppDatabase, $DayWorkoutItemsTable, DayWorkoutItem>,
      ),
      DayWorkoutItem,
      PrefetchHooks Function()
    >;
typedef $$WorkoutSetLogsTableCreateCompanionBuilder =
    WorkoutSetLogsCompanion Function({
      Value<int> id,
      required DateTime date,
      required int exerciseId,
      required String exerciseName,
      required int setIndex,
      Value<int?> reps,
      Value<int?> durationSec,
      Value<int?> dayWorkoutItemId,
    });
typedef $$WorkoutSetLogsTableUpdateCompanionBuilder =
    WorkoutSetLogsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> exerciseId,
      Value<String> exerciseName,
      Value<int> setIndex,
      Value<int?> reps,
      Value<int?> durationSec,
      Value<int?> dayWorkoutItemId,
    });

class $$WorkoutSetLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetLogsTable> {
  $$WorkoutSetLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayWorkoutItemId => $composableBuilder(
    column: $table.dayWorkoutItemId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutSetLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetLogsTable> {
  $$WorkoutSetLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayWorkoutItemId => $composableBuilder(
    column: $table.dayWorkoutItemId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSetLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetLogsTable> {
  $$WorkoutSetLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayWorkoutItemId => $composableBuilder(
    column: $table.dayWorkoutItemId,
    builder: (column) => column,
  );
}

class $$WorkoutSetLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetLogsTable,
          WorkoutSetLog,
          $$WorkoutSetLogsTableFilterComposer,
          $$WorkoutSetLogsTableOrderingComposer,
          $$WorkoutSetLogsTableAnnotationComposer,
          $$WorkoutSetLogsTableCreateCompanionBuilder,
          $$WorkoutSetLogsTableUpdateCompanionBuilder,
          (
            WorkoutSetLog,
            BaseReferences<_$AppDatabase, $WorkoutSetLogsTable, WorkoutSetLog>,
          ),
          WorkoutSetLog,
          PrefetchHooks Function()
        > {
  $$WorkoutSetLogsTableTableManager(
    _$AppDatabase db,
    $WorkoutSetLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int?> dayWorkoutItemId = const Value.absent(),
              }) => WorkoutSetLogsCompanion(
                id: id,
                date: date,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                setIndex: setIndex,
                reps: reps,
                durationSec: durationSec,
                dayWorkoutItemId: dayWorkoutItemId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int exerciseId,
                required String exerciseName,
                required int setIndex,
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int?> dayWorkoutItemId = const Value.absent(),
              }) => WorkoutSetLogsCompanion.insert(
                id: id,
                date: date,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                setIndex: setIndex,
                reps: reps,
                durationSec: durationSec,
                dayWorkoutItemId: dayWorkoutItemId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutSetLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetLogsTable,
      WorkoutSetLog,
      $$WorkoutSetLogsTableFilterComposer,
      $$WorkoutSetLogsTableOrderingComposer,
      $$WorkoutSetLogsTableAnnotationComposer,
      $$WorkoutSetLogsTableCreateCompanionBuilder,
      $$WorkoutSetLogsTableUpdateCompanionBuilder,
      (
        WorkoutSetLog,
        BaseReferences<_$AppDatabase, $WorkoutSetLogsTable, WorkoutSetLog>,
      ),
      WorkoutSetLog,
      PrefetchHooks Function()
    >;
typedef $$DailyNotesTableCreateCompanionBuilder =
    DailyNotesCompanion Function({
      Value<int> id,
      required DateTime date,
      required String content,
      required DateTime updatedAt,
    });
typedef $$DailyNotesTableUpdateCompanionBuilder =
    DailyNotesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> content,
      Value<DateTime> updatedAt,
    });

class $$DailyNotesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyNotesTable> {
  $$DailyNotesTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyNotesTable> {
  $$DailyNotesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyNotesTable> {
  $$DailyNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyNotesTable,
          DailyNote,
          $$DailyNotesTableFilterComposer,
          $$DailyNotesTableOrderingComposer,
          $$DailyNotesTableAnnotationComposer,
          $$DailyNotesTableCreateCompanionBuilder,
          $$DailyNotesTableUpdateCompanionBuilder,
          (
            DailyNote,
            BaseReferences<_$AppDatabase, $DailyNotesTable, DailyNote>,
          ),
          DailyNote,
          PrefetchHooks Function()
        > {
  $$DailyNotesTableTableManager(_$AppDatabase db, $DailyNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyNotesCompanion(
                id: id,
                date: date,
                content: content,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String content,
                required DateTime updatedAt,
              }) => DailyNotesCompanion.insert(
                id: id,
                date: date,
                content: content,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyNotesTable,
      DailyNote,
      $$DailyNotesTableFilterComposer,
      $$DailyNotesTableOrderingComposer,
      $$DailyNotesTableAnnotationComposer,
      $$DailyNotesTableCreateCompanionBuilder,
      $$DailyNotesTableUpdateCompanionBuilder,
      (DailyNote, BaseReferences<_$AppDatabase, $DailyNotesTable, DailyNote>),
      DailyNote,
      PrefetchHooks Function()
    >;
typedef $$DietStrategyPlansTableCreateCompanionBuilder =
    DietStrategyPlansCompanion Function({
      Value<int> id,
      required int version,
      required String strategy,
      required String status,
      required String effectiveFrom,
      Value<String?> endedOn,
      required DateTime createdAt,
      required double referenceWeightKg,
      required double estimatedTdee,
      required double deficitFraction,
      required double proteinPerKg,
      required double fatPerKg,
      required double baseEnergy,
      Value<String?> schedule,
      Value<double?> carbAmplitudeG,
      Value<int> taperStage,
      Value<String?> observationStart,
      Value<int> observationDays,
      Value<String> reason,
      Value<int?> legacyCalories,
    });
typedef $$DietStrategyPlansTableUpdateCompanionBuilder =
    DietStrategyPlansCompanion Function({
      Value<int> id,
      Value<int> version,
      Value<String> strategy,
      Value<String> status,
      Value<String> effectiveFrom,
      Value<String?> endedOn,
      Value<DateTime> createdAt,
      Value<double> referenceWeightKg,
      Value<double> estimatedTdee,
      Value<double> deficitFraction,
      Value<double> proteinPerKg,
      Value<double> fatPerKg,
      Value<double> baseEnergy,
      Value<String?> schedule,
      Value<double?> carbAmplitudeG,
      Value<int> taperStage,
      Value<String?> observationStart,
      Value<int> observationDays,
      Value<String> reason,
      Value<int?> legacyCalories,
    });

class $$DietStrategyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $DietStrategyPlansTable> {
  $$DietStrategyPlansTableFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endedOn => $composableBuilder(
    column: $table.endedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get referenceWeightKg => $composableBuilder(
    column: $table.referenceWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedTdee => $composableBuilder(
    column: $table.estimatedTdee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deficitFraction => $composableBuilder(
    column: $table.deficitFraction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPerKg => $composableBuilder(
    column: $table.proteinPerKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPerKg => $composableBuilder(
    column: $table.fatPerKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseEnergy => $composableBuilder(
    column: $table.baseEnergy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schedule => $composableBuilder(
    column: $table.schedule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbAmplitudeG => $composableBuilder(
    column: $table.carbAmplitudeG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taperStage => $composableBuilder(
    column: $table.taperStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observationStart => $composableBuilder(
    column: $table.observationStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observationDays => $composableBuilder(
    column: $table.observationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacyCalories => $composableBuilder(
    column: $table.legacyCalories,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DietStrategyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $DietStrategyPlansTable> {
  $$DietStrategyPlansTableOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedOn => $composableBuilder(
    column: $table.endedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get referenceWeightKg => $composableBuilder(
    column: $table.referenceWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedTdee => $composableBuilder(
    column: $table.estimatedTdee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deficitFraction => $composableBuilder(
    column: $table.deficitFraction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPerKg => $composableBuilder(
    column: $table.proteinPerKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPerKg => $composableBuilder(
    column: $table.fatPerKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseEnergy => $composableBuilder(
    column: $table.baseEnergy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schedule => $composableBuilder(
    column: $table.schedule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbAmplitudeG => $composableBuilder(
    column: $table.carbAmplitudeG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taperStage => $composableBuilder(
    column: $table.taperStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observationStart => $composableBuilder(
    column: $table.observationStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observationDays => $composableBuilder(
    column: $table.observationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacyCalories => $composableBuilder(
    column: $table.legacyCalories,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DietStrategyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $DietStrategyPlansTable> {
  $$DietStrategyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endedOn =>
      $composableBuilder(column: $table.endedOn, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get referenceWeightKg => $composableBuilder(
    column: $table.referenceWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get estimatedTdee => $composableBuilder(
    column: $table.estimatedTdee,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deficitFraction => $composableBuilder(
    column: $table.deficitFraction,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPerKg => $composableBuilder(
    column: $table.proteinPerKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPerKg =>
      $composableBuilder(column: $table.fatPerKg, builder: (column) => column);

  GeneratedColumn<double> get baseEnergy => $composableBuilder(
    column: $table.baseEnergy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => column);

  GeneratedColumn<double> get carbAmplitudeG => $composableBuilder(
    column: $table.carbAmplitudeG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taperStage => $composableBuilder(
    column: $table.taperStage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observationStart => $composableBuilder(
    column: $table.observationStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get observationDays => $composableBuilder(
    column: $table.observationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get legacyCalories => $composableBuilder(
    column: $table.legacyCalories,
    builder: (column) => column,
  );
}

class $$DietStrategyPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DietStrategyPlansTable,
          DietStrategyPlanRow,
          $$DietStrategyPlansTableFilterComposer,
          $$DietStrategyPlansTableOrderingComposer,
          $$DietStrategyPlansTableAnnotationComposer,
          $$DietStrategyPlansTableCreateCompanionBuilder,
          $$DietStrategyPlansTableUpdateCompanionBuilder,
          (
            DietStrategyPlanRow,
            BaseReferences<
              _$AppDatabase,
              $DietStrategyPlansTable,
              DietStrategyPlanRow
            >,
          ),
          DietStrategyPlanRow,
          PrefetchHooks Function()
        > {
  $$DietStrategyPlansTableTableManager(
    _$AppDatabase db,
    $DietStrategyPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietStrategyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietStrategyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietStrategyPlansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> strategy = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> effectiveFrom = const Value.absent(),
                Value<String?> endedOn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<double> referenceWeightKg = const Value.absent(),
                Value<double> estimatedTdee = const Value.absent(),
                Value<double> deficitFraction = const Value.absent(),
                Value<double> proteinPerKg = const Value.absent(),
                Value<double> fatPerKg = const Value.absent(),
                Value<double> baseEnergy = const Value.absent(),
                Value<String?> schedule = const Value.absent(),
                Value<double?> carbAmplitudeG = const Value.absent(),
                Value<int> taperStage = const Value.absent(),
                Value<String?> observationStart = const Value.absent(),
                Value<int> observationDays = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int?> legacyCalories = const Value.absent(),
              }) => DietStrategyPlansCompanion(
                id: id,
                version: version,
                strategy: strategy,
                status: status,
                effectiveFrom: effectiveFrom,
                endedOn: endedOn,
                createdAt: createdAt,
                referenceWeightKg: referenceWeightKg,
                estimatedTdee: estimatedTdee,
                deficitFraction: deficitFraction,
                proteinPerKg: proteinPerKg,
                fatPerKg: fatPerKg,
                baseEnergy: baseEnergy,
                schedule: schedule,
                carbAmplitudeG: carbAmplitudeG,
                taperStage: taperStage,
                observationStart: observationStart,
                observationDays: observationDays,
                reason: reason,
                legacyCalories: legacyCalories,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int version,
                required String strategy,
                required String status,
                required String effectiveFrom,
                Value<String?> endedOn = const Value.absent(),
                required DateTime createdAt,
                required double referenceWeightKg,
                required double estimatedTdee,
                required double deficitFraction,
                required double proteinPerKg,
                required double fatPerKg,
                required double baseEnergy,
                Value<String?> schedule = const Value.absent(),
                Value<double?> carbAmplitudeG = const Value.absent(),
                Value<int> taperStage = const Value.absent(),
                Value<String?> observationStart = const Value.absent(),
                Value<int> observationDays = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int?> legacyCalories = const Value.absent(),
              }) => DietStrategyPlansCompanion.insert(
                id: id,
                version: version,
                strategy: strategy,
                status: status,
                effectiveFrom: effectiveFrom,
                endedOn: endedOn,
                createdAt: createdAt,
                referenceWeightKg: referenceWeightKg,
                estimatedTdee: estimatedTdee,
                deficitFraction: deficitFraction,
                proteinPerKg: proteinPerKg,
                fatPerKg: fatPerKg,
                baseEnergy: baseEnergy,
                schedule: schedule,
                carbAmplitudeG: carbAmplitudeG,
                taperStage: taperStage,
                observationStart: observationStart,
                observationDays: observationDays,
                reason: reason,
                legacyCalories: legacyCalories,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DietStrategyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DietStrategyPlansTable,
      DietStrategyPlanRow,
      $$DietStrategyPlansTableFilterComposer,
      $$DietStrategyPlansTableOrderingComposer,
      $$DietStrategyPlansTableAnnotationComposer,
      $$DietStrategyPlansTableCreateCompanionBuilder,
      $$DietStrategyPlansTableUpdateCompanionBuilder,
      (
        DietStrategyPlanRow,
        BaseReferences<
          _$AppDatabase,
          $DietStrategyPlansTable,
          DietStrategyPlanRow
        >,
      ),
      DietStrategyPlanRow,
      PrefetchHooks Function()
    >;
typedef $$DailyNutritionTargetsTableCreateCompanionBuilder =
    DailyNutritionTargetsCompanion Function({
      required String date,
      Value<int?> planId,
      Value<int?> planVersion,
      Value<String?> strategy,
      Value<String?> dayType,
      required double calories,
      required double proteinG,
      required double carbG,
      required double fatG,
      Value<double?> estimatedTdee,
      required String source,
      Value<String> status,
      Value<String?> reason,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DailyNutritionTargetsTableUpdateCompanionBuilder =
    DailyNutritionTargetsCompanion Function({
      Value<String> date,
      Value<int?> planId,
      Value<int?> planVersion,
      Value<String?> strategy,
      Value<String?> dayType,
      Value<double> calories,
      Value<double> proteinG,
      Value<double> carbG,
      Value<double> fatG,
      Value<double?> estimatedTdee,
      Value<String> source,
      Value<String> status,
      Value<String?> reason,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DailyNutritionTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyNutritionTargetsTable> {
  $$DailyNutritionTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planVersion => $composableBuilder(
    column: $table.planVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayType => $composableBuilder(
    column: $table.dayType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedTdee => $composableBuilder(
    column: $table.estimatedTdee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyNutritionTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyNutritionTargetsTable> {
  $$DailyNutritionTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planVersion => $composableBuilder(
    column: $table.planVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayType => $composableBuilder(
    column: $table.dayType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedTdee => $composableBuilder(
    column: $table.estimatedTdee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyNutritionTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyNutritionTargetsTable> {
  $$DailyNutritionTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get planVersion => $composableBuilder(
    column: $table.planVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => column);

  GeneratedColumn<String> get dayType =>
      $composableBuilder(column: $table.dayType, builder: (column) => column);

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get estimatedTdee => $composableBuilder(
    column: $table.estimatedTdee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyNutritionTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyNutritionTargetsTable,
          DailyNutritionTargetRow,
          $$DailyNutritionTargetsTableFilterComposer,
          $$DailyNutritionTargetsTableOrderingComposer,
          $$DailyNutritionTargetsTableAnnotationComposer,
          $$DailyNutritionTargetsTableCreateCompanionBuilder,
          $$DailyNutritionTargetsTableUpdateCompanionBuilder,
          (
            DailyNutritionTargetRow,
            BaseReferences<
              _$AppDatabase,
              $DailyNutritionTargetsTable,
              DailyNutritionTargetRow
            >,
          ),
          DailyNutritionTargetRow,
          PrefetchHooks Function()
        > {
  $$DailyNutritionTargetsTableTableManager(
    _$AppDatabase db,
    $DailyNutritionTargetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyNutritionTargetsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyNutritionTargetsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyNutritionTargetsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int?> planId = const Value.absent(),
                Value<int?> planVersion = const Value.absent(),
                Value<String?> strategy = const Value.absent(),
                Value<String?> dayType = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<double?> estimatedTdee = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyNutritionTargetsCompanion(
                date: date,
                planId: planId,
                planVersion: planVersion,
                strategy: strategy,
                dayType: dayType,
                calories: calories,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                estimatedTdee: estimatedTdee,
                source: source,
                status: status,
                reason: reason,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                Value<int?> planId = const Value.absent(),
                Value<int?> planVersion = const Value.absent(),
                Value<String?> strategy = const Value.absent(),
                Value<String?> dayType = const Value.absent(),
                required double calories,
                required double proteinG,
                required double carbG,
                required double fatG,
                Value<double?> estimatedTdee = const Value.absent(),
                required String source,
                Value<String> status = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyNutritionTargetsCompanion.insert(
                date: date,
                planId: planId,
                planVersion: planVersion,
                strategy: strategy,
                dayType: dayType,
                calories: calories,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                estimatedTdee: estimatedTdee,
                source: source,
                status: status,
                reason: reason,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyNutritionTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyNutritionTargetsTable,
      DailyNutritionTargetRow,
      $$DailyNutritionTargetsTableFilterComposer,
      $$DailyNutritionTargetsTableOrderingComposer,
      $$DailyNutritionTargetsTableAnnotationComposer,
      $$DailyNutritionTargetsTableCreateCompanionBuilder,
      $$DailyNutritionTargetsTableUpdateCompanionBuilder,
      (
        DailyNutritionTargetRow,
        BaseReferences<
          _$AppDatabase,
          $DailyNutritionTargetsTable,
          DailyNutritionTargetRow
        >,
      ),
      DailyNutritionTargetRow,
      PrefetchHooks Function()
    >;
typedef $$DayDietConfirmationsTableCreateCompanionBuilder =
    DayDietConfirmationsCompanion Function({
      required String date,
      required bool complete,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DayDietConfirmationsTableUpdateCompanionBuilder =
    DayDietConfirmationsCompanion Function({
      Value<String> date,
      Value<bool> complete,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DayDietConfirmationsTableFilterComposer
    extends Composer<_$AppDatabase, $DayDietConfirmationsTable> {
  $$DayDietConfirmationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayDietConfirmationsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayDietConfirmationsTable> {
  $$DayDietConfirmationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayDietConfirmationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayDietConfirmationsTable> {
  $$DayDietConfirmationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DayDietConfirmationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayDietConfirmationsTable,
          DayDietConfirmationRow,
          $$DayDietConfirmationsTableFilterComposer,
          $$DayDietConfirmationsTableOrderingComposer,
          $$DayDietConfirmationsTableAnnotationComposer,
          $$DayDietConfirmationsTableCreateCompanionBuilder,
          $$DayDietConfirmationsTableUpdateCompanionBuilder,
          (
            DayDietConfirmationRow,
            BaseReferences<
              _$AppDatabase,
              $DayDietConfirmationsTable,
              DayDietConfirmationRow
            >,
          ),
          DayDietConfirmationRow,
          PrefetchHooks Function()
        > {
  $$DayDietConfirmationsTableTableManager(
    _$AppDatabase db,
    $DayDietConfirmationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayDietConfirmationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayDietConfirmationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DayDietConfirmationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayDietConfirmationsCompanion(
                date: date,
                complete: complete,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required bool complete,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DayDietConfirmationsCompanion.insert(
                date: date,
                complete: complete,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayDietConfirmationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayDietConfirmationsTable,
      DayDietConfirmationRow,
      $$DayDietConfirmationsTableFilterComposer,
      $$DayDietConfirmationsTableOrderingComposer,
      $$DayDietConfirmationsTableAnnotationComposer,
      $$DayDietConfirmationsTableCreateCompanionBuilder,
      $$DayDietConfirmationsTableUpdateCompanionBuilder,
      (
        DayDietConfirmationRow,
        BaseReferences<
          _$AppDatabase,
          $DayDietConfirmationsTable,
          DayDietConfirmationRow
        >,
      ),
      DayDietConfirmationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db, _db.foodItems);
  $$FoodServingsTableTableManager get foodServings =>
      $$FoodServingsTableTableManager(_db, _db.foodServings);
  $$FavoriteFoodsTableTableManager get favoriteFoods =>
      $$FavoriteFoodsTableTableManager(_db, _db.favoriteFoods);
  $$WeightLogsTableTableManager get weightLogs =>
      $$WeightLogsTableTableManager(_db, _db.weightLogs);
  $$MealEntriesTableTableManager get mealEntries =>
      $$MealEntriesTableTableManager(_db, _db.mealEntries);
  $$MealPresetsTableTableManager get mealPresets =>
      $$MealPresetsTableTableManager(_db, _db.mealPresets);
  $$MealPresetItemsTableTableManager get mealPresetItems =>
      $$MealPresetItemsTableTableManager(_db, _db.mealPresetItems);
  $$WaterLogsTableTableManager get waterLogs =>
      $$WaterLogsTableTableManager(_db, _db.waterLogs);
  $$StepLogsTableTableManager get stepLogs =>
      $$StepLogsTableTableManager(_db, _db.stepLogs);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutPlansTableTableManager get workoutPlans =>
      $$WorkoutPlansTableTableManager(_db, _db.workoutPlans);
  $$WorkoutPlanItemsTableTableManager get workoutPlanItems =>
      $$WorkoutPlanItemsTableTableManager(_db, _db.workoutPlanItems);
  $$DayWorkoutsTableTableManager get dayWorkouts =>
      $$DayWorkoutsTableTableManager(_db, _db.dayWorkouts);
  $$DayWorkoutItemsTableTableManager get dayWorkoutItems =>
      $$DayWorkoutItemsTableTableManager(_db, _db.dayWorkoutItems);
  $$WorkoutSetLogsTableTableManager get workoutSetLogs =>
      $$WorkoutSetLogsTableTableManager(_db, _db.workoutSetLogs);
  $$DailyNotesTableTableManager get dailyNotes =>
      $$DailyNotesTableTableManager(_db, _db.dailyNotes);
  $$DietStrategyPlansTableTableManager get dietStrategyPlans =>
      $$DietStrategyPlansTableTableManager(_db, _db.dietStrategyPlans);
  $$DailyNutritionTargetsTableTableManager get dailyNutritionTargets =>
      $$DailyNutritionTargetsTableTableManager(_db, _db.dailyNutritionTargets);
  $$DayDietConfirmationsTableTableManager get dayDietConfirmations =>
      $$DayDietConfirmationsTableTableManager(_db, _db.dayDietConfirmations);
}
