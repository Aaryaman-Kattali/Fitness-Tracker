// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MovementPattern, String> pattern =
      GeneratedColumn<String>(
        'pattern',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MovementPattern>($ExercisesTable.$converterpattern);
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUnilateralMeta = const VerificationMeta(
    'isUnilateral',
  );
  @override
  late final GeneratedColumn<bool> isUnilateral = GeneratedColumn<bool>(
    'is_unilateral',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unilateral" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    pattern,
    equipment,
    isUnilateral,
  ];
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
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('is_unilateral')) {
      context.handle(
        _isUnilateralMeta,
        isUnilateral.isAcceptableOrUnknown(
          data['is_unilateral']!,
          _isUnilateralMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
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
      pattern: $ExercisesTable.$converterpattern.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pattern'],
        )!,
      ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      isUnilateral: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unilateral'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MovementPattern, String, String> $converterpattern =
      const EnumNameConverter<MovementPattern>(MovementPattern.values);
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String name;
  final MovementPattern pattern;
  final String equipment;
  final bool isUnilateral;
  const Exercise({
    required this.id,
    required this.name,
    required this.pattern,
    required this.equipment,
    required this.isUnilateral,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['pattern'] = Variable<String>(
        $ExercisesTable.$converterpattern.toSql(pattern),
      );
    }
    map['equipment'] = Variable<String>(equipment);
    map['is_unilateral'] = Variable<bool>(isUnilateral);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      pattern: Value(pattern),
      equipment: Value(equipment),
      isUnilateral: Value(isUnilateral),
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
      pattern: $ExercisesTable.$converterpattern.fromJson(
        serializer.fromJson<String>(json['pattern']),
      ),
      equipment: serializer.fromJson<String>(json['equipment']),
      isUnilateral: serializer.fromJson<bool>(json['isUnilateral']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'pattern': serializer.toJson<String>(
        $ExercisesTable.$converterpattern.toJson(pattern),
      ),
      'equipment': serializer.toJson<String>(equipment),
      'isUnilateral': serializer.toJson<bool>(isUnilateral),
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    MovementPattern? pattern,
    String? equipment,
    bool? isUnilateral,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    pattern: pattern ?? this.pattern,
    equipment: equipment ?? this.equipment,
    isUnilateral: isUnilateral ?? this.isUnilateral,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      isUnilateral: data.isUnilateral.present
          ? data.isUnilateral.value
          : this.isUnilateral,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pattern: $pattern, ')
          ..write('equipment: $equipment, ')
          ..write('isUnilateral: $isUnilateral')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, pattern, equipment, isUnilateral);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.pattern == this.pattern &&
          other.equipment == this.equipment &&
          other.isUnilateral == this.isUnilateral);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<MovementPattern> pattern;
  final Value<String> equipment;
  final Value<bool> isUnilateral;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.pattern = const Value.absent(),
    this.equipment = const Value.absent(),
    this.isUnilateral = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required MovementPattern pattern,
    required String equipment,
    this.isUnilateral = const Value.absent(),
  }) : name = Value(name),
       pattern = Value(pattern),
       equipment = Value(equipment);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? pattern,
    Expression<String>? equipment,
    Expression<bool>? isUnilateral,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (pattern != null) 'pattern': pattern,
      if (equipment != null) 'equipment': equipment,
      if (isUnilateral != null) 'is_unilateral': isUnilateral,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<MovementPattern>? pattern,
    Value<String>? equipment,
    Value<bool>? isUnilateral,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      equipment: equipment ?? this.equipment,
      isUnilateral: isUnilateral ?? this.isUnilateral,
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
    if (pattern.present) {
      map['pattern'] = Variable<String>(
        $ExercisesTable.$converterpattern.toSql(pattern.value),
      );
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (isUnilateral.present) {
      map['is_unilateral'] = Variable<bool>(isUnilateral.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pattern: $pattern, ')
          ..write('equipment: $equipment, ')
          ..write('isUnilateral: $isUnilateral')
          ..write(')'))
        .toString();
  }
}

class $PlanDaysTable extends PlanDays with TableInfo<$PlanDaysTable, PlanDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanDaysTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<PlanDayKey, String> dayKey =
      GeneratedColumn<String>(
        'day_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      ).withConverter<PlanDayKey>($PlanDaysTable.$converterdayKey);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dayKey, name, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanDay> instance, {
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
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanDay(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayKey: $PlanDaysTable.$converterdayKey.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}day_key'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $PlanDaysTable createAlias(String alias) {
    return $PlanDaysTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlanDayKey, String, String> $converterdayKey =
      const EnumNameConverter<PlanDayKey>(PlanDayKey.values);
}

class PlanDay extends DataClass implements Insertable<PlanDay> {
  final int id;
  final PlanDayKey dayKey;
  final String name;
  final int orderIndex;
  const PlanDay({
    required this.id,
    required this.dayKey,
    required this.name,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['day_key'] = Variable<String>(
        $PlanDaysTable.$converterdayKey.toSql(dayKey),
      );
    }
    map['name'] = Variable<String>(name);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  PlanDaysCompanion toCompanion(bool nullToAbsent) {
    return PlanDaysCompanion(
      id: Value(id),
      dayKey: Value(dayKey),
      name: Value(name),
      orderIndex: Value(orderIndex),
    );
  }

  factory PlanDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanDay(
      id: serializer.fromJson<int>(json['id']),
      dayKey: $PlanDaysTable.$converterdayKey.fromJson(
        serializer.fromJson<String>(json['dayKey']),
      ),
      name: serializer.fromJson<String>(json['name']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayKey': serializer.toJson<String>(
        $PlanDaysTable.$converterdayKey.toJson(dayKey),
      ),
      'name': serializer.toJson<String>(name),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  PlanDay copyWith({
    int? id,
    PlanDayKey? dayKey,
    String? name,
    int? orderIndex,
  }) => PlanDay(
    id: id ?? this.id,
    dayKey: dayKey ?? this.dayKey,
    name: name ?? this.name,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  PlanDay copyWithCompanion(PlanDaysCompanion data) {
    return PlanDay(
      id: data.id.present ? data.id.value : this.id,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      name: data.name.present ? data.name.value : this.name,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanDay(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayKey, name, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanDay &&
          other.id == this.id &&
          other.dayKey == this.dayKey &&
          other.name == this.name &&
          other.orderIndex == this.orderIndex);
}

class PlanDaysCompanion extends UpdateCompanion<PlanDay> {
  final Value<int> id;
  final Value<PlanDayKey> dayKey;
  final Value<String> name;
  final Value<int> orderIndex;
  const PlanDaysCompanion({
    this.id = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.name = const Value.absent(),
    this.orderIndex = const Value.absent(),
  });
  PlanDaysCompanion.insert({
    this.id = const Value.absent(),
    required PlanDayKey dayKey,
    required String name,
    required int orderIndex,
  }) : dayKey = Value(dayKey),
       name = Value(name),
       orderIndex = Value(orderIndex);
  static Insertable<PlanDay> custom({
    Expression<int>? id,
    Expression<String>? dayKey,
    Expression<String>? name,
    Expression<int>? orderIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayKey != null) 'day_key': dayKey,
      if (name != null) 'name': name,
      if (orderIndex != null) 'order_index': orderIndex,
    });
  }

  PlanDaysCompanion copyWith({
    Value<int>? id,
    Value<PlanDayKey>? dayKey,
    Value<String>? name,
    Value<int>? orderIndex,
  }) {
    return PlanDaysCompanion(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(
        $PlanDaysTable.$converterdayKey.toSql(dayKey.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanDaysCompanion(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }
}

class $PlanItemsTable extends PlanItems
    with TableInfo<$PlanItemsTable, PlanItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _planDayIdMeta = const VerificationMeta(
    'planDayId',
  );
  @override
  late final GeneratedColumn<int> planDayId = GeneratedColumn<int>(
    'plan_day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plan_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrainingBlock, String> block =
      GeneratedColumn<String>(
        'block',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TrainingBlock>($PlanItemsTable.$converterblock);
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repLowMeta = const VerificationMeta('repLow');
  @override
  late final GeneratedColumn<int> repLow = GeneratedColumn<int>(
    'rep_low',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repHighMeta = const VerificationMeta(
    'repHigh',
  );
  @override
  late final GeneratedColumn<int> repHigh = GeneratedColumn<int>(
    'rep_high',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planDayId,
    exerciseId,
    block,
    targetSets,
    repLow,
    repHigh,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
        _planDayIdMeta,
        planDayId.isAcceptableOrUnknown(data['plan_day_id']!, _planDayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planDayIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    }
    if (data.containsKey('rep_low')) {
      context.handle(
        _repLowMeta,
        repLow.isAcceptableOrUnknown(data['rep_low']!, _repLowMeta),
      );
    }
    if (data.containsKey('rep_high')) {
      context.handle(
        _repHighMeta,
        repHigh.isAcceptableOrUnknown(data['rep_high']!, _repHighMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_day_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      ),
      block: $PlanItemsTable.$converterblock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}block'],
        )!,
      ),
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      ),
      repLow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rep_low'],
      ),
      repHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rep_high'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $PlanItemsTable createAlias(String alias) {
    return $PlanItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TrainingBlock, String, String> $converterblock =
      const EnumNameConverter<TrainingBlock>(TrainingBlock.values);
}

class PlanItem extends DataClass implements Insertable<PlanItem> {
  final int id;
  final int planDayId;
  final int? exerciseId;
  final TrainingBlock block;
  final int? targetSets;
  final int? repLow;
  final int? repHigh;
  final String? notes;
  const PlanItem({
    required this.id,
    required this.planDayId,
    this.exerciseId,
    required this.block,
    this.targetSets,
    this.repLow,
    this.repHigh,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_day_id'] = Variable<int>(planDayId);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<int>(exerciseId);
    }
    {
      map['block'] = Variable<String>(
        $PlanItemsTable.$converterblock.toSql(block),
      );
    }
    if (!nullToAbsent || targetSets != null) {
      map['target_sets'] = Variable<int>(targetSets);
    }
    if (!nullToAbsent || repLow != null) {
      map['rep_low'] = Variable<int>(repLow);
    }
    if (!nullToAbsent || repHigh != null) {
      map['rep_high'] = Variable<int>(repHigh);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  PlanItemsCompanion toCompanion(bool nullToAbsent) {
    return PlanItemsCompanion(
      id: Value(id),
      planDayId: Value(planDayId),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      block: Value(block),
      targetSets: targetSets == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSets),
      repLow: repLow == null && nullToAbsent
          ? const Value.absent()
          : Value(repLow),
      repHigh: repHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(repHigh),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory PlanItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanItem(
      id: serializer.fromJson<int>(json['id']),
      planDayId: serializer.fromJson<int>(json['planDayId']),
      exerciseId: serializer.fromJson<int?>(json['exerciseId']),
      block: $PlanItemsTable.$converterblock.fromJson(
        serializer.fromJson<String>(json['block']),
      ),
      targetSets: serializer.fromJson<int?>(json['targetSets']),
      repLow: serializer.fromJson<int?>(json['repLow']),
      repHigh: serializer.fromJson<int?>(json['repHigh']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planDayId': serializer.toJson<int>(planDayId),
      'exerciseId': serializer.toJson<int?>(exerciseId),
      'block': serializer.toJson<String>(
        $PlanItemsTable.$converterblock.toJson(block),
      ),
      'targetSets': serializer.toJson<int?>(targetSets),
      'repLow': serializer.toJson<int?>(repLow),
      'repHigh': serializer.toJson<int?>(repHigh),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  PlanItem copyWith({
    int? id,
    int? planDayId,
    Value<int?> exerciseId = const Value.absent(),
    TrainingBlock? block,
    Value<int?> targetSets = const Value.absent(),
    Value<int?> repLow = const Value.absent(),
    Value<int?> repHigh = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => PlanItem(
    id: id ?? this.id,
    planDayId: planDayId ?? this.planDayId,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    block: block ?? this.block,
    targetSets: targetSets.present ? targetSets.value : this.targetSets,
    repLow: repLow.present ? repLow.value : this.repLow,
    repHigh: repHigh.present ? repHigh.value : this.repHigh,
    notes: notes.present ? notes.value : this.notes,
  );
  PlanItem copyWithCompanion(PlanItemsCompanion data) {
    return PlanItem(
      id: data.id.present ? data.id.value : this.id,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      block: data.block.present ? data.block.value : this.block,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      repLow: data.repLow.present ? data.repLow.value : this.repLow,
      repHigh: data.repHigh.present ? data.repHigh.value : this.repHigh,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanItem(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('block: $block, ')
          ..write('targetSets: $targetSets, ')
          ..write('repLow: $repLow, ')
          ..write('repHigh: $repHigh, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planDayId,
    exerciseId,
    block,
    targetSets,
    repLow,
    repHigh,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanItem &&
          other.id == this.id &&
          other.planDayId == this.planDayId &&
          other.exerciseId == this.exerciseId &&
          other.block == this.block &&
          other.targetSets == this.targetSets &&
          other.repLow == this.repLow &&
          other.repHigh == this.repHigh &&
          other.notes == this.notes);
}

class PlanItemsCompanion extends UpdateCompanion<PlanItem> {
  final Value<int> id;
  final Value<int> planDayId;
  final Value<int?> exerciseId;
  final Value<TrainingBlock> block;
  final Value<int?> targetSets;
  final Value<int?> repLow;
  final Value<int?> repHigh;
  final Value<String?> notes;
  const PlanItemsCompanion({
    this.id = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.block = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.repLow = const Value.absent(),
    this.repHigh = const Value.absent(),
    this.notes = const Value.absent(),
  });
  PlanItemsCompanion.insert({
    this.id = const Value.absent(),
    required int planDayId,
    this.exerciseId = const Value.absent(),
    required TrainingBlock block,
    this.targetSets = const Value.absent(),
    this.repLow = const Value.absent(),
    this.repHigh = const Value.absent(),
    this.notes = const Value.absent(),
  }) : planDayId = Value(planDayId),
       block = Value(block);
  static Insertable<PlanItem> custom({
    Expression<int>? id,
    Expression<int>? planDayId,
    Expression<int>? exerciseId,
    Expression<String>? block,
    Expression<int>? targetSets,
    Expression<int>? repLow,
    Expression<int>? repHigh,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (block != null) 'block': block,
      if (targetSets != null) 'target_sets': targetSets,
      if (repLow != null) 'rep_low': repLow,
      if (repHigh != null) 'rep_high': repHigh,
      if (notes != null) 'notes': notes,
    });
  }

  PlanItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? planDayId,
    Value<int?>? exerciseId,
    Value<TrainingBlock>? block,
    Value<int?>? targetSets,
    Value<int?>? repLow,
    Value<int?>? repHigh,
    Value<String?>? notes,
  }) {
    return PlanItemsCompanion(
      id: id ?? this.id,
      planDayId: planDayId ?? this.planDayId,
      exerciseId: exerciseId ?? this.exerciseId,
      block: block ?? this.block,
      targetSets: targetSets ?? this.targetSets,
      repLow: repLow ?? this.repLow,
      repHigh: repHigh ?? this.repHigh,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<int>(planDayId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (block.present) {
      map['block'] = Variable<String>(
        $PlanItemsTable.$converterblock.toSql(block.value),
      );
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (repLow.present) {
      map['rep_low'] = Variable<int>(repLow.value);
    }
    if (repHigh.present) {
      map['rep_high'] = Variable<int>(repHigh.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanItemsCompanion(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('block: $block, ')
          ..write('targetSets: $targetSets, ')
          ..write('repLow: $repLow, ')
          ..write('repHigh: $repHigh, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _planDayIdMeta = const VerificationMeta(
    'planDayId',
  );
  @override
  late final GeneratedColumn<int> planDayId = GeneratedColumn<int>(
    'plan_day_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plan_days (id)',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    planDayId,
    startedAt,
    endedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workout> instance, {
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
    if (data.containsKey('plan_day_id')) {
      context.handle(
        _planDayIdMeta,
        planDayId.isAcceptableOrUnknown(data['plan_day_id']!, _planDayIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      planDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_day_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final int id;
  final DateTime date;
  final int? planDayId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;
  const Workout({
    required this.id,
    required this.date,
    this.planDayId,
    required this.startedAt,
    this.endedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || planDayId != null) {
      map['plan_day_id'] = Variable<int>(planDayId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      date: Value(date),
      planDayId: planDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(planDayId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Workout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      planDayId: serializer.fromJson<int?>(json['planDayId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'planDayId': serializer.toJson<int?>(planDayId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Workout copyWith({
    int? id,
    DateTime? date,
    Value<int?> planDayId = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Workout(
    id: id ?? this.id,
    date: date ?? this.date,
    planDayId: planDayId.present ? planDayId.value : this.planDayId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('planDayId: $planDayId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, planDayId, startedAt, endedAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.date == this.date &&
          other.planDayId == this.planDayId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.notes == this.notes);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int?> planDayId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> notes;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.planDayId = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
  }) : date = Value(date),
       startedAt = Value(startedAt);
  static Insertable<Workout> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? planDayId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (notes != null) 'notes': notes,
    });
  }

  WorkoutsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int?>? planDayId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? notes,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      planDayId: planDayId ?? this.planDayId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
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
    if (planDayId.present) {
      map['plan_day_id'] = Variable<int>(planDayId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('planDayId: $planDayId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SetLogsTable extends SetLogs with TableInfo<$SetLogsTable, SetLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workouts (id) ON DELETE CASCADE',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
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
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isWarmupMeta = const VerificationMeta(
    'isWarmup',
  );
  @override
  late final GeneratedColumn<bool> isWarmup = GeneratedColumn<bool>(
    'is_warmup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_warmup" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    exerciseId,
    setIndex,
    weightKg,
    reps,
    rir,
    isWarmup,
    loggedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('is_warmup')) {
      context.handle(
        _isWarmupMeta,
        isWarmup.isAcceptableOrUnknown(data['is_warmup']!, _isWarmupMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rir'],
      ),
      isWarmup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_warmup'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      ),
    );
  }

  @override
  $SetLogsTable createAlias(String alias) {
    return $SetLogsTable(attachedDatabase, alias);
  }
}

class SetLog extends DataClass implements Insertable<SetLog> {
  final int id;
  final int workoutId;
  final int exerciseId;
  final int setIndex;
  final double? weightKg;
  final int reps;
  final int? rir;
  final bool isWarmup;

  /// Wall-clock time the set was recorded.
  ///
  /// Needed to close out a workout that was left open — the session really
  /// ended at its last set, not whenever the app next launched.
  ///
  /// Nullable only because it arrived in schema v2: `ALTER TABLE ADD COLUMN`
  /// cannot fill a NOT NULL column on existing rows, so the migration adds it
  /// nullable and backfills from the parent workout's `startedAt`. Every
  /// insert since v2 supplies it, so null never appears on new rows.
  final DateTime? loggedAt;
  const SetLog({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setIndex,
    this.weightKg,
    required this.reps,
    this.rir,
    required this.isWarmup,
    this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    map['is_warmup'] = Variable<bool>(isWarmup);
    if (!nullToAbsent || loggedAt != null) {
      map['logged_at'] = Variable<DateTime>(loggedAt);
    }
    return map;
  }

  SetLogsCompanion toCompanion(bool nullToAbsent) {
    return SetLogsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      setIndex: Value(setIndex),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      reps: Value(reps),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      isWarmup: Value(isWarmup),
      loggedAt: loggedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(loggedAt),
    );
  }

  factory SetLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetLog(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      reps: serializer.fromJson<int>(json['reps']),
      rir: serializer.fromJson<int?>(json['rir']),
      isWarmup: serializer.fromJson<bool>(json['isWarmup']),
      loggedAt: serializer.fromJson<DateTime?>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'setIndex': serializer.toJson<int>(setIndex),
      'weightKg': serializer.toJson<double?>(weightKg),
      'reps': serializer.toJson<int>(reps),
      'rir': serializer.toJson<int?>(rir),
      'isWarmup': serializer.toJson<bool>(isWarmup),
      'loggedAt': serializer.toJson<DateTime?>(loggedAt),
    };
  }

  SetLog copyWith({
    int? id,
    int? workoutId,
    int? exerciseId,
    int? setIndex,
    Value<double?> weightKg = const Value.absent(),
    int? reps,
    Value<int?> rir = const Value.absent(),
    bool? isWarmup,
    Value<DateTime?> loggedAt = const Value.absent(),
  }) => SetLog(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    reps: reps ?? this.reps,
    rir: rir.present ? rir.value : this.rir,
    isWarmup: isWarmup ?? this.isWarmup,
    loggedAt: loggedAt.present ? loggedAt.value : this.loggedAt,
  );
  SetLog copyWithCompanion(SetLogsCompanion data) {
    return SetLog(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      reps: data.reps.present ? data.reps.value : this.reps,
      rir: data.rir.present ? data.rir.value : this.rir,
      isWarmup: data.isWarmup.present ? data.isWarmup.value : this.isWarmup,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetLog(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    exerciseId,
    setIndex,
    weightKg,
    reps,
    rir,
    isWarmup,
    loggedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetLog &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.setIndex == this.setIndex &&
          other.weightKg == this.weightKg &&
          other.reps == this.reps &&
          other.rir == this.rir &&
          other.isWarmup == this.isWarmup &&
          other.loggedAt == this.loggedAt);
}

class SetLogsCompanion extends UpdateCompanion<SetLog> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<int> exerciseId;
  final Value<int> setIndex;
  final Value<double?> weightKg;
  final Value<int> reps;
  final Value<int?> rir;
  final Value<bool> isWarmup;
  final Value<DateTime?> loggedAt;
  const SetLogsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  SetLogsCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    required int exerciseId,
    required int setIndex,
    this.weightKg = const Value.absent(),
    required int reps,
    this.rir = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.loggedAt = const Value.absent(),
  }) : workoutId = Value(workoutId),
       exerciseId = Value(exerciseId),
       setIndex = Value(setIndex),
       reps = Value(reps);
  static Insertable<SetLog> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<int>? exerciseId,
    Expression<int>? setIndex,
    Expression<double>? weightKg,
    Expression<int>? reps,
    Expression<int>? rir,
    Expression<bool>? isWarmup,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setIndex != null) 'set_index': setIndex,
      if (weightKg != null) 'weight_kg': weightKg,
      if (reps != null) 'reps': reps,
      if (rir != null) 'rir': rir,
      if (isWarmup != null) 'is_warmup': isWarmup,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  SetLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutId,
    Value<int>? exerciseId,
    Value<int>? setIndex,
    Value<double?>? weightKg,
    Value<int>? reps,
    Value<int?>? rir,
    Value<bool>? isWarmup,
    Value<DateTime?>? loggedAt,
  }) {
    return SetLogsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      setIndex: setIndex ?? this.setIndex,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      isWarmup: isWarmup ?? this.isWarmup,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (isWarmup.present) {
      map['is_warmup'] = Variable<bool>(isWarmup.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetLogsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

class $WarmupChecksTable extends WarmupChecks
    with TableInfo<$WarmupChecksTable, WarmupCheck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WarmupChecksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workouts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _planItemIdMeta = const VerificationMeta(
    'planItemId',
  );
  @override
  late final GeneratedColumn<int> planItemId = GeneratedColumn<int>(
    'plan_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plan_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lineIndexMeta = const VerificationMeta(
    'lineIndex',
  );
  @override
  late final GeneratedColumn<int> lineIndex = GeneratedColumn<int>(
    'line_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, workoutId, planItemId, lineIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'warmup_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<WarmupCheck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('plan_item_id')) {
      context.handle(
        _planItemIdMeta,
        planItemId.isAcceptableOrUnknown(
          data['plan_item_id']!,
          _planItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planItemIdMeta);
    }
    if (data.containsKey('line_index')) {
      context.handle(
        _lineIndexMeta,
        lineIndex.isAcceptableOrUnknown(data['line_index']!, _lineIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_lineIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workoutId, planItemId, lineIndex},
  ];
  @override
  WarmupCheck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WarmupCheck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      planItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_item_id'],
      )!,
      lineIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_index'],
      )!,
    );
  }

  @override
  $WarmupChecksTable createAlias(String alias) {
    return $WarmupChecksTable(attachedDatabase, alias);
  }
}

class WarmupCheck extends DataClass implements Insertable<WarmupCheck> {
  final int id;
  final int workoutId;
  final int planItemId;

  /// Which line of the item's `notes` was ticked, counting non-blank lines
  /// from zero — the same order the checklist renders in.
  final int lineIndex;
  const WarmupCheck({
    required this.id,
    required this.workoutId,
    required this.planItemId,
    required this.lineIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    map['plan_item_id'] = Variable<int>(planItemId);
    map['line_index'] = Variable<int>(lineIndex);
    return map;
  }

  WarmupChecksCompanion toCompanion(bool nullToAbsent) {
    return WarmupChecksCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      planItemId: Value(planItemId),
      lineIndex: Value(lineIndex),
    );
  }

  factory WarmupCheck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WarmupCheck(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      planItemId: serializer.fromJson<int>(json['planItemId']),
      lineIndex: serializer.fromJson<int>(json['lineIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'planItemId': serializer.toJson<int>(planItemId),
      'lineIndex': serializer.toJson<int>(lineIndex),
    };
  }

  WarmupCheck copyWith({
    int? id,
    int? workoutId,
    int? planItemId,
    int? lineIndex,
  }) => WarmupCheck(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    planItemId: planItemId ?? this.planItemId,
    lineIndex: lineIndex ?? this.lineIndex,
  );
  WarmupCheck copyWithCompanion(WarmupChecksCompanion data) {
    return WarmupCheck(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      planItemId: data.planItemId.present
          ? data.planItemId.value
          : this.planItemId,
      lineIndex: data.lineIndex.present ? data.lineIndex.value : this.lineIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WarmupCheck(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('planItemId: $planItemId, ')
          ..write('lineIndex: $lineIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutId, planItemId, lineIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WarmupCheck &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.planItemId == this.planItemId &&
          other.lineIndex == this.lineIndex);
}

class WarmupChecksCompanion extends UpdateCompanion<WarmupCheck> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<int> planItemId;
  final Value<int> lineIndex;
  const WarmupChecksCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.planItemId = const Value.absent(),
    this.lineIndex = const Value.absent(),
  });
  WarmupChecksCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    required int planItemId,
    required int lineIndex,
  }) : workoutId = Value(workoutId),
       planItemId = Value(planItemId),
       lineIndex = Value(lineIndex);
  static Insertable<WarmupCheck> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<int>? planItemId,
    Expression<int>? lineIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (planItemId != null) 'plan_item_id': planItemId,
      if (lineIndex != null) 'line_index': lineIndex,
    });
  }

  WarmupChecksCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutId,
    Value<int>? planItemId,
    Value<int>? lineIndex,
  }) {
    return WarmupChecksCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      planItemId: planItemId ?? this.planItemId,
      lineIndex: lineIndex ?? this.lineIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (planItemId.present) {
      map['plan_item_id'] = Variable<int>(planItemId.value);
    }
    if (lineIndex.present) {
      map['line_index'] = Variable<int>(lineIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WarmupChecksCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('planItemId: $planItemId, ')
          ..write('lineIndex: $lineIndex')
          ..write(')'))
        .toString();
  }
}

class $FoodsTable extends Foods with TableInfo<$FoodsTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameLocalMeta = const VerificationMeta(
    'nameLocal',
  );
  @override
  late final GeneratedColumn<String> nameLocal = GeneratedColumn<String>(
    'name_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FoodSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FoodSource>($FoodsTable.$convertersource);
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRecipeMeta = const VerificationMeta(
    'isRecipe',
  );
  @override
  late final GeneratedColumn<bool> isRecipe = GeneratedColumn<bool>(
    'is_recipe',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recipe" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _kcal100Meta = const VerificationMeta(
    'kcal100',
  );
  @override
  late final GeneratedColumn<double> kcal100 = GeneratedColumn<double>(
    'kcal100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protein100Meta = const VerificationMeta(
    'protein100',
  );
  @override
  late final GeneratedColumn<double> protein100 = GeneratedColumn<double>(
    'protein100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbs100Meta = const VerificationMeta(
    'carbs100',
  );
  @override
  late final GeneratedColumn<double> carbs100 = GeneratedColumn<double>(
    'carbs100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fat100Meta = const VerificationMeta('fat100');
  @override
  late final GeneratedColumn<double> fat100 = GeneratedColumn<double>(
    'fat100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fibre100Meta = const VerificationMeta(
    'fibre100',
  );
  @override
  late final GeneratedColumn<double> fibre100 = GeneratedColumn<double>(
    'fibre100',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sugar100Meta = const VerificationMeta(
    'sugar100',
  );
  @override
  late final GeneratedColumn<double> sugar100 = GeneratedColumn<double>(
    'sugar100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _satFat100Meta = const VerificationMeta(
    'satFat100',
  );
  @override
  late final GeneratedColumn<double> satFat100 = GeneratedColumn<double>(
    'sat_fat100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sodium100Meta = const VerificationMeta(
    'sodium100',
  );
  @override
  late final GeneratedColumn<double> sodium100 = GeneratedColumn<double>(
    'sodium100',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameLocal,
    brand,
    source,
    barcode,
    isRecipe,
    kcal100,
    protein100,
    carbs100,
    fat100,
    fibre100,
    sugar100,
    satFat100,
    sodium100,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Food> instance, {
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
    if (data.containsKey('name_local')) {
      context.handle(
        _nameLocalMeta,
        nameLocal.isAcceptableOrUnknown(data['name_local']!, _nameLocalMeta),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('is_recipe')) {
      context.handle(
        _isRecipeMeta,
        isRecipe.isAcceptableOrUnknown(data['is_recipe']!, _isRecipeMeta),
      );
    }
    if (data.containsKey('kcal100')) {
      context.handle(
        _kcal100Meta,
        kcal100.isAcceptableOrUnknown(data['kcal100']!, _kcal100Meta),
      );
    } else if (isInserting) {
      context.missing(_kcal100Meta);
    }
    if (data.containsKey('protein100')) {
      context.handle(
        _protein100Meta,
        protein100.isAcceptableOrUnknown(data['protein100']!, _protein100Meta),
      );
    } else if (isInserting) {
      context.missing(_protein100Meta);
    }
    if (data.containsKey('carbs100')) {
      context.handle(
        _carbs100Meta,
        carbs100.isAcceptableOrUnknown(data['carbs100']!, _carbs100Meta),
      );
    } else if (isInserting) {
      context.missing(_carbs100Meta);
    }
    if (data.containsKey('fat100')) {
      context.handle(
        _fat100Meta,
        fat100.isAcceptableOrUnknown(data['fat100']!, _fat100Meta),
      );
    } else if (isInserting) {
      context.missing(_fat100Meta);
    }
    if (data.containsKey('fibre100')) {
      context.handle(
        _fibre100Meta,
        fibre100.isAcceptableOrUnknown(data['fibre100']!, _fibre100Meta),
      );
    } else if (isInserting) {
      context.missing(_fibre100Meta);
    }
    if (data.containsKey('sugar100')) {
      context.handle(
        _sugar100Meta,
        sugar100.isAcceptableOrUnknown(data['sugar100']!, _sugar100Meta),
      );
    }
    if (data.containsKey('sat_fat100')) {
      context.handle(
        _satFat100Meta,
        satFat100.isAcceptableOrUnknown(data['sat_fat100']!, _satFat100Meta),
      );
    }
    if (data.containsKey('sodium100')) {
      context.handle(
        _sodium100Meta,
        sodium100.isAcceptableOrUnknown(data['sodium100']!, _sodium100Meta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_local'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      source: $FoodsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      isRecipe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recipe'],
      )!,
      kcal100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal100'],
      )!,
      protein100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein100'],
      )!,
      carbs100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs100'],
      )!,
      fat100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat100'],
      )!,
      fibre100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fibre100'],
      )!,
      sugar100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar100'],
      ),
      satFat100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sat_fat100'],
      ),
      sodium100: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium100'],
      ),
    );
  }

  @override
  $FoodsTable createAlias(String alias) {
    return $FoodsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FoodSource, String, String> $convertersource =
      const EnumNameConverter<FoodSource>(FoodSource.values);
}

class Food extends DataClass implements Insertable<Food> {
  final int id;
  final String name;
  final String? nameLocal;
  final String? brand;
  final FoodSource source;
  final String? barcode;
  final bool isRecipe;
  final double kcal100;
  final double protein100;
  final double carbs100;
  final double fat100;
  final double fibre100;
  final double? sugar100;
  final double? satFat100;
  final double? sodium100;
  const Food({
    required this.id,
    required this.name,
    this.nameLocal,
    this.brand,
    required this.source,
    this.barcode,
    required this.isRecipe,
    required this.kcal100,
    required this.protein100,
    required this.carbs100,
    required this.fat100,
    required this.fibre100,
    this.sugar100,
    this.satFat100,
    this.sodium100,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nameLocal != null) {
      map['name_local'] = Variable<String>(nameLocal);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    {
      map['source'] = Variable<String>(
        $FoodsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['is_recipe'] = Variable<bool>(isRecipe);
    map['kcal100'] = Variable<double>(kcal100);
    map['protein100'] = Variable<double>(protein100);
    map['carbs100'] = Variable<double>(carbs100);
    map['fat100'] = Variable<double>(fat100);
    map['fibre100'] = Variable<double>(fibre100);
    if (!nullToAbsent || sugar100 != null) {
      map['sugar100'] = Variable<double>(sugar100);
    }
    if (!nullToAbsent || satFat100 != null) {
      map['sat_fat100'] = Variable<double>(satFat100);
    }
    if (!nullToAbsent || sodium100 != null) {
      map['sodium100'] = Variable<double>(sodium100);
    }
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      id: Value(id),
      name: Value(name),
      nameLocal: nameLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(nameLocal),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      source: Value(source),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      isRecipe: Value(isRecipe),
      kcal100: Value(kcal100),
      protein100: Value(protein100),
      carbs100: Value(carbs100),
      fat100: Value(fat100),
      fibre100: Value(fibre100),
      sugar100: sugar100 == null && nullToAbsent
          ? const Value.absent()
          : Value(sugar100),
      satFat100: satFat100 == null && nullToAbsent
          ? const Value.absent()
          : Value(satFat100),
      sodium100: sodium100 == null && nullToAbsent
          ? const Value.absent()
          : Value(sodium100),
    );
  }

  factory Food.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameLocal: serializer.fromJson<String?>(json['nameLocal']),
      brand: serializer.fromJson<String?>(json['brand']),
      source: $FoodsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      barcode: serializer.fromJson<String?>(json['barcode']),
      isRecipe: serializer.fromJson<bool>(json['isRecipe']),
      kcal100: serializer.fromJson<double>(json['kcal100']),
      protein100: serializer.fromJson<double>(json['protein100']),
      carbs100: serializer.fromJson<double>(json['carbs100']),
      fat100: serializer.fromJson<double>(json['fat100']),
      fibre100: serializer.fromJson<double>(json['fibre100']),
      sugar100: serializer.fromJson<double?>(json['sugar100']),
      satFat100: serializer.fromJson<double?>(json['satFat100']),
      sodium100: serializer.fromJson<double?>(json['sodium100']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nameLocal': serializer.toJson<String?>(nameLocal),
      'brand': serializer.toJson<String?>(brand),
      'source': serializer.toJson<String>(
        $FoodsTable.$convertersource.toJson(source),
      ),
      'barcode': serializer.toJson<String?>(barcode),
      'isRecipe': serializer.toJson<bool>(isRecipe),
      'kcal100': serializer.toJson<double>(kcal100),
      'protein100': serializer.toJson<double>(protein100),
      'carbs100': serializer.toJson<double>(carbs100),
      'fat100': serializer.toJson<double>(fat100),
      'fibre100': serializer.toJson<double>(fibre100),
      'sugar100': serializer.toJson<double?>(sugar100),
      'satFat100': serializer.toJson<double?>(satFat100),
      'sodium100': serializer.toJson<double?>(sodium100),
    };
  }

  Food copyWith({
    int? id,
    String? name,
    Value<String?> nameLocal = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    FoodSource? source,
    Value<String?> barcode = const Value.absent(),
    bool? isRecipe,
    double? kcal100,
    double? protein100,
    double? carbs100,
    double? fat100,
    double? fibre100,
    Value<double?> sugar100 = const Value.absent(),
    Value<double?> satFat100 = const Value.absent(),
    Value<double?> sodium100 = const Value.absent(),
  }) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    nameLocal: nameLocal.present ? nameLocal.value : this.nameLocal,
    brand: brand.present ? brand.value : this.brand,
    source: source ?? this.source,
    barcode: barcode.present ? barcode.value : this.barcode,
    isRecipe: isRecipe ?? this.isRecipe,
    kcal100: kcal100 ?? this.kcal100,
    protein100: protein100 ?? this.protein100,
    carbs100: carbs100 ?? this.carbs100,
    fat100: fat100 ?? this.fat100,
    fibre100: fibre100 ?? this.fibre100,
    sugar100: sugar100.present ? sugar100.value : this.sugar100,
    satFat100: satFat100.present ? satFat100.value : this.satFat100,
    sodium100: sodium100.present ? sodium100.value : this.sodium100,
  );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameLocal: data.nameLocal.present ? data.nameLocal.value : this.nameLocal,
      brand: data.brand.present ? data.brand.value : this.brand,
      source: data.source.present ? data.source.value : this.source,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      isRecipe: data.isRecipe.present ? data.isRecipe.value : this.isRecipe,
      kcal100: data.kcal100.present ? data.kcal100.value : this.kcal100,
      protein100: data.protein100.present
          ? data.protein100.value
          : this.protein100,
      carbs100: data.carbs100.present ? data.carbs100.value : this.carbs100,
      fat100: data.fat100.present ? data.fat100.value : this.fat100,
      fibre100: data.fibre100.present ? data.fibre100.value : this.fibre100,
      sugar100: data.sugar100.present ? data.sugar100.value : this.sugar100,
      satFat100: data.satFat100.present ? data.satFat100.value : this.satFat100,
      sodium100: data.sodium100.present ? data.sodium100.value : this.sodium100,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLocal: $nameLocal, ')
          ..write('brand: $brand, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('isRecipe: $isRecipe, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carbs100: $carbs100, ')
          ..write('fat100: $fat100, ')
          ..write('fibre100: $fibre100, ')
          ..write('sugar100: $sugar100, ')
          ..write('satFat100: $satFat100, ')
          ..write('sodium100: $sodium100')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    nameLocal,
    brand,
    source,
    barcode,
    isRecipe,
    kcal100,
    protein100,
    carbs100,
    fat100,
    fibre100,
    sugar100,
    satFat100,
    sodium100,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameLocal == this.nameLocal &&
          other.brand == this.brand &&
          other.source == this.source &&
          other.barcode == this.barcode &&
          other.isRecipe == this.isRecipe &&
          other.kcal100 == this.kcal100 &&
          other.protein100 == this.protein100 &&
          other.carbs100 == this.carbs100 &&
          other.fat100 == this.fat100 &&
          other.fibre100 == this.fibre100 &&
          other.sugar100 == this.sugar100 &&
          other.satFat100 == this.satFat100 &&
          other.sodium100 == this.sodium100);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> nameLocal;
  final Value<String?> brand;
  final Value<FoodSource> source;
  final Value<String?> barcode;
  final Value<bool> isRecipe;
  final Value<double> kcal100;
  final Value<double> protein100;
  final Value<double> carbs100;
  final Value<double> fat100;
  final Value<double> fibre100;
  final Value<double?> sugar100;
  final Value<double?> satFat100;
  final Value<double?> sodium100;
  const FoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameLocal = const Value.absent(),
    this.brand = const Value.absent(),
    this.source = const Value.absent(),
    this.barcode = const Value.absent(),
    this.isRecipe = const Value.absent(),
    this.kcal100 = const Value.absent(),
    this.protein100 = const Value.absent(),
    this.carbs100 = const Value.absent(),
    this.fat100 = const Value.absent(),
    this.fibre100 = const Value.absent(),
    this.sugar100 = const Value.absent(),
    this.satFat100 = const Value.absent(),
    this.sodium100 = const Value.absent(),
  });
  FoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.nameLocal = const Value.absent(),
    this.brand = const Value.absent(),
    required FoodSource source,
    this.barcode = const Value.absent(),
    this.isRecipe = const Value.absent(),
    required double kcal100,
    required double protein100,
    required double carbs100,
    required double fat100,
    required double fibre100,
    this.sugar100 = const Value.absent(),
    this.satFat100 = const Value.absent(),
    this.sodium100 = const Value.absent(),
  }) : name = Value(name),
       source = Value(source),
       kcal100 = Value(kcal100),
       protein100 = Value(protein100),
       carbs100 = Value(carbs100),
       fat100 = Value(fat100),
       fibre100 = Value(fibre100);
  static Insertable<Food> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nameLocal,
    Expression<String>? brand,
    Expression<String>? source,
    Expression<String>? barcode,
    Expression<bool>? isRecipe,
    Expression<double>? kcal100,
    Expression<double>? protein100,
    Expression<double>? carbs100,
    Expression<double>? fat100,
    Expression<double>? fibre100,
    Expression<double>? sugar100,
    Expression<double>? satFat100,
    Expression<double>? sodium100,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameLocal != null) 'name_local': nameLocal,
      if (brand != null) 'brand': brand,
      if (source != null) 'source': source,
      if (barcode != null) 'barcode': barcode,
      if (isRecipe != null) 'is_recipe': isRecipe,
      if (kcal100 != null) 'kcal100': kcal100,
      if (protein100 != null) 'protein100': protein100,
      if (carbs100 != null) 'carbs100': carbs100,
      if (fat100 != null) 'fat100': fat100,
      if (fibre100 != null) 'fibre100': fibre100,
      if (sugar100 != null) 'sugar100': sugar100,
      if (satFat100 != null) 'sat_fat100': satFat100,
      if (sodium100 != null) 'sodium100': sodium100,
    });
  }

  FoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? nameLocal,
    Value<String?>? brand,
    Value<FoodSource>? source,
    Value<String?>? barcode,
    Value<bool>? isRecipe,
    Value<double>? kcal100,
    Value<double>? protein100,
    Value<double>? carbs100,
    Value<double>? fat100,
    Value<double>? fibre100,
    Value<double?>? sugar100,
    Value<double?>? satFat100,
    Value<double?>? sodium100,
  }) {
    return FoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLocal: nameLocal ?? this.nameLocal,
      brand: brand ?? this.brand,
      source: source ?? this.source,
      barcode: barcode ?? this.barcode,
      isRecipe: isRecipe ?? this.isRecipe,
      kcal100: kcal100 ?? this.kcal100,
      protein100: protein100 ?? this.protein100,
      carbs100: carbs100 ?? this.carbs100,
      fat100: fat100 ?? this.fat100,
      fibre100: fibre100 ?? this.fibre100,
      sugar100: sugar100 ?? this.sugar100,
      satFat100: satFat100 ?? this.satFat100,
      sodium100: sodium100 ?? this.sodium100,
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
    if (nameLocal.present) {
      map['name_local'] = Variable<String>(nameLocal.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $FoodsTable.$convertersource.toSql(source.value),
      );
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (isRecipe.present) {
      map['is_recipe'] = Variable<bool>(isRecipe.value);
    }
    if (kcal100.present) {
      map['kcal100'] = Variable<double>(kcal100.value);
    }
    if (protein100.present) {
      map['protein100'] = Variable<double>(protein100.value);
    }
    if (carbs100.present) {
      map['carbs100'] = Variable<double>(carbs100.value);
    }
    if (fat100.present) {
      map['fat100'] = Variable<double>(fat100.value);
    }
    if (fibre100.present) {
      map['fibre100'] = Variable<double>(fibre100.value);
    }
    if (sugar100.present) {
      map['sugar100'] = Variable<double>(sugar100.value);
    }
    if (satFat100.present) {
      map['sat_fat100'] = Variable<double>(satFat100.value);
    }
    if (sodium100.present) {
      map['sodium100'] = Variable<double>(sodium100.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLocal: $nameLocal, ')
          ..write('brand: $brand, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('isRecipe: $isRecipe, ')
          ..write('kcal100: $kcal100, ')
          ..write('protein100: $protein100, ')
          ..write('carbs100: $carbs100, ')
          ..write('fat100: $fat100, ')
          ..write('fibre100: $fibre100, ')
          ..write('sugar100: $sugar100, ')
          ..write('satFat100: $satFat100, ')
          ..write('sodium100: $sodium100')
          ..write(')'))
        .toString();
  }
}

class $ServingsTable extends Servings with TableInfo<$ServingsTable, Serving> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServingsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, foodId, label, grams, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Serving> instance, {
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
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Serving map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Serving(
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
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $ServingsTable createAlias(String alias) {
    return $ServingsTable(attachedDatabase, alias);
  }
}

class Serving extends DataClass implements Insertable<Serving> {
  final int id;
  final int foodId;
  final String label;
  final double grams;
  final bool isDefault;
  const Serving({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['food_id'] = Variable<int>(foodId);
    map['label'] = Variable<String>(label);
    map['grams'] = Variable<double>(grams);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  ServingsCompanion toCompanion(bool nullToAbsent) {
    return ServingsCompanion(
      id: Value(id),
      foodId: Value(foodId),
      label: Value(label),
      grams: Value(grams),
      isDefault: Value(isDefault),
    );
  }

  factory Serving.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Serving(
      id: serializer.fromJson<int>(json['id']),
      foodId: serializer.fromJson<int>(json['foodId']),
      label: serializer.fromJson<String>(json['label']),
      grams: serializer.fromJson<double>(json['grams']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
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
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  Serving copyWith({
    int? id,
    int? foodId,
    String? label,
    double? grams,
    bool? isDefault,
  }) => Serving(
    id: id ?? this.id,
    foodId: foodId ?? this.foodId,
    label: label ?? this.label,
    grams: grams ?? this.grams,
    isDefault: isDefault ?? this.isDefault,
  );
  Serving copyWithCompanion(ServingsCompanion data) {
    return Serving(
      id: data.id.present ? data.id.value : this.id,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      label: data.label.present ? data.label.value : this.label,
      grams: data.grams.present ? data.grams.value : this.grams,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Serving(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, foodId, label, grams, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Serving &&
          other.id == this.id &&
          other.foodId == this.foodId &&
          other.label == this.label &&
          other.grams == this.grams &&
          other.isDefault == this.isDefault);
}

class ServingsCompanion extends UpdateCompanion<Serving> {
  final Value<int> id;
  final Value<int> foodId;
  final Value<String> label;
  final Value<double> grams;
  final Value<bool> isDefault;
  const ServingsCompanion({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.label = const Value.absent(),
    this.grams = const Value.absent(),
    this.isDefault = const Value.absent(),
  });
  ServingsCompanion.insert({
    this.id = const Value.absent(),
    required int foodId,
    required String label,
    required double grams,
    this.isDefault = const Value.absent(),
  }) : foodId = Value(foodId),
       label = Value(label),
       grams = Value(grams);
  static Insertable<Serving> custom({
    Expression<int>? id,
    Expression<int>? foodId,
    Expression<String>? label,
    Expression<double>? grams,
    Expression<bool>? isDefault,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (label != null) 'label': label,
      if (grams != null) 'grams': grams,
      if (isDefault != null) 'is_default': isDefault,
    });
  }

  ServingsCompanion copyWith({
    Value<int>? id,
    Value<int>? foodId,
    Value<String>? label,
    Value<double>? grams,
    Value<bool>? isDefault,
  }) {
    return ServingsCompanion(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      label: label ?? this.label,
      grams: grams ?? this.grams,
      isDefault: isDefault ?? this.isDefault,
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
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServingsCompanion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('label: $label, ')
          ..write('grams: $grams, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }
}

class $RecipeItemsTable extends RecipeItems
    with TableInfo<$RecipeItemsTable, RecipeItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recipeFoodIdMeta = const VerificationMeta(
    'recipeFoodId',
  );
  @override
  late final GeneratedColumn<int> recipeFoodId = GeneratedColumn<int>(
    'recipe_food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ingredientFoodIdMeta = const VerificationMeta(
    'ingredientFoodId',
  );
  @override
  late final GeneratedColumn<int> ingredientFoodId = GeneratedColumn<int>(
    'ingredient_food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id)',
    ),
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
  List<GeneratedColumn> get $columns => [
    id,
    recipeFoodId,
    ingredientFoodId,
    grams,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_food_id')) {
      context.handle(
        _recipeFoodIdMeta,
        recipeFoodId.isAcceptableOrUnknown(
          data['recipe_food_id']!,
          _recipeFoodIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipeFoodIdMeta);
    }
    if (data.containsKey('ingredient_food_id')) {
      context.handle(
        _ingredientFoodIdMeta,
        ingredientFoodId.isAcceptableOrUnknown(
          data['ingredient_food_id']!,
          _ingredientFoodIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientFoodIdMeta);
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
  RecipeItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recipeFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_food_id'],
      )!,
      ingredientFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingredient_food_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
    );
  }

  @override
  $RecipeItemsTable createAlias(String alias) {
    return $RecipeItemsTable(attachedDatabase, alias);
  }
}

class RecipeItem extends DataClass implements Insertable<RecipeItem> {
  final int id;
  final int recipeFoodId;
  final int ingredientFoodId;
  final double grams;
  const RecipeItem({
    required this.id,
    required this.recipeFoodId,
    required this.ingredientFoodId,
    required this.grams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipe_food_id'] = Variable<int>(recipeFoodId);
    map['ingredient_food_id'] = Variable<int>(ingredientFoodId);
    map['grams'] = Variable<double>(grams);
    return map;
  }

  RecipeItemsCompanion toCompanion(bool nullToAbsent) {
    return RecipeItemsCompanion(
      id: Value(id),
      recipeFoodId: Value(recipeFoodId),
      ingredientFoodId: Value(ingredientFoodId),
      grams: Value(grams),
    );
  }

  factory RecipeItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeItem(
      id: serializer.fromJson<int>(json['id']),
      recipeFoodId: serializer.fromJson<int>(json['recipeFoodId']),
      ingredientFoodId: serializer.fromJson<int>(json['ingredientFoodId']),
      grams: serializer.fromJson<double>(json['grams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipeFoodId': serializer.toJson<int>(recipeFoodId),
      'ingredientFoodId': serializer.toJson<int>(ingredientFoodId),
      'grams': serializer.toJson<double>(grams),
    };
  }

  RecipeItem copyWith({
    int? id,
    int? recipeFoodId,
    int? ingredientFoodId,
    double? grams,
  }) => RecipeItem(
    id: id ?? this.id,
    recipeFoodId: recipeFoodId ?? this.recipeFoodId,
    ingredientFoodId: ingredientFoodId ?? this.ingredientFoodId,
    grams: grams ?? this.grams,
  );
  RecipeItem copyWithCompanion(RecipeItemsCompanion data) {
    return RecipeItem(
      id: data.id.present ? data.id.value : this.id,
      recipeFoodId: data.recipeFoodId.present
          ? data.recipeFoodId.value
          : this.recipeFoodId,
      ingredientFoodId: data.ingredientFoodId.present
          ? data.ingredientFoodId.value
          : this.ingredientFoodId,
      grams: data.grams.present ? data.grams.value : this.grams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeItem(')
          ..write('id: $id, ')
          ..write('recipeFoodId: $recipeFoodId, ')
          ..write('ingredientFoodId: $ingredientFoodId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeFoodId, ingredientFoodId, grams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeItem &&
          other.id == this.id &&
          other.recipeFoodId == this.recipeFoodId &&
          other.ingredientFoodId == this.ingredientFoodId &&
          other.grams == this.grams);
}

class RecipeItemsCompanion extends UpdateCompanion<RecipeItem> {
  final Value<int> id;
  final Value<int> recipeFoodId;
  final Value<int> ingredientFoodId;
  final Value<double> grams;
  const RecipeItemsCompanion({
    this.id = const Value.absent(),
    this.recipeFoodId = const Value.absent(),
    this.ingredientFoodId = const Value.absent(),
    this.grams = const Value.absent(),
  });
  RecipeItemsCompanion.insert({
    this.id = const Value.absent(),
    required int recipeFoodId,
    required int ingredientFoodId,
    required double grams,
  }) : recipeFoodId = Value(recipeFoodId),
       ingredientFoodId = Value(ingredientFoodId),
       grams = Value(grams);
  static Insertable<RecipeItem> custom({
    Expression<int>? id,
    Expression<int>? recipeFoodId,
    Expression<int>? ingredientFoodId,
    Expression<double>? grams,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeFoodId != null) 'recipe_food_id': recipeFoodId,
      if (ingredientFoodId != null) 'ingredient_food_id': ingredientFoodId,
      if (grams != null) 'grams': grams,
    });
  }

  RecipeItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? recipeFoodId,
    Value<int>? ingredientFoodId,
    Value<double>? grams,
  }) {
    return RecipeItemsCompanion(
      id: id ?? this.id,
      recipeFoodId: recipeFoodId ?? this.recipeFoodId,
      ingredientFoodId: ingredientFoodId ?? this.ingredientFoodId,
      grams: grams ?? this.grams,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipeFoodId.present) {
      map['recipe_food_id'] = Variable<int>(recipeFoodId.value);
    }
    if (ingredientFoodId.present) {
      map['ingredient_food_id'] = Variable<int>(ingredientFoodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeItemsCompanion(')
          ..write('id: $id, ')
          ..write('recipeFoodId: $recipeFoodId, ')
          ..write('ingredientFoodId: $ingredientFoodId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }
}

class $FoodLogsTable extends FoodLogs with TableInfo<$FoodLogsTable, FoodLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodLogsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<Meal, String> meal =
      GeneratedColumn<String>(
        'meal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Meal>($FoodLogsTable.$convertermeal);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id)',
    ),
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
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    meal,
    foodId,
    grams,
    loggedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodLog> instance, {
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
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      meal: $FoodLogsTable.$convertermeal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal'],
        )!,
      ),
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
    );
  }

  @override
  $FoodLogsTable createAlias(String alias) {
    return $FoodLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Meal, String, String> $convertermeal =
      const EnumNameConverter<Meal>(Meal.values);
}

class FoodLog extends DataClass implements Insertable<FoodLog> {
  final int id;
  final DateTime date;
  final Meal meal;
  final int foodId;
  final double grams;
  final DateTime loggedAt;
  const FoodLog({
    required this.id,
    required this.date,
    required this.meal,
    required this.foodId,
    required this.grams,
    required this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    {
      map['meal'] = Variable<String>($FoodLogsTable.$convertermeal.toSql(meal));
    }
    map['food_id'] = Variable<int>(foodId);
    map['grams'] = Variable<double>(grams);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  FoodLogsCompanion toCompanion(bool nullToAbsent) {
    return FoodLogsCompanion(
      id: Value(id),
      date: Value(date),
      meal: Value(meal),
      foodId: Value(foodId),
      grams: Value(grams),
      loggedAt: Value(loggedAt),
    );
  }

  factory FoodLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      meal: $FoodLogsTable.$convertermeal.fromJson(
        serializer.fromJson<String>(json['meal']),
      ),
      foodId: serializer.fromJson<int>(json['foodId']),
      grams: serializer.fromJson<double>(json['grams']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'meal': serializer.toJson<String>(
        $FoodLogsTable.$convertermeal.toJson(meal),
      ),
      'foodId': serializer.toJson<int>(foodId),
      'grams': serializer.toJson<double>(grams),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  FoodLog copyWith({
    int? id,
    DateTime? date,
    Meal? meal,
    int? foodId,
    double? grams,
    DateTime? loggedAt,
  }) => FoodLog(
    id: id ?? this.id,
    date: date ?? this.date,
    meal: meal ?? this.meal,
    foodId: foodId ?? this.foodId,
    grams: grams ?? this.grams,
    loggedAt: loggedAt ?? this.loggedAt,
  );
  FoodLog copyWithCompanion(FoodLogsCompanion data) {
    return FoodLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      meal: data.meal.present ? data.meal.value : this.meal,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      grams: data.grams.present ? data.grams.value : this.grams,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, meal, foodId, grams, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.meal == this.meal &&
          other.foodId == this.foodId &&
          other.grams == this.grams &&
          other.loggedAt == this.loggedAt);
}

class FoodLogsCompanion extends UpdateCompanion<FoodLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<Meal> meal;
  final Value<int> foodId;
  final Value<double> grams;
  final Value<DateTime> loggedAt;
  const FoodLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.meal = const Value.absent(),
    this.foodId = const Value.absent(),
    this.grams = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  FoodLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required Meal meal,
    required int foodId,
    required double grams,
    required DateTime loggedAt,
  }) : date = Value(date),
       meal = Value(meal),
       foodId = Value(foodId),
       grams = Value(grams),
       loggedAt = Value(loggedAt);
  static Insertable<FoodLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? meal,
    Expression<int>? foodId,
    Expression<double>? grams,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (meal != null) 'meal': meal,
      if (foodId != null) 'food_id': foodId,
      if (grams != null) 'grams': grams,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  FoodLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<Meal>? meal,
    Value<int>? foodId,
    Value<double>? grams,
    Value<DateTime>? loggedAt,
  }) {
    return FoodLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      meal: meal ?? this.meal,
      foodId: foodId ?? this.foodId,
      grams: grams ?? this.grams,
      loggedAt: loggedAt ?? this.loggedAt,
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
    if (meal.present) {
      map['meal'] = Variable<String>(
        $FoodLogsTable.$convertermeal.toSql(meal.value),
      );
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('meal: $meal, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyStepsTable extends DailySteps
    with TableInfo<$DailyStepsTable, DailyStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStepsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _activeKcalMeta = const VerificationMeta(
    'activeKcal',
  );
  @override
  late final GeneratedColumn<double> activeKcal = GeneratedColumn<double>(
    'active_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [date, steps, activeKcal, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStep> instance, {
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
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    if (data.containsKey('active_kcal')) {
      context.handle(
        _activeKcalMeta,
        activeKcal.isAcceptableOrUnknown(data['active_kcal']!, _activeKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_activeKcalMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStep(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
      activeKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}active_kcal'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DailyStepsTable createAlias(String alias) {
    return $DailyStepsTable(attachedDatabase, alias);
  }
}

class DailyStep extends DataClass implements Insertable<DailyStep> {
  final DateTime date;
  final int steps;
  final double activeKcal;
  final String source;
  const DailyStep({
    required this.date,
    required this.steps,
    required this.activeKcal,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<DateTime>(date);
    map['steps'] = Variable<int>(steps);
    map['active_kcal'] = Variable<double>(activeKcal);
    map['source'] = Variable<String>(source);
    return map;
  }

  DailyStepsCompanion toCompanion(bool nullToAbsent) {
    return DailyStepsCompanion(
      date: Value(date),
      steps: Value(steps),
      activeKcal: Value(activeKcal),
      source: Value(source),
    );
  }

  factory DailyStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStep(
      date: serializer.fromJson<DateTime>(json['date']),
      steps: serializer.fromJson<int>(json['steps']),
      activeKcal: serializer.fromJson<double>(json['activeKcal']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'steps': serializer.toJson<int>(steps),
      'activeKcal': serializer.toJson<double>(activeKcal),
      'source': serializer.toJson<String>(source),
    };
  }

  DailyStep copyWith({
    DateTime? date,
    int? steps,
    double? activeKcal,
    String? source,
  }) => DailyStep(
    date: date ?? this.date,
    steps: steps ?? this.steps,
    activeKcal: activeKcal ?? this.activeKcal,
    source: source ?? this.source,
  );
  DailyStep copyWithCompanion(DailyStepsCompanion data) {
    return DailyStep(
      date: data.date.present ? data.date.value : this.date,
      steps: data.steps.present ? data.steps.value : this.steps,
      activeKcal: data.activeKcal.present
          ? data.activeKcal.value
          : this.activeKcal,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStep(')
          ..write('date: $date, ')
          ..write('steps: $steps, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, steps, activeKcal, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStep &&
          other.date == this.date &&
          other.steps == this.steps &&
          other.activeKcal == this.activeKcal &&
          other.source == this.source);
}

class DailyStepsCompanion extends UpdateCompanion<DailyStep> {
  final Value<DateTime> date;
  final Value<int> steps;
  final Value<double> activeKcal;
  final Value<String> source;
  final Value<int> rowid;
  const DailyStepsCompanion({
    this.date = const Value.absent(),
    this.steps = const Value.absent(),
    this.activeKcal = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyStepsCompanion.insert({
    required DateTime date,
    required int steps,
    required double activeKcal,
    required String source,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       steps = Value(steps),
       activeKcal = Value(activeKcal),
       source = Value(source);
  static Insertable<DailyStep> custom({
    Expression<DateTime>? date,
    Expression<int>? steps,
    Expression<double>? activeKcal,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (steps != null) 'steps': steps,
      if (activeKcal != null) 'active_kcal': activeKcal,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyStepsCompanion copyWith({
    Value<DateTime>? date,
    Value<int>? steps,
    Value<double>? activeKcal,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return DailyStepsCompanion(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      activeKcal: activeKcal ?? this.activeKcal,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (activeKcal.present) {
      map['active_kcal'] = Variable<double>(activeKcal.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStepsCompanion(')
          ..write('date: $date, ')
          ..write('steps: $steps, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunsTable extends Runs with TableInfo<$RunsTable, Run> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movingSMeta = const VerificationMeta(
    'movingS',
  );
  @override
  late final GeneratedColumn<int> movingS = GeneratedColumn<int>(
    'moving_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedSMeta = const VerificationMeta(
    'elapsedS',
  );
  @override
  late final GeneratedColumn<int> elapsedS = GeneratedColumn<int>(
    'elapsed_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevGainMMeta = const VerificationMeta(
    'elevGainM',
  );
  @override
  late final GeneratedColumn<double> elevGainM = GeneratedColumn<double>(
    'elev_gain_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgPaceSPerKmMeta = const VerificationMeta(
    'avgPaceSPerKm',
  );
  @override
  late final GeneratedColumn<double> avgPaceSPerKm = GeneratedColumn<double>(
    'avg_pace_s_per_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _polylineMeta = const VerificationMeta(
    'polyline',
  );
  @override
  late final GeneratedColumn<String> polyline = GeneratedColumn<String>(
    'polyline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgHrBpmMeta = const VerificationMeta(
    'avgHrBpm',
  );
  @override
  late final GeneratedColumn<int> avgHrBpm = GeneratedColumn<int>(
    'avg_hr_bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHrBpmMeta = const VerificationMeta(
    'maxHrBpm',
  );
  @override
  late final GeneratedColumn<int> maxHrBpm = GeneratedColumn<int>(
    'max_hr_bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    distanceM,
    movingS,
    elapsedS,
    elevGainM,
    avgPaceSPerKm,
    polyline,
    avgHrBpm,
    maxHrBpm,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Run> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('moving_s')) {
      context.handle(
        _movingSMeta,
        movingS.isAcceptableOrUnknown(data['moving_s']!, _movingSMeta),
      );
    } else if (isInserting) {
      context.missing(_movingSMeta);
    }
    if (data.containsKey('elapsed_s')) {
      context.handle(
        _elapsedSMeta,
        elapsedS.isAcceptableOrUnknown(data['elapsed_s']!, _elapsedSMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedSMeta);
    }
    if (data.containsKey('elev_gain_m')) {
      context.handle(
        _elevGainMMeta,
        elevGainM.isAcceptableOrUnknown(data['elev_gain_m']!, _elevGainMMeta),
      );
    }
    if (data.containsKey('avg_pace_s_per_km')) {
      context.handle(
        _avgPaceSPerKmMeta,
        avgPaceSPerKm.isAcceptableOrUnknown(
          data['avg_pace_s_per_km']!,
          _avgPaceSPerKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgPaceSPerKmMeta);
    }
    if (data.containsKey('polyline')) {
      context.handle(
        _polylineMeta,
        polyline.isAcceptableOrUnknown(data['polyline']!, _polylineMeta),
      );
    }
    if (data.containsKey('avg_hr_bpm')) {
      context.handle(
        _avgHrBpmMeta,
        avgHrBpm.isAcceptableOrUnknown(data['avg_hr_bpm']!, _avgHrBpmMeta),
      );
    }
    if (data.containsKey('max_hr_bpm')) {
      context.handle(
        _maxHrBpmMeta,
        maxHrBpm.isAcceptableOrUnknown(data['max_hr_bpm']!, _maxHrBpmMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Run map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Run(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      )!,
      movingS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_s'],
      )!,
      elapsedS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_s'],
      )!,
      elevGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elev_gain_m'],
      ),
      avgPaceSPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_pace_s_per_km'],
      )!,
      polyline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}polyline'],
      ),
      avgHrBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_hr_bpm'],
      ),
      maxHrBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_hr_bpm'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }
}

class Run extends DataClass implements Insertable<Run> {
  final int id;
  final DateTime startedAt;

  /// Null while the run is still being recorded, exactly as `Workouts.endedAt`
  /// is null for a session in progress.
  final DateTime? endedAt;
  final double distanceM;
  final int movingS;
  final int elapsedS;

  /// Null until A6. GPS altitude is ±10–15 m and the A32 has no barometer, so
  /// climb is not computed from it — raw altitude is kept per point in
  /// [RunPoints] and nothing is derived from it yet.
  final double? elevGainM;
  final double avgPaceSPerKm;

  /// Encoded polyline, for fast list rendering without loading every point.
  /// Null until A2 draws a map; the points are the source of truth regardless.
  final String? polyline;

  /// Heart rate lands in A7, over BLE. These two columns exist ahead of that
  /// feature deliberately: a nullable column added during this migration costs
  /// four lines, while adding it later costs a schema v8 and ~1,500
  /// permanently unrecoverable generated lines in `test/generated/`. Recorded
  /// as requirement A1-3 so an audit does not read them as speculation.
  final int? avgHrBpm;
  final int? maxHrBpm;
  final String? notes;
  const Run({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.distanceM,
    required this.movingS,
    required this.elapsedS,
    this.elevGainM,
    required this.avgPaceSPerKm,
    this.polyline,
    this.avgHrBpm,
    this.maxHrBpm,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['distance_m'] = Variable<double>(distanceM);
    map['moving_s'] = Variable<int>(movingS);
    map['elapsed_s'] = Variable<int>(elapsedS);
    if (!nullToAbsent || elevGainM != null) {
      map['elev_gain_m'] = Variable<double>(elevGainM);
    }
    map['avg_pace_s_per_km'] = Variable<double>(avgPaceSPerKm);
    if (!nullToAbsent || polyline != null) {
      map['polyline'] = Variable<String>(polyline);
    }
    if (!nullToAbsent || avgHrBpm != null) {
      map['avg_hr_bpm'] = Variable<int>(avgHrBpm);
    }
    if (!nullToAbsent || maxHrBpm != null) {
      map['max_hr_bpm'] = Variable<int>(maxHrBpm);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      distanceM: Value(distanceM),
      movingS: Value(movingS),
      elapsedS: Value(elapsedS),
      elevGainM: elevGainM == null && nullToAbsent
          ? const Value.absent()
          : Value(elevGainM),
      avgPaceSPerKm: Value(avgPaceSPerKm),
      polyline: polyline == null && nullToAbsent
          ? const Value.absent()
          : Value(polyline),
      avgHrBpm: avgHrBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHrBpm),
      maxHrBpm: maxHrBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHrBpm),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Run.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Run(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      movingS: serializer.fromJson<int>(json['movingS']),
      elapsedS: serializer.fromJson<int>(json['elapsedS']),
      elevGainM: serializer.fromJson<double?>(json['elevGainM']),
      avgPaceSPerKm: serializer.fromJson<double>(json['avgPaceSPerKm']),
      polyline: serializer.fromJson<String?>(json['polyline']),
      avgHrBpm: serializer.fromJson<int?>(json['avgHrBpm']),
      maxHrBpm: serializer.fromJson<int?>(json['maxHrBpm']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'distanceM': serializer.toJson<double>(distanceM),
      'movingS': serializer.toJson<int>(movingS),
      'elapsedS': serializer.toJson<int>(elapsedS),
      'elevGainM': serializer.toJson<double?>(elevGainM),
      'avgPaceSPerKm': serializer.toJson<double>(avgPaceSPerKm),
      'polyline': serializer.toJson<String?>(polyline),
      'avgHrBpm': serializer.toJson<int?>(avgHrBpm),
      'maxHrBpm': serializer.toJson<int?>(maxHrBpm),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Run copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    double? distanceM,
    int? movingS,
    int? elapsedS,
    Value<double?> elevGainM = const Value.absent(),
    double? avgPaceSPerKm,
    Value<String?> polyline = const Value.absent(),
    Value<int?> avgHrBpm = const Value.absent(),
    Value<int?> maxHrBpm = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Run(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    distanceM: distanceM ?? this.distanceM,
    movingS: movingS ?? this.movingS,
    elapsedS: elapsedS ?? this.elapsedS,
    elevGainM: elevGainM.present ? elevGainM.value : this.elevGainM,
    avgPaceSPerKm: avgPaceSPerKm ?? this.avgPaceSPerKm,
    polyline: polyline.present ? polyline.value : this.polyline,
    avgHrBpm: avgHrBpm.present ? avgHrBpm.value : this.avgHrBpm,
    maxHrBpm: maxHrBpm.present ? maxHrBpm.value : this.maxHrBpm,
    notes: notes.present ? notes.value : this.notes,
  );
  Run copyWithCompanion(RunsCompanion data) {
    return Run(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      movingS: data.movingS.present ? data.movingS.value : this.movingS,
      elapsedS: data.elapsedS.present ? data.elapsedS.value : this.elapsedS,
      elevGainM: data.elevGainM.present ? data.elevGainM.value : this.elevGainM,
      avgPaceSPerKm: data.avgPaceSPerKm.present
          ? data.avgPaceSPerKm.value
          : this.avgPaceSPerKm,
      polyline: data.polyline.present ? data.polyline.value : this.polyline,
      avgHrBpm: data.avgHrBpm.present ? data.avgHrBpm.value : this.avgHrBpm,
      maxHrBpm: data.maxHrBpm.present ? data.maxHrBpm.value : this.maxHrBpm,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Run(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('movingS: $movingS, ')
          ..write('elapsedS: $elapsedS, ')
          ..write('elevGainM: $elevGainM, ')
          ..write('avgPaceSPerKm: $avgPaceSPerKm, ')
          ..write('polyline: $polyline, ')
          ..write('avgHrBpm: $avgHrBpm, ')
          ..write('maxHrBpm: $maxHrBpm, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    distanceM,
    movingS,
    elapsedS,
    elevGainM,
    avgPaceSPerKm,
    polyline,
    avgHrBpm,
    maxHrBpm,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Run &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.distanceM == this.distanceM &&
          other.movingS == this.movingS &&
          other.elapsedS == this.elapsedS &&
          other.elevGainM == this.elevGainM &&
          other.avgPaceSPerKm == this.avgPaceSPerKm &&
          other.polyline == this.polyline &&
          other.avgHrBpm == this.avgHrBpm &&
          other.maxHrBpm == this.maxHrBpm &&
          other.notes == this.notes);
}

class RunsCompanion extends UpdateCompanion<Run> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> distanceM;
  final Value<int> movingS;
  final Value<int> elapsedS;
  final Value<double?> elevGainM;
  final Value<double> avgPaceSPerKm;
  final Value<String?> polyline;
  final Value<int?> avgHrBpm;
  final Value<int?> maxHrBpm;
  final Value<String?> notes;
  const RunsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.movingS = const Value.absent(),
    this.elapsedS = const Value.absent(),
    this.elevGainM = const Value.absent(),
    this.avgPaceSPerKm = const Value.absent(),
    this.polyline = const Value.absent(),
    this.avgHrBpm = const Value.absent(),
    this.maxHrBpm = const Value.absent(),
    this.notes = const Value.absent(),
  });
  RunsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required double distanceM,
    required int movingS,
    required int elapsedS,
    this.elevGainM = const Value.absent(),
    required double avgPaceSPerKm,
    this.polyline = const Value.absent(),
    this.avgHrBpm = const Value.absent(),
    this.maxHrBpm = const Value.absent(),
    this.notes = const Value.absent(),
  }) : startedAt = Value(startedAt),
       distanceM = Value(distanceM),
       movingS = Value(movingS),
       elapsedS = Value(elapsedS),
       avgPaceSPerKm = Value(avgPaceSPerKm);
  static Insertable<Run> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? distanceM,
    Expression<int>? movingS,
    Expression<int>? elapsedS,
    Expression<double>? elevGainM,
    Expression<double>? avgPaceSPerKm,
    Expression<String>? polyline,
    Expression<int>? avgHrBpm,
    Expression<int>? maxHrBpm,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (distanceM != null) 'distance_m': distanceM,
      if (movingS != null) 'moving_s': movingS,
      if (elapsedS != null) 'elapsed_s': elapsedS,
      if (elevGainM != null) 'elev_gain_m': elevGainM,
      if (avgPaceSPerKm != null) 'avg_pace_s_per_km': avgPaceSPerKm,
      if (polyline != null) 'polyline': polyline,
      if (avgHrBpm != null) 'avg_hr_bpm': avgHrBpm,
      if (maxHrBpm != null) 'max_hr_bpm': maxHrBpm,
      if (notes != null) 'notes': notes,
    });
  }

  RunsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<double>? distanceM,
    Value<int>? movingS,
    Value<int>? elapsedS,
    Value<double?>? elevGainM,
    Value<double>? avgPaceSPerKm,
    Value<String?>? polyline,
    Value<int?>? avgHrBpm,
    Value<int?>? maxHrBpm,
    Value<String?>? notes,
  }) {
    return RunsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceM: distanceM ?? this.distanceM,
      movingS: movingS ?? this.movingS,
      elapsedS: elapsedS ?? this.elapsedS,
      elevGainM: elevGainM ?? this.elevGainM,
      avgPaceSPerKm: avgPaceSPerKm ?? this.avgPaceSPerKm,
      polyline: polyline ?? this.polyline,
      avgHrBpm: avgHrBpm ?? this.avgHrBpm,
      maxHrBpm: maxHrBpm ?? this.maxHrBpm,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (movingS.present) {
      map['moving_s'] = Variable<int>(movingS.value);
    }
    if (elapsedS.present) {
      map['elapsed_s'] = Variable<int>(elapsedS.value);
    }
    if (elevGainM.present) {
      map['elev_gain_m'] = Variable<double>(elevGainM.value);
    }
    if (avgPaceSPerKm.present) {
      map['avg_pace_s_per_km'] = Variable<double>(avgPaceSPerKm.value);
    }
    if (polyline.present) {
      map['polyline'] = Variable<String>(polyline.value);
    }
    if (avgHrBpm.present) {
      map['avg_hr_bpm'] = Variable<int>(avgHrBpm.value);
    }
    if (maxHrBpm.present) {
      map['max_hr_bpm'] = Variable<int>(maxHrBpm.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('movingS: $movingS, ')
          ..write('elapsedS: $elapsedS, ')
          ..write('elevGainM: $elevGainM, ')
          ..write('avgPaceSPerKm: $avgPaceSPerKm, ')
          ..write('polyline: $polyline, ')
          ..write('avgHrBpm: $avgHrBpm, ')
          ..write('maxHrBpm: $maxHrBpm, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $RunPointsTable extends RunPoints
    with TableInfo<$RunPointsTable, RunPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunPointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<int> runId = GeneratedColumn<int>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES runs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevMMeta = const VerificationMeta('elevM');
  @override
  late final GeneratedColumn<double> elevM = GeneratedColumn<double>(
    'elev_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    lat,
    lon,
    elevM,
    timestamp,
    accuracyM,
    speedMps,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('elev_m')) {
      context.handle(
        _elevMMeta,
        elevM.isAcceptableOrUnknown(data['elev_m']!, _elevMMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      elevM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elev_m'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
    );
  }

  @override
  $RunPointsTable createAlias(String alias) {
    return $RunPointsTable(attachedDatabase, alias);
  }
}

class RunPoint extends DataClass implements Insertable<RunPoint> {
  final int id;
  final int runId;
  final double lat;
  final double lon;

  /// Raw GPS altitude, stored and not used. Nullable because a horizontal-only
  /// fix genuinely carries no altitude.
  final double? elevM;
  final DateTime timestamp;

  /// Both nullable for the same reason: a real fix can arrive without a
  /// reported accuracy or a Doppler speed, and inventing a zero would claim
  /// perfect precision and a dead stop.
  final double? accuracyM;
  final double? speedMps;
  const RunPoint({
    required this.id,
    required this.runId,
    required this.lat,
    required this.lon,
    this.elevM,
    required this.timestamp,
    this.accuracyM,
    this.speedMps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<int>(runId);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || elevM != null) {
      map['elev_m'] = Variable<double>(elevM);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    return map;
  }

  RunPointsCompanion toCompanion(bool nullToAbsent) {
    return RunPointsCompanion(
      id: Value(id),
      runId: Value(runId),
      lat: Value(lat),
      lon: Value(lon),
      elevM: elevM == null && nullToAbsent
          ? const Value.absent()
          : Value(elevM),
      timestamp: Value(timestamp),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
    );
  }

  factory RunPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunPoint(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<int>(json['runId']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      elevM: serializer.fromJson<double?>(json['elevM']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<int>(runId),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'elevM': serializer.toJson<double?>(elevM),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'speedMps': serializer.toJson<double?>(speedMps),
    };
  }

  RunPoint copyWith({
    int? id,
    int? runId,
    double? lat,
    double? lon,
    Value<double?> elevM = const Value.absent(),
    DateTime? timestamp,
    Value<double?> accuracyM = const Value.absent(),
    Value<double?> speedMps = const Value.absent(),
  }) => RunPoint(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    elevM: elevM.present ? elevM.value : this.elevM,
    timestamp: timestamp ?? this.timestamp,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
  );
  RunPoint copyWithCompanion(RunPointsCompanion data) {
    return RunPoint(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      elevM: data.elevM.present ? data.elevM.value : this.elevM,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunPoint(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('elevM: $elevM, ')
          ..write('timestamp: $timestamp, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, runId, lat, lon, elevM, timestamp, accuracyM, speedMps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunPoint &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.elevM == this.elevM &&
          other.timestamp == this.timestamp &&
          other.accuracyM == this.accuracyM &&
          other.speedMps == this.speedMps);
}

class RunPointsCompanion extends UpdateCompanion<RunPoint> {
  final Value<int> id;
  final Value<int> runId;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> elevM;
  final Value<DateTime> timestamp;
  final Value<double?> accuracyM;
  final Value<double?> speedMps;
  const RunPointsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.elevM = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
  });
  RunPointsCompanion.insert({
    this.id = const Value.absent(),
    required int runId,
    required double lat,
    required double lon,
    this.elevM = const Value.absent(),
    required DateTime timestamp,
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
  }) : runId = Value(runId),
       lat = Value(lat),
       lon = Value(lon),
       timestamp = Value(timestamp);
  static Insertable<RunPoint> custom({
    Expression<int>? id,
    Expression<int>? runId,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? elevM,
    Expression<DateTime>? timestamp,
    Expression<double>? accuracyM,
    Expression<double>? speedMps,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (elevM != null) 'elev_m': elevM,
      if (timestamp != null) 'timestamp': timestamp,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (speedMps != null) 'speed_mps': speedMps,
    });
  }

  RunPointsCompanion copyWith({
    Value<int>? id,
    Value<int>? runId,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? elevM,
    Value<DateTime>? timestamp,
    Value<double?>? accuracyM,
    Value<double?>? speedMps,
  }) {
    return RunPointsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      elevM: elevM ?? this.elevM,
      timestamp: timestamp ?? this.timestamp,
      accuracyM: accuracyM ?? this.accuracyM,
      speedMps: speedMps ?? this.speedMps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<int>(runId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (elevM.present) {
      map['elev_m'] = Variable<double>(elevM.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunPointsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('elevM: $elevM, ')
          ..write('timestamp: $timestamp, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps')
          ..write(')'))
        .toString();
  }
}

class $SplitsTable extends Splits with TableInfo<$SplitsTable, Split> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<int> runId = GeneratedColumn<int>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES runs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kmMeta = const VerificationMeta('km');
  @override
  late final GeneratedColumn<int> km = GeneratedColumn<int>(
    'km',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPartialMeta = const VerificationMeta(
    'isPartial',
  );
  @override
  late final GeneratedColumn<bool> isPartial = GeneratedColumn<bool>(
    'is_partial',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_partial" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _elevDeltaMMeta = const VerificationMeta(
    'elevDeltaM',
  );
  @override
  late final GeneratedColumn<double> elevDeltaM = GeneratedColumn<double>(
    'elev_delta_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    km,
    durationS,
    distanceM,
    isPartial,
    elevDeltaM,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Split> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('km')) {
      context.handle(_kmMeta, km.isAcceptableOrUnknown(data['km']!, _kmMeta));
    } else if (isInserting) {
      context.missing(_kmMeta);
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    } else if (isInserting) {
      context.missing(_durationSMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('is_partial')) {
      context.handle(
        _isPartialMeta,
        isPartial.isAcceptableOrUnknown(data['is_partial']!, _isPartialMeta),
      );
    }
    if (data.containsKey('elev_delta_m')) {
      context.handle(
        _elevDeltaMMeta,
        elevDeltaM.isAcceptableOrUnknown(
          data['elev_delta_m']!,
          _elevDeltaMMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Split map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Split(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_id'],
      )!,
      km: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km'],
      )!,
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      )!,
      isPartial: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_partial'],
      )!,
      elevDeltaM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elev_delta_m'],
      ),
    );
  }

  @override
  $SplitsTable createAlias(String alias) {
    return $SplitsTable(attachedDatabase, alias);
  }
}

class Split extends DataClass implements Insertable<Split> {
  final int id;
  final int runId;
  final int km;
  final int durationS;

  /// Metres this split actually covers — 1000 for a whole one, less for the
  /// remainder at the end.
  final double distanceM;
  final bool isPartial;

  /// Null until A6, for the same reason as `Runs.elevGainM`.
  final double? elevDeltaM;
  const Split({
    required this.id,
    required this.runId,
    required this.km,
    required this.durationS,
    required this.distanceM,
    required this.isPartial,
    this.elevDeltaM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<int>(runId);
    map['km'] = Variable<int>(km);
    map['duration_s'] = Variable<int>(durationS);
    map['distance_m'] = Variable<double>(distanceM);
    map['is_partial'] = Variable<bool>(isPartial);
    if (!nullToAbsent || elevDeltaM != null) {
      map['elev_delta_m'] = Variable<double>(elevDeltaM);
    }
    return map;
  }

  SplitsCompanion toCompanion(bool nullToAbsent) {
    return SplitsCompanion(
      id: Value(id),
      runId: Value(runId),
      km: Value(km),
      durationS: Value(durationS),
      distanceM: Value(distanceM),
      isPartial: Value(isPartial),
      elevDeltaM: elevDeltaM == null && nullToAbsent
          ? const Value.absent()
          : Value(elevDeltaM),
    );
  }

  factory Split.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Split(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<int>(json['runId']),
      km: serializer.fromJson<int>(json['km']),
      durationS: serializer.fromJson<int>(json['durationS']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      isPartial: serializer.fromJson<bool>(json['isPartial']),
      elevDeltaM: serializer.fromJson<double?>(json['elevDeltaM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<int>(runId),
      'km': serializer.toJson<int>(km),
      'durationS': serializer.toJson<int>(durationS),
      'distanceM': serializer.toJson<double>(distanceM),
      'isPartial': serializer.toJson<bool>(isPartial),
      'elevDeltaM': serializer.toJson<double?>(elevDeltaM),
    };
  }

  Split copyWith({
    int? id,
    int? runId,
    int? km,
    int? durationS,
    double? distanceM,
    bool? isPartial,
    Value<double?> elevDeltaM = const Value.absent(),
  }) => Split(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    km: km ?? this.km,
    durationS: durationS ?? this.durationS,
    distanceM: distanceM ?? this.distanceM,
    isPartial: isPartial ?? this.isPartial,
    elevDeltaM: elevDeltaM.present ? elevDeltaM.value : this.elevDeltaM,
  );
  Split copyWithCompanion(SplitsCompanion data) {
    return Split(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      km: data.km.present ? data.km.value : this.km,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      isPartial: data.isPartial.present ? data.isPartial.value : this.isPartial,
      elevDeltaM: data.elevDeltaM.present
          ? data.elevDeltaM.value
          : this.elevDeltaM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Split(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('km: $km, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('isPartial: $isPartial, ')
          ..write('elevDeltaM: $elevDeltaM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, runId, km, durationS, distanceM, isPartial, elevDeltaM);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Split &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.km == this.km &&
          other.durationS == this.durationS &&
          other.distanceM == this.distanceM &&
          other.isPartial == this.isPartial &&
          other.elevDeltaM == this.elevDeltaM);
}

class SplitsCompanion extends UpdateCompanion<Split> {
  final Value<int> id;
  final Value<int> runId;
  final Value<int> km;
  final Value<int> durationS;
  final Value<double> distanceM;
  final Value<bool> isPartial;
  final Value<double?> elevDeltaM;
  const SplitsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.km = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.isPartial = const Value.absent(),
    this.elevDeltaM = const Value.absent(),
  });
  SplitsCompanion.insert({
    this.id = const Value.absent(),
    required int runId,
    required int km,
    required int durationS,
    required double distanceM,
    this.isPartial = const Value.absent(),
    this.elevDeltaM = const Value.absent(),
  }) : runId = Value(runId),
       km = Value(km),
       durationS = Value(durationS),
       distanceM = Value(distanceM);
  static Insertable<Split> custom({
    Expression<int>? id,
    Expression<int>? runId,
    Expression<int>? km,
    Expression<int>? durationS,
    Expression<double>? distanceM,
    Expression<bool>? isPartial,
    Expression<double>? elevDeltaM,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (km != null) 'km': km,
      if (durationS != null) 'duration_s': durationS,
      if (distanceM != null) 'distance_m': distanceM,
      if (isPartial != null) 'is_partial': isPartial,
      if (elevDeltaM != null) 'elev_delta_m': elevDeltaM,
    });
  }

  SplitsCompanion copyWith({
    Value<int>? id,
    Value<int>? runId,
    Value<int>? km,
    Value<int>? durationS,
    Value<double>? distanceM,
    Value<bool>? isPartial,
    Value<double?>? elevDeltaM,
  }) {
    return SplitsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      km: km ?? this.km,
      durationS: durationS ?? this.durationS,
      distanceM: distanceM ?? this.distanceM,
      isPartial: isPartial ?? this.isPartial,
      elevDeltaM: elevDeltaM ?? this.elevDeltaM,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<int>(runId.value);
    }
    if (km.present) {
      map['km'] = Variable<int>(km.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (isPartial.present) {
      map['is_partial'] = Variable<bool>(isPartial.value);
    }
    if (elevDeltaM.present) {
      map['elev_delta_m'] = Variable<double>(elevDeltaM.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('km: $km, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('isPartial: $isPartial, ')
          ..write('elevDeltaM: $elevDeltaM')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waistCmMeta = const VerificationMeta(
    'waistCm',
  );
  @override
  late final GeneratedColumn<double> waistCm = GeneratedColumn<double>(
    'waist_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chestCmMeta = const VerificationMeta(
    'chestCm',
  );
  @override
  late final GeneratedColumn<double> chestCm = GeneratedColumn<double>(
    'chest_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _armCmMeta = const VerificationMeta('armCm');
  @override
  late final GeneratedColumn<double> armCm = GeneratedColumn<double>(
    'arm_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thighCmMeta = const VerificationMeta(
    'thighCm',
  );
  @override
  late final GeneratedColumn<double> thighCm = GeneratedColumn<double>(
    'thigh_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hipCmMeta = const VerificationMeta('hipCm');
  @override
  late final GeneratedColumn<double> hipCm = GeneratedColumn<double>(
    'hip_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neckCmMeta = const VerificationMeta('neckCm');
  @override
  late final GeneratedColumn<double> neckCm = GeneratedColumn<double>(
    'neck_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _broadJumpCmMeta = const VerificationMeta(
    'broadJumpCm',
  );
  @override
  late final GeneratedColumn<double> broadJumpCm = GeneratedColumn<double>(
    'broad_jump_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    weightKg,
    waistCm,
    chestCm,
    armCm,
    thighCm,
    hipCm,
    neckCm,
    broadJumpCm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Measurement> instance, {
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
    }
    if (data.containsKey('waist_cm')) {
      context.handle(
        _waistCmMeta,
        waistCm.isAcceptableOrUnknown(data['waist_cm']!, _waistCmMeta),
      );
    }
    if (data.containsKey('chest_cm')) {
      context.handle(
        _chestCmMeta,
        chestCm.isAcceptableOrUnknown(data['chest_cm']!, _chestCmMeta),
      );
    }
    if (data.containsKey('arm_cm')) {
      context.handle(
        _armCmMeta,
        armCm.isAcceptableOrUnknown(data['arm_cm']!, _armCmMeta),
      );
    }
    if (data.containsKey('thigh_cm')) {
      context.handle(
        _thighCmMeta,
        thighCm.isAcceptableOrUnknown(data['thigh_cm']!, _thighCmMeta),
      );
    }
    if (data.containsKey('hip_cm')) {
      context.handle(
        _hipCmMeta,
        hipCm.isAcceptableOrUnknown(data['hip_cm']!, _hipCmMeta),
      );
    }
    if (data.containsKey('neck_cm')) {
      context.handle(
        _neckCmMeta,
        neckCm.isAcceptableOrUnknown(data['neck_cm']!, _neckCmMeta),
      );
    }
    if (data.containsKey('broad_jump_cm')) {
      context.handle(
        _broadJumpCmMeta,
        broadJumpCm.isAcceptableOrUnknown(
          data['broad_jump_cm']!,
          _broadJumpCmMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
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
      ),
      waistCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waist_cm'],
      ),
      chestCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chest_cm'],
      ),
      armCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}arm_cm'],
      ),
      thighCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thigh_cm'],
      ),
      hipCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hip_cm'],
      ),
      neckCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}neck_cm'],
      ),
      broadJumpCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}broad_jump_cm'],
      ),
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final int id;
  final DateTime date;
  final double? weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;
  final double? thighCm;
  final double? hipCm;
  final double? neckCm;
  final double? broadJumpCm;
  const Measurement({
    required this.id,
    required this.date,
    this.weightKg,
    this.waistCm,
    this.chestCm,
    this.armCm,
    this.thighCm,
    this.hipCm,
    this.neckCm,
    this.broadJumpCm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || waistCm != null) {
      map['waist_cm'] = Variable<double>(waistCm);
    }
    if (!nullToAbsent || chestCm != null) {
      map['chest_cm'] = Variable<double>(chestCm);
    }
    if (!nullToAbsent || armCm != null) {
      map['arm_cm'] = Variable<double>(armCm);
    }
    if (!nullToAbsent || thighCm != null) {
      map['thigh_cm'] = Variable<double>(thighCm);
    }
    if (!nullToAbsent || hipCm != null) {
      map['hip_cm'] = Variable<double>(hipCm);
    }
    if (!nullToAbsent || neckCm != null) {
      map['neck_cm'] = Variable<double>(neckCm);
    }
    if (!nullToAbsent || broadJumpCm != null) {
      map['broad_jump_cm'] = Variable<double>(broadJumpCm);
    }
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      date: Value(date),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      waistCm: waistCm == null && nullToAbsent
          ? const Value.absent()
          : Value(waistCm),
      chestCm: chestCm == null && nullToAbsent
          ? const Value.absent()
          : Value(chestCm),
      armCm: armCm == null && nullToAbsent
          ? const Value.absent()
          : Value(armCm),
      thighCm: thighCm == null && nullToAbsent
          ? const Value.absent()
          : Value(thighCm),
      hipCm: hipCm == null && nullToAbsent
          ? const Value.absent()
          : Value(hipCm),
      neckCm: neckCm == null && nullToAbsent
          ? const Value.absent()
          : Value(neckCm),
      broadJumpCm: broadJumpCm == null && nullToAbsent
          ? const Value.absent()
          : Value(broadJumpCm),
    );
  }

  factory Measurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      waistCm: serializer.fromJson<double?>(json['waistCm']),
      chestCm: serializer.fromJson<double?>(json['chestCm']),
      armCm: serializer.fromJson<double?>(json['armCm']),
      thighCm: serializer.fromJson<double?>(json['thighCm']),
      hipCm: serializer.fromJson<double?>(json['hipCm']),
      neckCm: serializer.fromJson<double?>(json['neckCm']),
      broadJumpCm: serializer.fromJson<double?>(json['broadJumpCm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'weightKg': serializer.toJson<double?>(weightKg),
      'waistCm': serializer.toJson<double?>(waistCm),
      'chestCm': serializer.toJson<double?>(chestCm),
      'armCm': serializer.toJson<double?>(armCm),
      'thighCm': serializer.toJson<double?>(thighCm),
      'hipCm': serializer.toJson<double?>(hipCm),
      'neckCm': serializer.toJson<double?>(neckCm),
      'broadJumpCm': serializer.toJson<double?>(broadJumpCm),
    };
  }

  Measurement copyWith({
    int? id,
    DateTime? date,
    Value<double?> weightKg = const Value.absent(),
    Value<double?> waistCm = const Value.absent(),
    Value<double?> chestCm = const Value.absent(),
    Value<double?> armCm = const Value.absent(),
    Value<double?> thighCm = const Value.absent(),
    Value<double?> hipCm = const Value.absent(),
    Value<double?> neckCm = const Value.absent(),
    Value<double?> broadJumpCm = const Value.absent(),
  }) => Measurement(
    id: id ?? this.id,
    date: date ?? this.date,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    waistCm: waistCm.present ? waistCm.value : this.waistCm,
    chestCm: chestCm.present ? chestCm.value : this.chestCm,
    armCm: armCm.present ? armCm.value : this.armCm,
    thighCm: thighCm.present ? thighCm.value : this.thighCm,
    hipCm: hipCm.present ? hipCm.value : this.hipCm,
    neckCm: neckCm.present ? neckCm.value : this.neckCm,
    broadJumpCm: broadJumpCm.present ? broadJumpCm.value : this.broadJumpCm,
  );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      waistCm: data.waistCm.present ? data.waistCm.value : this.waistCm,
      chestCm: data.chestCm.present ? data.chestCm.value : this.chestCm,
      armCm: data.armCm.present ? data.armCm.value : this.armCm,
      thighCm: data.thighCm.present ? data.thighCm.value : this.thighCm,
      hipCm: data.hipCm.present ? data.hipCm.value : this.hipCm,
      neckCm: data.neckCm.present ? data.neckCm.value : this.neckCm,
      broadJumpCm: data.broadJumpCm.present
          ? data.broadJumpCm.value
          : this.broadJumpCm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('waistCm: $waistCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('armCm: $armCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('hipCm: $hipCm, ')
          ..write('neckCm: $neckCm, ')
          ..write('broadJumpCm: $broadJumpCm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    weightKg,
    waistCm,
    chestCm,
    armCm,
    thighCm,
    hipCm,
    neckCm,
    broadJumpCm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.id == this.id &&
          other.date == this.date &&
          other.weightKg == this.weightKg &&
          other.waistCm == this.waistCm &&
          other.chestCm == this.chestCm &&
          other.armCm == this.armCm &&
          other.thighCm == this.thighCm &&
          other.hipCm == this.hipCm &&
          other.neckCm == this.neckCm &&
          other.broadJumpCm == this.broadJumpCm);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double?> weightKg;
  final Value<double?> waistCm;
  final Value<double?> chestCm;
  final Value<double?> armCm;
  final Value<double?> thighCm;
  final Value<double?> hipCm;
  final Value<double?> neckCm;
  final Value<double?> broadJumpCm;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.armCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.hipCm = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.broadJumpCm = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.weightKg = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.armCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.hipCm = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.broadJumpCm = const Value.absent(),
  }) : date = Value(date);
  static Insertable<Measurement> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? weightKg,
    Expression<double>? waistCm,
    Expression<double>? chestCm,
    Expression<double>? armCm,
    Expression<double>? thighCm,
    Expression<double>? hipCm,
    Expression<double>? neckCm,
    Expression<double>? broadJumpCm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (weightKg != null) 'weight_kg': weightKg,
      if (waistCm != null) 'waist_cm': waistCm,
      if (chestCm != null) 'chest_cm': chestCm,
      if (armCm != null) 'arm_cm': armCm,
      if (thighCm != null) 'thigh_cm': thighCm,
      if (hipCm != null) 'hip_cm': hipCm,
      if (neckCm != null) 'neck_cm': neckCm,
      if (broadJumpCm != null) 'broad_jump_cm': broadJumpCm,
    });
  }

  MeasurementsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<double?>? weightKg,
    Value<double?>? waistCm,
    Value<double?>? chestCm,
    Value<double?>? armCm,
    Value<double?>? thighCm,
    Value<double?>? hipCm,
    Value<double?>? neckCm,
    Value<double?>? broadJumpCm,
  }) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      waistCm: waistCm ?? this.waistCm,
      chestCm: chestCm ?? this.chestCm,
      armCm: armCm ?? this.armCm,
      thighCm: thighCm ?? this.thighCm,
      hipCm: hipCm ?? this.hipCm,
      neckCm: neckCm ?? this.neckCm,
      broadJumpCm: broadJumpCm ?? this.broadJumpCm,
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
    if (waistCm.present) {
      map['waist_cm'] = Variable<double>(waistCm.value);
    }
    if (chestCm.present) {
      map['chest_cm'] = Variable<double>(chestCm.value);
    }
    if (armCm.present) {
      map['arm_cm'] = Variable<double>(armCm.value);
    }
    if (thighCm.present) {
      map['thigh_cm'] = Variable<double>(thighCm.value);
    }
    if (hipCm.present) {
      map['hip_cm'] = Variable<double>(hipCm.value);
    }
    if (neckCm.present) {
      map['neck_cm'] = Variable<double>(neckCm.value);
    }
    if (broadJumpCm.present) {
      map['broad_jump_cm'] = Variable<double>(broadJumpCm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('waistCm: $waistCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('armCm: $armCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('hipCm: $hipCm, ')
          ..write('neckCm: $neckCm, ')
          ..write('broadJumpCm: $broadJumpCm')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
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
    Insertable<Preference> instance, {
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
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
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
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
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

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
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
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
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

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
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
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $PlanDaysTable planDays = $PlanDaysTable(this);
  late final $PlanItemsTable planItems = $PlanItemsTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $SetLogsTable setLogs = $SetLogsTable(this);
  late final $WarmupChecksTable warmupChecks = $WarmupChecksTable(this);
  late final $FoodsTable foods = $FoodsTable(this);
  late final $ServingsTable servings = $ServingsTable(this);
  late final $RecipeItemsTable recipeItems = $RecipeItemsTable(this);
  late final $FoodLogsTable foodLogs = $FoodLogsTable(this);
  late final $DailyStepsTable dailySteps = $DailyStepsTable(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $RunPointsTable runPoints = $RunPointsTable(this);
  late final $SplitsTable splits = $SplitsTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final Index idxSetLogsWorkout = Index(
    'idx_set_logs_workout',
    'CREATE INDEX idx_set_logs_workout ON set_logs (workout_id)',
  );
  late final Index idxSetLogsExercise = Index(
    'idx_set_logs_exercise',
    'CREATE INDEX idx_set_logs_exercise ON set_logs (exercise_id)',
  );
  late final Index idxWarmupChecksWorkout = Index(
    'idx_warmup_checks_workout',
    'CREATE INDEX idx_warmup_checks_workout ON warmup_checks (workout_id)',
  );
  late final Index idxFoodLogsDate = Index(
    'idx_food_logs_date',
    'CREATE INDEX idx_food_logs_date ON food_logs (date)',
  );
  late final Index idxRunsStartedAt = Index(
    'idx_runs_started_at',
    'CREATE INDEX idx_runs_started_at ON runs (started_at)',
  );
  late final Index idxRunPointsRun = Index(
    'idx_run_points_run',
    'CREATE INDEX idx_run_points_run ON run_points (run_id)',
  );
  late final PlanDao planDao = PlanDao(this as AppDatabase);
  late final WorkoutDao workoutDao = WorkoutDao(this as AppDatabase);
  late final StepsDao stepsDao = StepsDao(this as AppDatabase);
  late final PreferencesDao preferencesDao = PreferencesDao(
    this as AppDatabase,
  );
  late final RunDao runDao = RunDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    planDays,
    planItems,
    workouts,
    setLogs,
    warmupChecks,
    foods,
    servings,
    recipeItems,
    foodLogs,
    dailySteps,
    runs,
    runPoints,
    splits,
    measurements,
    preferences,
    idxSetLogsWorkout,
    idxSetLogsExercise,
    idxWarmupChecksWorkout,
    idxFoodLogsDate,
    idxRunsStartedAt,
    idxRunPointsRun,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plan_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workouts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('set_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workouts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('warmup_checks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plan_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('warmup_checks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('servings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('run_points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('splits', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      required String name,
      required MovementPattern pattern,
      required String equipment,
      Value<bool> isUnilateral,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<MovementPattern> pattern,
      Value<String> equipment,
      Value<bool> isUnilateral,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanItemsTable, List<PlanItem>>
  _planItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planItems,
    aliasName: $_aliasNameGenerator(db.exercises.id, db.planItems.exerciseId),
  );

  $$PlanItemsTableProcessedTableManager get planItemsRefs {
    final manager = $$PlanItemsTableTableManager(
      $_db,
      $_db.planItems,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SetLogsTable, List<SetLog>> _setLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.setLogs,
    aliasName: $_aliasNameGenerator(db.exercises.id, db.setLogs.exerciseId),
  );

  $$SetLogsTableProcessedTableManager get setLogsRefs {
    final manager = $$SetLogsTableTableManager(
      $_db,
      $_db.setLogs,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_setLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnWithTypeConverterFilters<MovementPattern, MovementPattern, String>
  get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnilateral => $composableBuilder(
    column: $table.isUnilateral,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> planItemsRefs(
    Expression<bool> Function($$PlanItemsTableFilterComposer f) f,
  ) {
    final $$PlanItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableFilterComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> setLogsRefs(
    Expression<bool> Function($$SetLogsTableFilterComposer f) f,
  ) {
    final $$SetLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setLogs,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetLogsTableFilterComposer(
            $db: $db,
            $table: $db.setLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnilateral => $composableBuilder(
    column: $table.isUnilateral,
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

  GeneratedColumnWithTypeConverter<MovementPattern, String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<bool> get isUnilateral => $composableBuilder(
    column: $table.isUnilateral,
    builder: (column) => column,
  );

  Expression<T> planItemsRefs<T extends Object>(
    Expression<T> Function($$PlanItemsTableAnnotationComposer a) f,
  ) {
    final $$PlanItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> setLogsRefs<T extends Object>(
    Expression<T> Function($$SetLogsTableAnnotationComposer a) f,
  ) {
    final $$SetLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setLogs,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.setLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({bool planItemsRefs, bool setLogsRefs})
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
                Value<MovementPattern> pattern = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<bool> isUnilateral = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                pattern: pattern,
                equipment: equipment,
                isUnilateral: isUnilateral,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required MovementPattern pattern,
                required String equipment,
                Value<bool> isUnilateral = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                pattern: pattern,
                equipment: equipment,
                isUnilateral: isUnilateral,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({planItemsRefs = false, setLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (planItemsRefs) db.planItems,
                    if (setLogsRefs) db.setLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (planItemsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          PlanItem
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._planItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).planItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (setLogsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          SetLog
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._setLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).setLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({bool planItemsRefs, bool setLogsRefs})
    >;
typedef $$PlanDaysTableCreateCompanionBuilder =
    PlanDaysCompanion Function({
      Value<int> id,
      required PlanDayKey dayKey,
      required String name,
      required int orderIndex,
    });
typedef $$PlanDaysTableUpdateCompanionBuilder =
    PlanDaysCompanion Function({
      Value<int> id,
      Value<PlanDayKey> dayKey,
      Value<String> name,
      Value<int> orderIndex,
    });

final class $$PlanDaysTableReferences
    extends BaseReferences<_$AppDatabase, $PlanDaysTable, PlanDay> {
  $$PlanDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanItemsTable, List<PlanItem>>
  _planItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planItems,
    aliasName: $_aliasNameGenerator(db.planDays.id, db.planItems.planDayId),
  );

  $$PlanItemsTableProcessedTableManager get planItemsRefs {
    final manager = $$PlanItemsTableTableManager(
      $_db,
      $_db.planItems,
    ).filter((f) => f.planDayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutsTable, List<Workout>> _workoutsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.workouts,
    aliasName: $_aliasNameGenerator(db.planDays.id, db.workouts.planDayId),
  );

  $$WorkoutsTableProcessedTableManager get workoutsRefs {
    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.planDayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlanDaysTableFilterComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableFilterComposer({
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

  ColumnWithTypeConverterFilters<PlanDayKey, PlanDayKey, String> get dayKey =>
      $composableBuilder(
        column: $table.dayKey,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> planItemsRefs(
    Expression<bool> Function($$PlanItemsTableFilterComposer f) f,
  ) {
    final $$PlanItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.planDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableFilterComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutsRefs(
    Expression<bool> Function($$WorkoutsTableFilterComposer f) f,
  ) {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.planDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlanDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableOrderingComposer({
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

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanDaysTable> {
  $$PlanDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlanDayKey, String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  Expression<T> planItemsRefs<T extends Object>(
    Expression<T> Function($$PlanItemsTableAnnotationComposer a) f,
  ) {
    final $$PlanItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.planDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutsRefs<T extends Object>(
    Expression<T> Function($$WorkoutsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.planDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlanDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanDaysTable,
          PlanDay,
          $$PlanDaysTableFilterComposer,
          $$PlanDaysTableOrderingComposer,
          $$PlanDaysTableAnnotationComposer,
          $$PlanDaysTableCreateCompanionBuilder,
          $$PlanDaysTableUpdateCompanionBuilder,
          (PlanDay, $$PlanDaysTableReferences),
          PlanDay,
          PrefetchHooks Function({bool planItemsRefs, bool workoutsRefs})
        > {
  $$PlanDaysTableTableManager(_$AppDatabase db, $PlanDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<PlanDayKey> dayKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
              }) => PlanDaysCompanion(
                id: id,
                dayKey: dayKey,
                name: name,
                orderIndex: orderIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required PlanDayKey dayKey,
                required String name,
                required int orderIndex,
              }) => PlanDaysCompanion.insert(
                id: id,
                dayKey: dayKey,
                name: name,
                orderIndex: orderIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlanDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({planItemsRefs = false, workoutsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (planItemsRefs) db.planItems,
                    if (workoutsRefs) db.workouts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (planItemsRefs)
                        await $_getPrefetchedData<
                          PlanDay,
                          $PlanDaysTable,
                          PlanItem
                        >(
                          currentTable: table,
                          referencedTable: $$PlanDaysTableReferences
                              ._planItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlanDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).planItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutsRefs)
                        await $_getPrefetchedData<
                          PlanDay,
                          $PlanDaysTable,
                          Workout
                        >(
                          currentTable: table,
                          referencedTable: $$PlanDaysTableReferences
                              ._workoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlanDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlanDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanDaysTable,
      PlanDay,
      $$PlanDaysTableFilterComposer,
      $$PlanDaysTableOrderingComposer,
      $$PlanDaysTableAnnotationComposer,
      $$PlanDaysTableCreateCompanionBuilder,
      $$PlanDaysTableUpdateCompanionBuilder,
      (PlanDay, $$PlanDaysTableReferences),
      PlanDay,
      PrefetchHooks Function({bool planItemsRefs, bool workoutsRefs})
    >;
typedef $$PlanItemsTableCreateCompanionBuilder =
    PlanItemsCompanion Function({
      Value<int> id,
      required int planDayId,
      Value<int?> exerciseId,
      required TrainingBlock block,
      Value<int?> targetSets,
      Value<int?> repLow,
      Value<int?> repHigh,
      Value<String?> notes,
    });
typedef $$PlanItemsTableUpdateCompanionBuilder =
    PlanItemsCompanion Function({
      Value<int> id,
      Value<int> planDayId,
      Value<int?> exerciseId,
      Value<TrainingBlock> block,
      Value<int?> targetSets,
      Value<int?> repLow,
      Value<int?> repHigh,
      Value<String?> notes,
    });

final class $$PlanItemsTableReferences
    extends BaseReferences<_$AppDatabase, $PlanItemsTable, PlanItem> {
  $$PlanItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlanDaysTable _planDayIdTable(_$AppDatabase db) =>
      db.planDays.createAlias(
        $_aliasNameGenerator(db.planItems.planDayId, db.planDays.id),
      );

  $$PlanDaysTableProcessedTableManager get planDayId {
    final $_column = $_itemColumn<int>('plan_day_id')!;

    final manager = $$PlanDaysTableTableManager(
      $_db,
      $_db.planDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.planItems.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager? get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WarmupChecksTable, List<WarmupCheck>>
  _warmupChecksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.warmupChecks,
    aliasName: $_aliasNameGenerator(
      db.planItems.id,
      db.warmupChecks.planItemId,
    ),
  );

  $$WarmupChecksTableProcessedTableManager get warmupChecksRefs {
    final manager = $$WarmupChecksTableTableManager(
      $_db,
      $_db.warmupChecks,
    ).filter((f) => f.planItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_warmupChecksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlanItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanItemsTable> {
  $$PlanItemsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<TrainingBlock, TrainingBlock, String>
  get block => $composableBuilder(
    column: $table.block,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repLow => $composableBuilder(
    column: $table.repLow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repHigh => $composableBuilder(
    column: $table.repHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$PlanDaysTableFilterComposer get planDayId {
    final $$PlanDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDayId,
      referencedTable: $db.planDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanDaysTableFilterComposer(
            $db: $db,
            $table: $db.planDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> warmupChecksRefs(
    Expression<bool> Function($$WarmupChecksTableFilterComposer f) f,
  ) {
    final $$WarmupChecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.warmupChecks,
      getReferencedColumn: (t) => t.planItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarmupChecksTableFilterComposer(
            $db: $db,
            $table: $db.warmupChecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlanItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanItemsTable> {
  $$PlanItemsTableOrderingComposer({
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

  ColumnOrderings<String> get block => $composableBuilder(
    column: $table.block,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repLow => $composableBuilder(
    column: $table.repLow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repHigh => $composableBuilder(
    column: $table.repHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlanDaysTableOrderingComposer get planDayId {
    final $$PlanDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDayId,
      referencedTable: $db.planDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanDaysTableOrderingComposer(
            $db: $db,
            $table: $db.planDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanItemsTable> {
  $$PlanItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrainingBlock, String> get block =>
      $composableBuilder(column: $table.block, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repLow =>
      $composableBuilder(column: $table.repLow, builder: (column) => column);

  GeneratedColumn<int> get repHigh =>
      $composableBuilder(column: $table.repHigh, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$PlanDaysTableAnnotationComposer get planDayId {
    final $$PlanDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDayId,
      referencedTable: $db.planDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.planDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> warmupChecksRefs<T extends Object>(
    Expression<T> Function($$WarmupChecksTableAnnotationComposer a) f,
  ) {
    final $$WarmupChecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.warmupChecks,
      getReferencedColumn: (t) => t.planItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarmupChecksTableAnnotationComposer(
            $db: $db,
            $table: $db.warmupChecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlanItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanItemsTable,
          PlanItem,
          $$PlanItemsTableFilterComposer,
          $$PlanItemsTableOrderingComposer,
          $$PlanItemsTableAnnotationComposer,
          $$PlanItemsTableCreateCompanionBuilder,
          $$PlanItemsTableUpdateCompanionBuilder,
          (PlanItem, $$PlanItemsTableReferences),
          PlanItem,
          PrefetchHooks Function({
            bool planDayId,
            bool exerciseId,
            bool warmupChecksRefs,
          })
        > {
  $$PlanItemsTableTableManager(_$AppDatabase db, $PlanItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planDayId = const Value.absent(),
                Value<int?> exerciseId = const Value.absent(),
                Value<TrainingBlock> block = const Value.absent(),
                Value<int?> targetSets = const Value.absent(),
                Value<int?> repLow = const Value.absent(),
                Value<int?> repHigh = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => PlanItemsCompanion(
                id: id,
                planDayId: planDayId,
                exerciseId: exerciseId,
                block: block,
                targetSets: targetSets,
                repLow: repLow,
                repHigh: repHigh,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planDayId,
                Value<int?> exerciseId = const Value.absent(),
                required TrainingBlock block,
                Value<int?> targetSets = const Value.absent(),
                Value<int?> repLow = const Value.absent(),
                Value<int?> repHigh = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => PlanItemsCompanion.insert(
                id: id,
                planDayId: planDayId,
                exerciseId: exerciseId,
                block: block,
                targetSets: targetSets,
                repLow: repLow,
                repHigh: repHigh,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlanItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                planDayId = false,
                exerciseId = false,
                warmupChecksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (warmupChecksRefs) db.warmupChecks,
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
                        if (planDayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.planDayId,
                                    referencedTable: $$PlanItemsTableReferences
                                        ._planDayIdTable(db),
                                    referencedColumn: $$PlanItemsTableReferences
                                        ._planDayIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (exerciseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exerciseId,
                                    referencedTable: $$PlanItemsTableReferences
                                        ._exerciseIdTable(db),
                                    referencedColumn: $$PlanItemsTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (warmupChecksRefs)
                        await $_getPrefetchedData<
                          PlanItem,
                          $PlanItemsTable,
                          WarmupCheck
                        >(
                          currentTable: table,
                          referencedTable: $$PlanItemsTableReferences
                              ._warmupChecksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlanItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).warmupChecksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlanItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanItemsTable,
      PlanItem,
      $$PlanItemsTableFilterComposer,
      $$PlanItemsTableOrderingComposer,
      $$PlanItemsTableAnnotationComposer,
      $$PlanItemsTableCreateCompanionBuilder,
      $$PlanItemsTableUpdateCompanionBuilder,
      (PlanItem, $$PlanItemsTableReferences),
      PlanItem,
      PrefetchHooks Function({
        bool planDayId,
        bool exerciseId,
        bool warmupChecksRefs,
      })
    >;
typedef $$WorkoutsTableCreateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<int?> planDayId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<String?> notes,
    });
typedef $$WorkoutsTableUpdateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int?> planDayId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String?> notes,
    });

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlanDaysTable _planDayIdTable(_$AppDatabase db) => db.planDays
      .createAlias($_aliasNameGenerator(db.workouts.planDayId, db.planDays.id));

  $$PlanDaysTableProcessedTableManager? get planDayId {
    final $_column = $_itemColumn<int>('plan_day_id');
    if ($_column == null) return null;
    final manager = $$PlanDaysTableTableManager(
      $_db,
      $_db.planDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SetLogsTable, List<SetLog>> _setLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.setLogs,
    aliasName: $_aliasNameGenerator(db.workouts.id, db.setLogs.workoutId),
  );

  $$SetLogsTableProcessedTableManager get setLogsRefs {
    final manager = $$SetLogsTableTableManager(
      $_db,
      $_db.setLogs,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_setLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WarmupChecksTable, List<WarmupCheck>>
  _warmupChecksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.warmupChecks,
    aliasName: $_aliasNameGenerator(db.workouts.id, db.warmupChecks.workoutId),
  );

  $$WarmupChecksTableProcessedTableManager get warmupChecksRefs {
    final manager = $$WarmupChecksTableTableManager(
      $_db,
      $_db.warmupChecks,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_warmupChecksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$PlanDaysTableFilterComposer get planDayId {
    final $$PlanDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDayId,
      referencedTable: $db.planDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanDaysTableFilterComposer(
            $db: $db,
            $table: $db.planDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> setLogsRefs(
    Expression<bool> Function($$SetLogsTableFilterComposer f) f,
  ) {
    final $$SetLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setLogs,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetLogsTableFilterComposer(
            $db: $db,
            $table: $db.setLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> warmupChecksRefs(
    Expression<bool> Function($$WarmupChecksTableFilterComposer f) f,
  ) {
    final $$WarmupChecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.warmupChecks,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarmupChecksTableFilterComposer(
            $db: $db,
            $table: $db.warmupChecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlanDaysTableOrderingComposer get planDayId {
    final $$PlanDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDayId,
      referencedTable: $db.planDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanDaysTableOrderingComposer(
            $db: $db,
            $table: $db.planDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$PlanDaysTableAnnotationComposer get planDayId {
    final $$PlanDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planDayId,
      referencedTable: $db.planDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.planDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> setLogsRefs<T extends Object>(
    Expression<T> Function($$SetLogsTableAnnotationComposer a) f,
  ) {
    final $$SetLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setLogs,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.setLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> warmupChecksRefs<T extends Object>(
    Expression<T> Function($$WarmupChecksTableAnnotationComposer a) f,
  ) {
    final $$WarmupChecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.warmupChecks,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarmupChecksTableAnnotationComposer(
            $db: $db,
            $table: $db.warmupChecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, $$WorkoutsTableReferences),
          Workout,
          PrefetchHooks Function({
            bool planDayId,
            bool setLogsRefs,
            bool warmupChecksRefs,
          })
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int?> planDayId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                date: date,
                planDayId: planDayId,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<int?> planDayId = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => WorkoutsCompanion.insert(
                id: id,
                date: date,
                planDayId: planDayId,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                planDayId = false,
                setLogsRefs = false,
                warmupChecksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (setLogsRefs) db.setLogs,
                    if (warmupChecksRefs) db.warmupChecks,
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
                        if (planDayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.planDayId,
                                    referencedTable: $$WorkoutsTableReferences
                                        ._planDayIdTable(db),
                                    referencedColumn: $$WorkoutsTableReferences
                                        ._planDayIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (setLogsRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          SetLog
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._setLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).setLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (warmupChecksRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          WarmupCheck
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._warmupChecksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).warmupChecksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, $$WorkoutsTableReferences),
      Workout,
      PrefetchHooks Function({
        bool planDayId,
        bool setLogsRefs,
        bool warmupChecksRefs,
      })
    >;
typedef $$SetLogsTableCreateCompanionBuilder =
    SetLogsCompanion Function({
      Value<int> id,
      required int workoutId,
      required int exerciseId,
      required int setIndex,
      Value<double?> weightKg,
      required int reps,
      Value<int?> rir,
      Value<bool> isWarmup,
      Value<DateTime?> loggedAt,
    });
typedef $$SetLogsTableUpdateCompanionBuilder =
    SetLogsCompanion Function({
      Value<int> id,
      Value<int> workoutId,
      Value<int> exerciseId,
      Value<int> setIndex,
      Value<double?> weightKg,
      Value<int> reps,
      Value<int?> rir,
      Value<bool> isWarmup,
      Value<DateTime?> loggedAt,
    });

final class $$SetLogsTableReferences
    extends BaseReferences<_$AppDatabase, $SetLogsTable, SetLog> {
  $$SetLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) => db.workouts
      .createAlias($_aliasNameGenerator(db.setLogs.workoutId, db.workouts.id));

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.setLogs.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableFilterComposer({
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

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableOrderingComposer({
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

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetLogsTable> {
  $$SetLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<bool> get isWarmup =>
      $composableBuilder(column: $table.isWarmup, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetLogsTable,
          SetLog,
          $$SetLogsTableFilterComposer,
          $$SetLogsTableOrderingComposer,
          $$SetLogsTableAnnotationComposer,
          $$SetLogsTableCreateCompanionBuilder,
          $$SetLogsTableUpdateCompanionBuilder,
          (SetLog, $$SetLogsTableReferences),
          SetLog,
          PrefetchHooks Function({bool workoutId, bool exerciseId})
        > {
  $$SetLogsTableTableManager(_$AppDatabase db, $SetLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<DateTime?> loggedAt = const Value.absent(),
              }) => SetLogsCompanion(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                weightKg: weightKg,
                reps: reps,
                rir: rir,
                isWarmup: isWarmup,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
                required int exerciseId,
                required int setIndex,
                Value<double?> weightKg = const Value.absent(),
                required int reps,
                Value<int?> rir = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<DateTime?> loggedAt = const Value.absent(),
              }) => SetLogsCompanion.insert(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                weightKg: weightKg,
                reps: reps,
                rir: rir,
                isWarmup: isWarmup,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false, exerciseId = false}) {
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
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable: $$SetLogsTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn: $$SetLogsTableReferences
                                    ._workoutIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$SetLogsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$SetLogsTableReferences
                                    ._exerciseIdTable(db)
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

typedef $$SetLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetLogsTable,
      SetLog,
      $$SetLogsTableFilterComposer,
      $$SetLogsTableOrderingComposer,
      $$SetLogsTableAnnotationComposer,
      $$SetLogsTableCreateCompanionBuilder,
      $$SetLogsTableUpdateCompanionBuilder,
      (SetLog, $$SetLogsTableReferences),
      SetLog,
      PrefetchHooks Function({bool workoutId, bool exerciseId})
    >;
typedef $$WarmupChecksTableCreateCompanionBuilder =
    WarmupChecksCompanion Function({
      Value<int> id,
      required int workoutId,
      required int planItemId,
      required int lineIndex,
    });
typedef $$WarmupChecksTableUpdateCompanionBuilder =
    WarmupChecksCompanion Function({
      Value<int> id,
      Value<int> workoutId,
      Value<int> planItemId,
      Value<int> lineIndex,
    });

final class $$WarmupChecksTableReferences
    extends BaseReferences<_$AppDatabase, $WarmupChecksTable, WarmupCheck> {
  $$WarmupChecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(db.warmupChecks.workoutId, db.workouts.id),
      );

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlanItemsTable _planItemIdTable(_$AppDatabase db) =>
      db.planItems.createAlias(
        $_aliasNameGenerator(db.warmupChecks.planItemId, db.planItems.id),
      );

  $$PlanItemsTableProcessedTableManager get planItemId {
    final $_column = $_itemColumn<int>('plan_item_id')!;

    final manager = $$PlanItemsTableTableManager(
      $_db,
      $_db.planItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WarmupChecksTableFilterComposer
    extends Composer<_$AppDatabase, $WarmupChecksTable> {
  $$WarmupChecksTableFilterComposer({
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

  ColumnFilters<int> get lineIndex => $composableBuilder(
    column: $table.lineIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemsTableFilterComposer get planItemId {
    final $$PlanItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableFilterComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WarmupChecksTableOrderingComposer
    extends Composer<_$AppDatabase, $WarmupChecksTable> {
  $$WarmupChecksTableOrderingComposer({
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

  ColumnOrderings<int> get lineIndex => $composableBuilder(
    column: $table.lineIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemsTableOrderingComposer get planItemId {
    final $$PlanItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableOrderingComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WarmupChecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WarmupChecksTable> {
  $$WarmupChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lineIndex =>
      $composableBuilder(column: $table.lineIndex, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlanItemsTableAnnotationComposer get planItemId {
    final $$PlanItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planItemId,
      referencedTable: $db.planItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.planItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WarmupChecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WarmupChecksTable,
          WarmupCheck,
          $$WarmupChecksTableFilterComposer,
          $$WarmupChecksTableOrderingComposer,
          $$WarmupChecksTableAnnotationComposer,
          $$WarmupChecksTableCreateCompanionBuilder,
          $$WarmupChecksTableUpdateCompanionBuilder,
          (WarmupCheck, $$WarmupChecksTableReferences),
          WarmupCheck,
          PrefetchHooks Function({bool workoutId, bool planItemId})
        > {
  $$WarmupChecksTableTableManager(_$AppDatabase db, $WarmupChecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WarmupChecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WarmupChecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WarmupChecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<int> planItemId = const Value.absent(),
                Value<int> lineIndex = const Value.absent(),
              }) => WarmupChecksCompanion(
                id: id,
                workoutId: workoutId,
                planItemId: planItemId,
                lineIndex: lineIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
                required int planItemId,
                required int lineIndex,
              }) => WarmupChecksCompanion.insert(
                id: id,
                workoutId: workoutId,
                planItemId: planItemId,
                lineIndex: lineIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WarmupChecksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false, planItemId = false}) {
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
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable: $$WarmupChecksTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn: $$WarmupChecksTableReferences
                                    ._workoutIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (planItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.planItemId,
                                referencedTable: $$WarmupChecksTableReferences
                                    ._planItemIdTable(db),
                                referencedColumn: $$WarmupChecksTableReferences
                                    ._planItemIdTable(db)
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

typedef $$WarmupChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WarmupChecksTable,
      WarmupCheck,
      $$WarmupChecksTableFilterComposer,
      $$WarmupChecksTableOrderingComposer,
      $$WarmupChecksTableAnnotationComposer,
      $$WarmupChecksTableCreateCompanionBuilder,
      $$WarmupChecksTableUpdateCompanionBuilder,
      (WarmupCheck, $$WarmupChecksTableReferences),
      WarmupCheck,
      PrefetchHooks Function({bool workoutId, bool planItemId})
    >;
typedef $$FoodsTableCreateCompanionBuilder =
    FoodsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> nameLocal,
      Value<String?> brand,
      required FoodSource source,
      Value<String?> barcode,
      Value<bool> isRecipe,
      required double kcal100,
      required double protein100,
      required double carbs100,
      required double fat100,
      required double fibre100,
      Value<double?> sugar100,
      Value<double?> satFat100,
      Value<double?> sodium100,
    });
typedef $$FoodsTableUpdateCompanionBuilder =
    FoodsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> nameLocal,
      Value<String?> brand,
      Value<FoodSource> source,
      Value<String?> barcode,
      Value<bool> isRecipe,
      Value<double> kcal100,
      Value<double> protein100,
      Value<double> carbs100,
      Value<double> fat100,
      Value<double> fibre100,
      Value<double?> sugar100,
      Value<double?> satFat100,
      Value<double?> sodium100,
    });

final class $$FoodsTableReferences
    extends BaseReferences<_$AppDatabase, $FoodsTable, Food> {
  $$FoodsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ServingsTable, List<Serving>> _servingsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.servings,
    aliasName: $_aliasNameGenerator(db.foods.id, db.servings.foodId),
  );

  $$ServingsTableProcessedTableManager get servingsRefs {
    final manager = $$ServingsTableTableManager(
      $_db,
      $_db.servings,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_servingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FoodLogsTable, List<FoodLog>> _foodLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.foodLogs,
    aliasName: $_aliasNameGenerator(db.foods.id, db.foodLogs.foodId),
  );

  $$FoodLogsTableProcessedTableManager get foodLogsRefs {
    final manager = $$FoodLogsTableTableManager(
      $_db,
      $_db.foodLogs,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_foodLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoodsTableFilterComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableFilterComposer({
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

  ColumnFilters<String> get nameLocal => $composableBuilder(
    column: $table.nameLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FoodSource, FoodSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecipe => $composableBuilder(
    column: $table.isRecipe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fibre100 => $composableBuilder(
    column: $table.fibre100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get satFat100 => $composableBuilder(
    column: $table.satFat100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodium100 => $composableBuilder(
    column: $table.sodium100,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> servingsRefs(
    Expression<bool> Function($$ServingsTableFilterComposer f) f,
  ) {
    final $$ServingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.servings,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServingsTableFilterComposer(
            $db: $db,
            $table: $db.servings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> foodLogsRefs(
    Expression<bool> Function($$FoodLogsTableFilterComposer f) f,
  ) {
    final $$FoodLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodLogs,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodLogsTableFilterComposer(
            $db: $db,
            $table: $db.foodLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableOrderingComposer({
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

  ColumnOrderings<String> get nameLocal => $composableBuilder(
    column: $table.nameLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecipe => $composableBuilder(
    column: $table.isRecipe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal100 => $composableBuilder(
    column: $table.kcal100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs100 => $composableBuilder(
    column: $table.carbs100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat100 => $composableBuilder(
    column: $table.fat100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fibre100 => $composableBuilder(
    column: $table.fibre100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugar100 => $composableBuilder(
    column: $table.sugar100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get satFat100 => $composableBuilder(
    column: $table.satFat100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodium100 => $composableBuilder(
    column: $table.sodium100,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableAnnotationComposer({
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

  GeneratedColumn<String> get nameLocal =>
      $composableBuilder(column: $table.nameLocal, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FoodSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<bool> get isRecipe =>
      $composableBuilder(column: $table.isRecipe, builder: (column) => column);

  GeneratedColumn<double> get kcal100 =>
      $composableBuilder(column: $table.kcal100, builder: (column) => column);

  GeneratedColumn<double> get protein100 => $composableBuilder(
    column: $table.protein100,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbs100 =>
      $composableBuilder(column: $table.carbs100, builder: (column) => column);

  GeneratedColumn<double> get fat100 =>
      $composableBuilder(column: $table.fat100, builder: (column) => column);

  GeneratedColumn<double> get fibre100 =>
      $composableBuilder(column: $table.fibre100, builder: (column) => column);

  GeneratedColumn<double> get sugar100 =>
      $composableBuilder(column: $table.sugar100, builder: (column) => column);

  GeneratedColumn<double> get satFat100 =>
      $composableBuilder(column: $table.satFat100, builder: (column) => column);

  GeneratedColumn<double> get sodium100 =>
      $composableBuilder(column: $table.sodium100, builder: (column) => column);

  Expression<T> servingsRefs<T extends Object>(
    Expression<T> Function($$ServingsTableAnnotationComposer a) f,
  ) {
    final $$ServingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.servings,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServingsTableAnnotationComposer(
            $db: $db,
            $table: $db.servings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> foodLogsRefs<T extends Object>(
    Expression<T> Function($$FoodLogsTableAnnotationComposer a) f,
  ) {
    final $$FoodLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.foodLogs,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.foodLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodsTable,
          Food,
          $$FoodsTableFilterComposer,
          $$FoodsTableOrderingComposer,
          $$FoodsTableAnnotationComposer,
          $$FoodsTableCreateCompanionBuilder,
          $$FoodsTableUpdateCompanionBuilder,
          (Food, $$FoodsTableReferences),
          Food,
          PrefetchHooks Function({bool servingsRefs, bool foodLogsRefs})
        > {
  $$FoodsTableTableManager(_$AppDatabase db, $FoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nameLocal = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<FoodSource> source = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<bool> isRecipe = const Value.absent(),
                Value<double> kcal100 = const Value.absent(),
                Value<double> protein100 = const Value.absent(),
                Value<double> carbs100 = const Value.absent(),
                Value<double> fat100 = const Value.absent(),
                Value<double> fibre100 = const Value.absent(),
                Value<double?> sugar100 = const Value.absent(),
                Value<double?> satFat100 = const Value.absent(),
                Value<double?> sodium100 = const Value.absent(),
              }) => FoodsCompanion(
                id: id,
                name: name,
                nameLocal: nameLocal,
                brand: brand,
                source: source,
                barcode: barcode,
                isRecipe: isRecipe,
                kcal100: kcal100,
                protein100: protein100,
                carbs100: carbs100,
                fat100: fat100,
                fibre100: fibre100,
                sugar100: sugar100,
                satFat100: satFat100,
                sodium100: sodium100,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> nameLocal = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                required FoodSource source,
                Value<String?> barcode = const Value.absent(),
                Value<bool> isRecipe = const Value.absent(),
                required double kcal100,
                required double protein100,
                required double carbs100,
                required double fat100,
                required double fibre100,
                Value<double?> sugar100 = const Value.absent(),
                Value<double?> satFat100 = const Value.absent(),
                Value<double?> sodium100 = const Value.absent(),
              }) => FoodsCompanion.insert(
                id: id,
                name: name,
                nameLocal: nameLocal,
                brand: brand,
                source: source,
                barcode: barcode,
                isRecipe: isRecipe,
                kcal100: kcal100,
                protein100: protein100,
                carbs100: carbs100,
                fat100: fat100,
                fibre100: fibre100,
                sugar100: sugar100,
                satFat100: satFat100,
                sodium100: sodium100,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$FoodsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({servingsRefs = false, foodLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (servingsRefs) db.servings,
                    if (foodLogsRefs) db.foodLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (servingsRefs)
                        await $_getPrefetchedData<Food, $FoodsTable, Serving>(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._servingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).servingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (foodLogsRefs)
                        await $_getPrefetchedData<Food, $FoodsTable, FoodLog>(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._foodLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).foodLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodsTable,
      Food,
      $$FoodsTableFilterComposer,
      $$FoodsTableOrderingComposer,
      $$FoodsTableAnnotationComposer,
      $$FoodsTableCreateCompanionBuilder,
      $$FoodsTableUpdateCompanionBuilder,
      (Food, $$FoodsTableReferences),
      Food,
      PrefetchHooks Function({bool servingsRefs, bool foodLogsRefs})
    >;
typedef $$ServingsTableCreateCompanionBuilder =
    ServingsCompanion Function({
      Value<int> id,
      required int foodId,
      required String label,
      required double grams,
      Value<bool> isDefault,
    });
typedef $$ServingsTableUpdateCompanionBuilder =
    ServingsCompanion Function({
      Value<int> id,
      Value<int> foodId,
      Value<String> label,
      Value<double> grams,
      Value<bool> isDefault,
    });

final class $$ServingsTableReferences
    extends BaseReferences<_$AppDatabase, $ServingsTable, Serving> {
  $$ServingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoodsTable _foodIdTable(_$AppDatabase db) => db.foods.createAlias(
    $_aliasNameGenerator(db.servings.foodId, db.foods.id),
  );

  $$FoodsTableProcessedTableManager get foodId {
    final $_column = $_itemColumn<int>('food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ServingsTableFilterComposer
    extends Composer<_$AppDatabase, $ServingsTable> {
  $$ServingsTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ServingsTable> {
  $$ServingsTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServingsTable> {
  $$ServingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServingsTable,
          Serving,
          $$ServingsTableFilterComposer,
          $$ServingsTableOrderingComposer,
          $$ServingsTableAnnotationComposer,
          $$ServingsTableCreateCompanionBuilder,
          $$ServingsTableUpdateCompanionBuilder,
          (Serving, $$ServingsTableReferences),
          Serving,
          PrefetchHooks Function({bool foodId})
        > {
  $$ServingsTableTableManager(_$AppDatabase db, $ServingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
              }) => ServingsCompanion(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
                isDefault: isDefault,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int foodId,
                required String label,
                required double grams,
                Value<bool> isDefault = const Value.absent(),
              }) => ServingsCompanion.insert(
                id: id,
                foodId: foodId,
                label: label,
                grams: grams,
                isDefault: isDefault,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ServingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodId = false}) {
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
                    if (foodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.foodId,
                                referencedTable: $$ServingsTableReferences
                                    ._foodIdTable(db),
                                referencedColumn: $$ServingsTableReferences
                                    ._foodIdTable(db)
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

typedef $$ServingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServingsTable,
      Serving,
      $$ServingsTableFilterComposer,
      $$ServingsTableOrderingComposer,
      $$ServingsTableAnnotationComposer,
      $$ServingsTableCreateCompanionBuilder,
      $$ServingsTableUpdateCompanionBuilder,
      (Serving, $$ServingsTableReferences),
      Serving,
      PrefetchHooks Function({bool foodId})
    >;
typedef $$RecipeItemsTableCreateCompanionBuilder =
    RecipeItemsCompanion Function({
      Value<int> id,
      required int recipeFoodId,
      required int ingredientFoodId,
      required double grams,
    });
typedef $$RecipeItemsTableUpdateCompanionBuilder =
    RecipeItemsCompanion Function({
      Value<int> id,
      Value<int> recipeFoodId,
      Value<int> ingredientFoodId,
      Value<double> grams,
    });

final class $$RecipeItemsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeItemsTable, RecipeItem> {
  $$RecipeItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoodsTable _recipeFoodIdTable(_$AppDatabase db) =>
      db.foods.createAlias(
        $_aliasNameGenerator(db.recipeItems.recipeFoodId, db.foods.id),
      );

  $$FoodsTableProcessedTableManager get recipeFoodId {
    final $_column = $_itemColumn<int>('recipe_food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeFoodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FoodsTable _ingredientFoodIdTable(_$AppDatabase db) =>
      db.foods.createAlias(
        $_aliasNameGenerator(db.recipeItems.ingredientFoodId, db.foods.id),
      );

  $$FoodsTableProcessedTableManager get ingredientFoodId {
    final $_column = $_itemColumn<int>('ingredient_food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientFoodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableFilterComposer({
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

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodsTableFilterComposer get recipeFoodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeFoodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableFilterComposer get ingredientFoodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientFoodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableOrderingComposer({
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

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodsTableOrderingComposer get recipeFoodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeFoodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableOrderingComposer get ingredientFoodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientFoodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  $$FoodsTableAnnotationComposer get recipeFoodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeFoodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableAnnotationComposer get ingredientFoodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientFoodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeItemsTable,
          RecipeItem,
          $$RecipeItemsTableFilterComposer,
          $$RecipeItemsTableOrderingComposer,
          $$RecipeItemsTableAnnotationComposer,
          $$RecipeItemsTableCreateCompanionBuilder,
          $$RecipeItemsTableUpdateCompanionBuilder,
          (RecipeItem, $$RecipeItemsTableReferences),
          RecipeItem,
          PrefetchHooks Function({bool recipeFoodId, bool ingredientFoodId})
        > {
  $$RecipeItemsTableTableManager(_$AppDatabase db, $RecipeItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recipeFoodId = const Value.absent(),
                Value<int> ingredientFoodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
              }) => RecipeItemsCompanion(
                id: id,
                recipeFoodId: recipeFoodId,
                ingredientFoodId: ingredientFoodId,
                grams: grams,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recipeFoodId,
                required int ingredientFoodId,
                required double grams,
              }) => RecipeItemsCompanion.insert(
                id: id,
                recipeFoodId: recipeFoodId,
                ingredientFoodId: ingredientFoodId,
                grams: grams,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({recipeFoodId = false, ingredientFoodId = false}) {
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
                        if (recipeFoodId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.recipeFoodId,
                                    referencedTable:
                                        $$RecipeItemsTableReferences
                                            ._recipeFoodIdTable(db),
                                    referencedColumn:
                                        $$RecipeItemsTableReferences
                                            ._recipeFoodIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (ingredientFoodId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ingredientFoodId,
                                    referencedTable:
                                        $$RecipeItemsTableReferences
                                            ._ingredientFoodIdTable(db),
                                    referencedColumn:
                                        $$RecipeItemsTableReferences
                                            ._ingredientFoodIdTable(db)
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

typedef $$RecipeItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeItemsTable,
      RecipeItem,
      $$RecipeItemsTableFilterComposer,
      $$RecipeItemsTableOrderingComposer,
      $$RecipeItemsTableAnnotationComposer,
      $$RecipeItemsTableCreateCompanionBuilder,
      $$RecipeItemsTableUpdateCompanionBuilder,
      (RecipeItem, $$RecipeItemsTableReferences),
      RecipeItem,
      PrefetchHooks Function({bool recipeFoodId, bool ingredientFoodId})
    >;
typedef $$FoodLogsTableCreateCompanionBuilder =
    FoodLogsCompanion Function({
      Value<int> id,
      required DateTime date,
      required Meal meal,
      required int foodId,
      required double grams,
      required DateTime loggedAt,
    });
typedef $$FoodLogsTableUpdateCompanionBuilder =
    FoodLogsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<Meal> meal,
      Value<int> foodId,
      Value<double> grams,
      Value<DateTime> loggedAt,
    });

final class $$FoodLogsTableReferences
    extends BaseReferences<_$AppDatabase, $FoodLogsTable, FoodLog> {
  $$FoodLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoodsTable _foodIdTable(_$AppDatabase db) => db.foods.createAlias(
    $_aliasNameGenerator(db.foodLogs.foodId, db.foods.id),
  );

  $$FoodsTableProcessedTableManager get foodId {
    final $_column = $_itemColumn<int>('food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FoodLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodLogsTable> {
  $$FoodLogsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<Meal, Meal, String> get meal =>
      $composableBuilder(
        column: $table.meal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodLogsTable> {
  $$FoodLogsTableOrderingComposer({
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

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodLogsTable> {
  $$FoodLogsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<Meal, String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoodLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodLogsTable,
          FoodLog,
          $$FoodLogsTableFilterComposer,
          $$FoodLogsTableOrderingComposer,
          $$FoodLogsTableAnnotationComposer,
          $$FoodLogsTableCreateCompanionBuilder,
          $$FoodLogsTableUpdateCompanionBuilder,
          (FoodLog, $$FoodLogsTableReferences),
          FoodLog,
          PrefetchHooks Function({bool foodId})
        > {
  $$FoodLogsTableTableManager(_$AppDatabase db, $FoodLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<Meal> meal = const Value.absent(),
                Value<int> foodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => FoodLogsCompanion(
                id: id,
                date: date,
                meal: meal,
                foodId: foodId,
                grams: grams,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required Meal meal,
                required int foodId,
                required double grams,
                required DateTime loggedAt,
              }) => FoodLogsCompanion.insert(
                id: id,
                date: date,
                meal: meal,
                foodId: foodId,
                grams: grams,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoodLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodId = false}) {
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
                    if (foodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.foodId,
                                referencedTable: $$FoodLogsTableReferences
                                    ._foodIdTable(db),
                                referencedColumn: $$FoodLogsTableReferences
                                    ._foodIdTable(db)
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

typedef $$FoodLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodLogsTable,
      FoodLog,
      $$FoodLogsTableFilterComposer,
      $$FoodLogsTableOrderingComposer,
      $$FoodLogsTableAnnotationComposer,
      $$FoodLogsTableCreateCompanionBuilder,
      $$FoodLogsTableUpdateCompanionBuilder,
      (FoodLog, $$FoodLogsTableReferences),
      FoodLog,
      PrefetchHooks Function({bool foodId})
    >;
typedef $$DailyStepsTableCreateCompanionBuilder =
    DailyStepsCompanion Function({
      required DateTime date,
      required int steps,
      required double activeKcal,
      required String source,
      Value<int> rowid,
    });
typedef $$DailyStepsTableUpdateCompanionBuilder =
    DailyStepsCompanion Function({
      Value<DateTime> date,
      Value<int> steps,
      Value<double> activeKcal,
      Value<String> source,
      Value<int> rowid,
    });

class $$DailyStepsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStepsTable> {
  $$DailyStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get activeKcal => $composableBuilder(
    column: $table.activeKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStepsTable> {
  $$DailyStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get activeKcal => $composableBuilder(
    column: $table.activeKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStepsTable> {
  $$DailyStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get activeKcal => $composableBuilder(
    column: $table.activeKcal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$DailyStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyStepsTable,
          DailyStep,
          $$DailyStepsTableFilterComposer,
          $$DailyStepsTableOrderingComposer,
          $$DailyStepsTableAnnotationComposer,
          $$DailyStepsTableCreateCompanionBuilder,
          $$DailyStepsTableUpdateCompanionBuilder,
          (
            DailyStep,
            BaseReferences<_$AppDatabase, $DailyStepsTable, DailyStep>,
          ),
          DailyStep,
          PrefetchHooks Function()
        > {
  $$DailyStepsTableTableManager(_$AppDatabase db, $DailyStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> date = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<double> activeKcal = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStepsCompanion(
                date: date,
                steps: steps,
                activeKcal: activeKcal,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime date,
                required int steps,
                required double activeKcal,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => DailyStepsCompanion.insert(
                date: date,
                steps: steps,
                activeKcal: activeKcal,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyStepsTable,
      DailyStep,
      $$DailyStepsTableFilterComposer,
      $$DailyStepsTableOrderingComposer,
      $$DailyStepsTableAnnotationComposer,
      $$DailyStepsTableCreateCompanionBuilder,
      $$DailyStepsTableUpdateCompanionBuilder,
      (DailyStep, BaseReferences<_$AppDatabase, $DailyStepsTable, DailyStep>),
      DailyStep,
      PrefetchHooks Function()
    >;
typedef $$RunsTableCreateCompanionBuilder =
    RunsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required double distanceM,
      required int movingS,
      required int elapsedS,
      Value<double?> elevGainM,
      required double avgPaceSPerKm,
      Value<String?> polyline,
      Value<int?> avgHrBpm,
      Value<int?> maxHrBpm,
      Value<String?> notes,
    });
typedef $$RunsTableUpdateCompanionBuilder =
    RunsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<double> distanceM,
      Value<int> movingS,
      Value<int> elapsedS,
      Value<double?> elevGainM,
      Value<double> avgPaceSPerKm,
      Value<String?> polyline,
      Value<int?> avgHrBpm,
      Value<int?> maxHrBpm,
      Value<String?> notes,
    });

final class $$RunsTableReferences
    extends BaseReferences<_$AppDatabase, $RunsTable, Run> {
  $$RunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RunPointsTable, List<RunPoint>>
  _runPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.runPoints,
    aliasName: $_aliasNameGenerator(db.runs.id, db.runPoints.runId),
  );

  $$RunPointsTableProcessedTableManager get runPointsRefs {
    final manager = $$RunPointsTableTableManager(
      $_db,
      $_db.runPoints,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_runPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SplitsTable, List<Split>> _splitsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.splits,
    aliasName: $_aliasNameGenerator(db.runs.id, db.splits.runId),
  );

  $$SplitsTableProcessedTableManager get splitsRefs {
    final manager = $$SplitsTableTableManager(
      $_db,
      $_db.splits,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RunsTableFilterComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingS => $composableBuilder(
    column: $table.movingS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedS => $composableBuilder(
    column: $table.elapsedS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevGainM => $composableBuilder(
    column: $table.elevGainM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgPaceSPerKm => $composableBuilder(
    column: $table.avgPaceSPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get polyline => $composableBuilder(
    column: $table.polyline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgHrBpm => $composableBuilder(
    column: $table.avgHrBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHrBpm => $composableBuilder(
    column: $table.maxHrBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> runPointsRefs(
    Expression<bool> Function($$RunPointsTableFilterComposer f) f,
  ) {
    final $$RunPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runPoints,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunPointsTableFilterComposer(
            $db: $db,
            $table: $db.runPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> splitsRefs(
    Expression<bool> Function($$SplitsTableFilterComposer f) f,
  ) {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitsTableFilterComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunsTableOrderingComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingS => $composableBuilder(
    column: $table.movingS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedS => $composableBuilder(
    column: $table.elapsedS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevGainM => $composableBuilder(
    column: $table.elevGainM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgPaceSPerKm => $composableBuilder(
    column: $table.avgPaceSPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get polyline => $composableBuilder(
    column: $table.polyline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgHrBpm => $composableBuilder(
    column: $table.avgHrBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHrBpm => $composableBuilder(
    column: $table.maxHrBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get movingS =>
      $composableBuilder(column: $table.movingS, builder: (column) => column);

  GeneratedColumn<int> get elapsedS =>
      $composableBuilder(column: $table.elapsedS, builder: (column) => column);

  GeneratedColumn<double> get elevGainM =>
      $composableBuilder(column: $table.elevGainM, builder: (column) => column);

  GeneratedColumn<double> get avgPaceSPerKm => $composableBuilder(
    column: $table.avgPaceSPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get polyline =>
      $composableBuilder(column: $table.polyline, builder: (column) => column);

  GeneratedColumn<int> get avgHrBpm =>
      $composableBuilder(column: $table.avgHrBpm, builder: (column) => column);

  GeneratedColumn<int> get maxHrBpm =>
      $composableBuilder(column: $table.maxHrBpm, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> runPointsRefs<T extends Object>(
    Expression<T> Function($$RunPointsTableAnnotationComposer a) f,
  ) {
    final $$RunPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runPoints,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.runPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> splitsRefs<T extends Object>(
    Expression<T> Function($$SplitsTableAnnotationComposer a) f,
  ) {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitsTableAnnotationComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunsTable,
          Run,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (Run, $$RunsTableReferences),
          Run,
          PrefetchHooks Function({bool runPointsRefs, bool splitsRefs})
        > {
  $$RunsTableTableManager(_$AppDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<int> movingS = const Value.absent(),
                Value<int> elapsedS = const Value.absent(),
                Value<double?> elevGainM = const Value.absent(),
                Value<double> avgPaceSPerKm = const Value.absent(),
                Value<String?> polyline = const Value.absent(),
                Value<int?> avgHrBpm = const Value.absent(),
                Value<int?> maxHrBpm = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => RunsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceM: distanceM,
                movingS: movingS,
                elapsedS: elapsedS,
                elevGainM: elevGainM,
                avgPaceSPerKm: avgPaceSPerKm,
                polyline: polyline,
                avgHrBpm: avgHrBpm,
                maxHrBpm: maxHrBpm,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required double distanceM,
                required int movingS,
                required int elapsedS,
                Value<double?> elevGainM = const Value.absent(),
                required double avgPaceSPerKm,
                Value<String?> polyline = const Value.absent(),
                Value<int?> avgHrBpm = const Value.absent(),
                Value<int?> maxHrBpm = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => RunsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceM: distanceM,
                movingS: movingS,
                elapsedS: elapsedS,
                elevGainM: elevGainM,
                avgPaceSPerKm: avgPaceSPerKm,
                polyline: polyline,
                avgHrBpm: avgHrBpm,
                maxHrBpm: maxHrBpm,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RunsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({runPointsRefs = false, splitsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (runPointsRefs) db.runPoints,
                if (splitsRefs) db.splits,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (runPointsRefs)
                    await $_getPrefetchedData<Run, $RunsTable, RunPoint>(
                      currentTable: table,
                      referencedTable: $$RunsTableReferences
                          ._runPointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RunsTableReferences(db, table, p0).runPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.runId == item.id),
                      typedResults: items,
                    ),
                  if (splitsRefs)
                    await $_getPrefetchedData<Run, $RunsTable, Split>(
                      currentTable: table,
                      referencedTable: $$RunsTableReferences._splitsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$RunsTableReferences(db, table, p0).splitsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.runId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunsTable,
      Run,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (Run, $$RunsTableReferences),
      Run,
      PrefetchHooks Function({bool runPointsRefs, bool splitsRefs})
    >;
typedef $$RunPointsTableCreateCompanionBuilder =
    RunPointsCompanion Function({
      Value<int> id,
      required int runId,
      required double lat,
      required double lon,
      Value<double?> elevM,
      required DateTime timestamp,
      Value<double?> accuracyM,
      Value<double?> speedMps,
    });
typedef $$RunPointsTableUpdateCompanionBuilder =
    RunPointsCompanion Function({
      Value<int> id,
      Value<int> runId,
      Value<double> lat,
      Value<double> lon,
      Value<double?> elevM,
      Value<DateTime> timestamp,
      Value<double?> accuracyM,
      Value<double?> speedMps,
    });

final class $$RunPointsTableReferences
    extends BaseReferences<_$AppDatabase, $RunPointsTable, RunPoint> {
  $$RunPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RunsTable _runIdTable(_$AppDatabase db) =>
      db.runs.createAlias($_aliasNameGenerator(db.runPoints.runId, db.runs.id));

  $$RunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<int>('run_id')!;

    final manager = $$RunsTableTableManager(
      $_db,
      $_db.runs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RunPointsTableFilterComposer
    extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableFilterComposer({
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

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevM => $composableBuilder(
    column: $table.elevM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  $$RunsTableFilterComposer get runId {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableOrderingComposer({
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

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevM => $composableBuilder(
    column: $table.elevM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  $$RunsTableOrderingComposer get runId {
    final $$RunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableOrderingComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get elevM =>
      $composableBuilder(column: $table.elevM, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  $$RunsTableAnnotationComposer get runId {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunPointsTable,
          RunPoint,
          $$RunPointsTableFilterComposer,
          $$RunPointsTableOrderingComposer,
          $$RunPointsTableAnnotationComposer,
          $$RunPointsTableCreateCompanionBuilder,
          $$RunPointsTableUpdateCompanionBuilder,
          (RunPoint, $$RunPointsTableReferences),
          RunPoint,
          PrefetchHooks Function({bool runId})
        > {
  $$RunPointsTableTableManager(_$AppDatabase db, $RunPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> runId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> elevM = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
              }) => RunPointsCompanion(
                id: id,
                runId: runId,
                lat: lat,
                lon: lon,
                elevM: elevM,
                timestamp: timestamp,
                accuracyM: accuracyM,
                speedMps: speedMps,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int runId,
                required double lat,
                required double lon,
                Value<double?> elevM = const Value.absent(),
                required DateTime timestamp,
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
              }) => RunPointsCompanion.insert(
                id: id,
                runId: runId,
                lat: lat,
                lon: lon,
                elevM: elevM,
                timestamp: timestamp,
                accuracyM: accuracyM,
                speedMps: speedMps,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RunPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $$RunPointsTableReferences
                                    ._runIdTable(db),
                                referencedColumn: $$RunPointsTableReferences
                                    ._runIdTable(db)
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

typedef $$RunPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunPointsTable,
      RunPoint,
      $$RunPointsTableFilterComposer,
      $$RunPointsTableOrderingComposer,
      $$RunPointsTableAnnotationComposer,
      $$RunPointsTableCreateCompanionBuilder,
      $$RunPointsTableUpdateCompanionBuilder,
      (RunPoint, $$RunPointsTableReferences),
      RunPoint,
      PrefetchHooks Function({bool runId})
    >;
typedef $$SplitsTableCreateCompanionBuilder =
    SplitsCompanion Function({
      Value<int> id,
      required int runId,
      required int km,
      required int durationS,
      required double distanceM,
      Value<bool> isPartial,
      Value<double?> elevDeltaM,
    });
typedef $$SplitsTableUpdateCompanionBuilder =
    SplitsCompanion Function({
      Value<int> id,
      Value<int> runId,
      Value<int> km,
      Value<int> durationS,
      Value<double> distanceM,
      Value<bool> isPartial,
      Value<double?> elevDeltaM,
    });

final class $$SplitsTableReferences
    extends BaseReferences<_$AppDatabase, $SplitsTable, Split> {
  $$SplitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RunsTable _runIdTable(_$AppDatabase db) =>
      db.runs.createAlias($_aliasNameGenerator(db.splits.runId, db.runs.id));

  $$RunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<int>('run_id')!;

    final manager = $$RunsTableTableManager(
      $_db,
      $_db.runs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SplitsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableFilterComposer({
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

  ColumnFilters<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPartial => $composableBuilder(
    column: $table.isPartial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevDeltaM => $composableBuilder(
    column: $table.elevDeltaM,
    builder: (column) => ColumnFilters(column),
  );

  $$RunsTableFilterComposer get runId {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableOrderingComposer({
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

  ColumnOrderings<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPartial => $composableBuilder(
    column: $table.isPartial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevDeltaM => $composableBuilder(
    column: $table.elevDeltaM,
    builder: (column) => ColumnOrderings(column),
  );

  $$RunsTableOrderingComposer get runId {
    final $$RunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableOrderingComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get km =>
      $composableBuilder(column: $table.km, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<bool> get isPartial =>
      $composableBuilder(column: $table.isPartial, builder: (column) => column);

  GeneratedColumn<double> get elevDeltaM => $composableBuilder(
    column: $table.elevDeltaM,
    builder: (column) => column,
  );

  $$RunsTableAnnotationComposer get runId {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitsTable,
          Split,
          $$SplitsTableFilterComposer,
          $$SplitsTableOrderingComposer,
          $$SplitsTableAnnotationComposer,
          $$SplitsTableCreateCompanionBuilder,
          $$SplitsTableUpdateCompanionBuilder,
          (Split, $$SplitsTableReferences),
          Split,
          PrefetchHooks Function({bool runId})
        > {
  $$SplitsTableTableManager(_$AppDatabase db, $SplitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> runId = const Value.absent(),
                Value<int> km = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<bool> isPartial = const Value.absent(),
                Value<double?> elevDeltaM = const Value.absent(),
              }) => SplitsCompanion(
                id: id,
                runId: runId,
                km: km,
                durationS: durationS,
                distanceM: distanceM,
                isPartial: isPartial,
                elevDeltaM: elevDeltaM,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int runId,
                required int km,
                required int durationS,
                required double distanceM,
                Value<bool> isPartial = const Value.absent(),
                Value<double?> elevDeltaM = const Value.absent(),
              }) => SplitsCompanion.insert(
                id: id,
                runId: runId,
                km: km,
                durationS: durationS,
                distanceM: distanceM,
                isPartial: isPartial,
                elevDeltaM: elevDeltaM,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SplitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $$SplitsTableReferences
                                    ._runIdTable(db),
                                referencedColumn: $$SplitsTableReferences
                                    ._runIdTable(db)
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

typedef $$SplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitsTable,
      Split,
      $$SplitsTableFilterComposer,
      $$SplitsTableOrderingComposer,
      $$SplitsTableAnnotationComposer,
      $$SplitsTableCreateCompanionBuilder,
      $$SplitsTableUpdateCompanionBuilder,
      (Split, $$SplitsTableReferences),
      Split,
      PrefetchHooks Function({bool runId})
    >;
typedef $$MeasurementsTableCreateCompanionBuilder =
    MeasurementsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<double?> weightKg,
      Value<double?> waistCm,
      Value<double?> chestCm,
      Value<double?> armCm,
      Value<double?> thighCm,
      Value<double?> hipCm,
      Value<double?> neckCm,
      Value<double?> broadJumpCm,
    });
typedef $$MeasurementsTableUpdateCompanionBuilder =
    MeasurementsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<double?> weightKg,
      Value<double?> waistCm,
      Value<double?> chestCm,
      Value<double?> armCm,
      Value<double?> thighCm,
      Value<double?> hipCm,
      Value<double?> neckCm,
      Value<double?> broadJumpCm,
    });

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
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

  ColumnFilters<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get armCm => $composableBuilder(
    column: $table.armCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hipCm => $composableBuilder(
    column: $table.hipCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get broadJumpCm => $composableBuilder(
    column: $table.broadJumpCm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
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

  ColumnOrderings<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get armCm => $composableBuilder(
    column: $table.armCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hipCm => $composableBuilder(
    column: $table.hipCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get broadJumpCm => $composableBuilder(
    column: $table.broadJumpCm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
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

  GeneratedColumn<double> get waistCm =>
      $composableBuilder(column: $table.waistCm, builder: (column) => column);

  GeneratedColumn<double> get chestCm =>
      $composableBuilder(column: $table.chestCm, builder: (column) => column);

  GeneratedColumn<double> get armCm =>
      $composableBuilder(column: $table.armCm, builder: (column) => column);

  GeneratedColumn<double> get thighCm =>
      $composableBuilder(column: $table.thighCm, builder: (column) => column);

  GeneratedColumn<double> get hipCm =>
      $composableBuilder(column: $table.hipCm, builder: (column) => column);

  GeneratedColumn<double> get neckCm =>
      $composableBuilder(column: $table.neckCm, builder: (column) => column);

  GeneratedColumn<double> get broadJumpCm => $composableBuilder(
    column: $table.broadJumpCm,
    builder: (column) => column,
  );
}

class $$MeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeasurementsTable,
          Measurement,
          $$MeasurementsTableFilterComposer,
          $$MeasurementsTableOrderingComposer,
          $$MeasurementsTableAnnotationComposer,
          $$MeasurementsTableCreateCompanionBuilder,
          $$MeasurementsTableUpdateCompanionBuilder,
          (
            Measurement,
            BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>,
          ),
          Measurement,
          PrefetchHooks Function()
        > {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> armCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> hipCm = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> broadJumpCm = const Value.absent(),
              }) => MeasurementsCompanion(
                id: id,
                date: date,
                weightKg: weightKg,
                waistCm: waistCm,
                chestCm: chestCm,
                armCm: armCm,
                thighCm: thighCm,
                hipCm: hipCm,
                neckCm: neckCm,
                broadJumpCm: broadJumpCm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<double?> weightKg = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> armCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> hipCm = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> broadJumpCm = const Value.absent(),
              }) => MeasurementsCompanion.insert(
                id: id,
                date: date,
                weightKg: weightKg,
                waistCm: waistCm,
                chestCm: chestCm,
                armCm: armCm,
                thighCm: thighCm,
                hipCm: hipCm,
                neckCm: neckCm,
                broadJumpCm: broadJumpCm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeasurementsTable,
      Measurement,
      $$MeasurementsTableFilterComposer,
      $$MeasurementsTableOrderingComposer,
      $$MeasurementsTableAnnotationComposer,
      $$MeasurementsTableCreateCompanionBuilder,
      $$MeasurementsTableUpdateCompanionBuilder,
      (
        Measurement,
        BaseReferences<_$AppDatabase, $MeasurementsTable, Measurement>,
      ),
      Measurement,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
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

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
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

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
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

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$PlanDaysTableTableManager get planDays =>
      $$PlanDaysTableTableManager(_db, _db.planDays);
  $$PlanItemsTableTableManager get planItems =>
      $$PlanItemsTableTableManager(_db, _db.planItems);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$SetLogsTableTableManager get setLogs =>
      $$SetLogsTableTableManager(_db, _db.setLogs);
  $$WarmupChecksTableTableManager get warmupChecks =>
      $$WarmupChecksTableTableManager(_db, _db.warmupChecks);
  $$FoodsTableTableManager get foods =>
      $$FoodsTableTableManager(_db, _db.foods);
  $$ServingsTableTableManager get servings =>
      $$ServingsTableTableManager(_db, _db.servings);
  $$RecipeItemsTableTableManager get recipeItems =>
      $$RecipeItemsTableTableManager(_db, _db.recipeItems);
  $$FoodLogsTableTableManager get foodLogs =>
      $$FoodLogsTableTableManager(_db, _db.foodLogs);
  $$DailyStepsTableTableManager get dailySteps =>
      $$DailyStepsTableTableManager(_db, _db.dailySteps);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$RunPointsTableTableManager get runPoints =>
      $$RunPointsTableTableManager(_db, _db.runPoints);
  $$SplitsTableTableManager get splits =>
      $$SplitsTableTableManager(_db, _db.splits);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
