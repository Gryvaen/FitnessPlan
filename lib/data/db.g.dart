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
          ..write('alcoholG: $alcoholG')
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
          other.alcoholG == this.alcoholG);
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
          ..write('alcoholG: $alcoholG')
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
  @override
  List<GeneratedColumn> get $columns => [id, name, unit, isCustom];
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
  const Exercise({
    required this.id,
    required this.name,
    required this.unit,
    required this.isCustom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['is_custom'] = Variable<bool>(isCustom);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      isCustom: Value(isCustom),
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
    };
  }

  Exercise copyWith({int? id, String? name, String? unit, bool? isCustom}) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        isCustom: isCustom ?? this.isCustom,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, unit, isCustom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.isCustom == this.isCustom);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<bool> isCustom;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.isCustom = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String unit,
    this.isCustom = const Value.absent(),
  }) : name = Value(name),
       unit = Value(unit);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<bool>? isCustom,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (isCustom != null) 'is_custom': isCustom,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? unit,
    Value<bool>? isCustom,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
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
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('isCustom: $isCustom')
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date},
  ];
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
    appMeta,
    exercises,
    workoutPlans,
    workoutPlanItems,
    dayWorkouts,
    dayWorkoutItems,
    workoutSetLogs,
    dailyNotes,
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
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> unit,
      Value<bool> isCustom,
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
              }) => ExercisesCompanion(
                id: id,
                name: name,
                unit: unit,
                isCustom: isCustom,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String unit,
                Value<bool> isCustom = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                unit: unit,
                isCustom: isCustom,
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
}
