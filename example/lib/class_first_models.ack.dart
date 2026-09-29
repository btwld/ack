// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'class_first_models.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

final _catObject = Ack.object({
  'type': Ack.literal('cat').optional(),
  'id': Ack.string(),
  'lives': Ack.integer().min(1).max(9),
}).describe('A cat with a limited number of lives.');

final _catWireSchema = Ack.preserveBoundary(_catObject);

final _catSchema = _catObject
    .codec<Cat>(decode: _$CatFromRuntime, encode: _$CatToRuntime)
    .describe('A cat with a limited number of lives.');

/// Parses, validates, and encodes [Cat] values.
abstract final class CatSchema {
  /// The typed schema, for composing [Cat] into other schemas.
  static AckSchema<Map<String, Object?>, Cat> get schema => _catSchema;

  /// The structural JSON map schema behind [schema].
  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _catWireSchema;

  /// Validates [value] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Cat parse(Object? value, {String? debugName}) =>
      _catSchema.parse(value, debugName: debugName)!;

  /// Validates [value] and returns the model or the validation failure.
  static SchemaResult<Cat> safeParse(Object? value, {String? debugName}) =>
      _catSchema.safeParse(value, debugName: debugName);

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Cat fromJson(Map<String, dynamic> json) => parse(json);

  /// Validates [value] and encodes it as a JSON map.
  ///
  /// Throws an `AckException` when validation fails.
  static Map<String, Object?> encode(Cat value, {String? debugName}) =>
      _catSchema.encode(value, debugName: debugName)!;

  /// Validates [value] and encodes it as a JSON map, returning the validation
  /// failure instead of throwing.
  static SchemaResult<Map<String, Object?>> safeEncode(
    Cat value, {
    String? debugName,
  }) => _catSchema.safeEncode(value, debugName: debugName);

  /// The JSON Schema that describes [Cat].
  static Map<String, Object?> toJsonSchema() => _catSchema.toJsonSchema();

  /// The schema model that describes [Cat].
  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_catSchema).toSchemaModel();
}

Cat _$CatFromRuntime(Map<String, Object?> value) =>
    _$CatFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$CatToRuntime(Cat model) {
  final result = <String, Object?>{..._$CatToJson(model)};
  return <String, Object?>{...result, 'type': 'cat'};
}

/// Creates copies of [Cat] with selected fields replaced.
abstract interface class $CatCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? id, int? lives});
}

final class _$CatCopyWith implements $CatCopyWith<Cat> {
  const _$CatCopyWith(this._source);

  final Cat _source;

  @override
  Cat call({String? id, int? lives}) =>
      Cat(id: id ?? _source.id, lives: lives ?? _source.lives);
}

mixin _$CatAck {
  /// Creates a copy of this model with selected fields replaced.
  $CatCopyWith<Cat> get copyWith => _$CatCopyWith(this as Cat);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Cat || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as Cat;
    return deepEquals(self.id, other.id) && deepEquals(self.lives, other.lives);
  }

  @override
  int get hashCode {
    final self = this as Cat;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.id),
      deepHashCode(self.lives),
    ]);
  }

  @override
  String toString() {
    final self = this as Cat;
    return 'Cat(id: ${self.id}, lives: ${self.lives})';
  }

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(CatSchema.encode(this as Cat));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() =>
      CatSchema.safeEncode(this as Cat);
}

String _ackCatFromRuntimeId(Object? value) => value as String;
Object? _ackCatToRuntimeId(String value) => value;
int _ackCatFromRuntimeLives(Object? value) => value as int;
Object? _ackCatToRuntimeLives(int value) => value;

final _dogObject = Ack.object({
  'type': Ack.literal('Dog').optional(),
  'id': Ack.string(),
  'breed': Ack.string(),
});

final _dogWireSchema = Ack.preserveBoundary(_dogObject);

final _dogSchema = _dogObject.codec<Dog>(
  decode: _$DogFromRuntime,
  encode: _$DogToRuntime,
);

/// Parses, validates, and encodes [Dog] values.
abstract final class DogSchema {
  /// The typed schema, for composing [Dog] into other schemas.
  static AckSchema<Map<String, Object?>, Dog> get schema => _dogSchema;

  /// The structural JSON map schema behind [schema].
  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _dogWireSchema;

  /// Validates [value] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Dog parse(Object? value, {String? debugName}) =>
      _dogSchema.parse(value, debugName: debugName)!;

  /// Validates [value] and returns the model or the validation failure.
  static SchemaResult<Dog> safeParse(Object? value, {String? debugName}) =>
      _dogSchema.safeParse(value, debugName: debugName);

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Dog fromJson(Map<String, dynamic> json) => parse(json);

  /// Validates [value] and encodes it as a JSON map.
  ///
  /// Throws an `AckException` when validation fails.
  static Map<String, Object?> encode(Dog value, {String? debugName}) =>
      _dogSchema.encode(value, debugName: debugName)!;

  /// Validates [value] and encodes it as a JSON map, returning the validation
  /// failure instead of throwing.
  static SchemaResult<Map<String, Object?>> safeEncode(
    Dog value, {
    String? debugName,
  }) => _dogSchema.safeEncode(value, debugName: debugName);

  /// The JSON Schema that describes [Dog].
  static Map<String, Object?> toJsonSchema() => _dogSchema.toJsonSchema();

  /// The schema model that describes [Dog].
  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_dogSchema).toSchemaModel();
}

Dog _$DogFromRuntime(Map<String, Object?> value) =>
    _$DogFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$DogToRuntime(Dog model) {
  final result = <String, Object?>{..._$DogToJson(model)};
  return <String, Object?>{...result, 'type': 'Dog'};
}

/// Creates copies of [Dog] with selected fields replaced.
abstract interface class $DogCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? id, String? breed});
}

final class _$DogCopyWith implements $DogCopyWith<Dog> {
  const _$DogCopyWith(this._source);

  final Dog _source;

  @override
  Dog call({String? id, String? breed}) =>
      Dog(id: id ?? _source.id, breed: breed ?? _source.breed);
}

mixin _$DogAck {
  /// Creates a copy of this model with selected fields replaced.
  $DogCopyWith<Dog> get copyWith => _$DogCopyWith(this as Dog);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Dog || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as Dog;
    return deepEquals(self.id, other.id) && deepEquals(self.breed, other.breed);
  }

  @override
  int get hashCode {
    final self = this as Dog;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.id),
      deepHashCode(self.breed),
    ]);
  }

  @override
  String toString() {
    final self = this as Dog;
    return 'Dog(id: ${self.id}, breed: ${self.breed})';
  }

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(DogSchema.encode(this as Dog));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() =>
      DogSchema.safeEncode(this as Dog);
}

String _ackDogFromRuntimeId(Object? value) => value as String;
Object? _ackDogToRuntimeId(String value) => value;
String _ackDogFromRuntimeBreed(Object? value) => value as String;
Object? _ackDogToRuntimeBreed(String value) => value;

final _petObject = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'cat': _catObject, 'Dog': _dogObject},
).describe('A pet, identified by its `type`.');

final _petWireSchema = Ack.preserveBoundary(_petObject);

final _petSchema = _petObject
    .codec<Pet>(
      decode: (value) => switch (value['type']) {
        'cat' => _$CatFromRuntime(value),
        'Dog' => _$DogFromRuntime(value),
        final unknown => throw StateError('Unknown type: $unknown'),
      },
      encode: (model) => switch (model) {
        Cat() => _$CatToRuntime(model),
        Dog() => _$DogToRuntime(model),
      },
    )
    .describe('A pet, identified by its `type`.');

/// Parses, validates, and encodes [Pet] values.
abstract final class PetSchema {
  /// The typed schema, for composing [Pet] into other schemas.
  static AckSchema<Map<String, Object?>, Pet> get schema => _petSchema;

  /// The structural JSON map schema behind [schema].
  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _petWireSchema;

  /// Validates [value] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Pet parse(Object? value, {String? debugName}) =>
      _petSchema.parse(value, debugName: debugName)!;

  /// Validates [value] and returns the model or the validation failure.
  static SchemaResult<Pet> safeParse(Object? value, {String? debugName}) =>
      _petSchema.safeParse(value, debugName: debugName);

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Pet fromJson(Map<String, dynamic> json) => parse(json);

  /// Validates [value] and encodes it as a JSON map.
  ///
  /// Throws an `AckException` when validation fails.
  static Map<String, Object?> encode(Pet value, {String? debugName}) =>
      _petSchema.encode(value, debugName: debugName)!;

  /// Validates [value] and encodes it as a JSON map, returning the validation
  /// failure instead of throwing.
  static SchemaResult<Map<String, Object?>> safeEncode(
    Pet value, {
    String? debugName,
  }) => _petSchema.safeEncode(value, debugName: debugName);

  /// The JSON Schema that describes [Pet].
  static Map<String, Object?> toJsonSchema() => _petSchema.toJsonSchema();

  /// The schema model that describes [Pet].
  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_petSchema).toSchemaModel();
}

mixin _$PetAck {
  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(PetSchema.encode(this as Pet));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() =>
      PetSchema.safeEncode(this as Pet);
}

final _accountObject = Ack.object({
  'display_name': Ack.string()
      .minLength(2)
      .describe('The name shown to other users.'),
  'website': Ack.uri().optional().nullable(),
  'role': Ack.string().withDefault('member'),
}).describe('A signed-in user\'s account.');

final _accountWireSchema = Ack.preserveBoundary(_accountObject);

final _accountSchema = _accountObject
    .codec<Account>(decode: _$AccountFromRuntime, encode: _$AccountToRuntime)
    .describe('A signed-in user\'s account.');

/// Parses, validates, and encodes [Account] values.
abstract final class AccountSchema {
  /// The typed schema, for composing [Account] into other schemas.
  static AckSchema<Map<String, Object?>, Account> get schema => _accountSchema;

  /// The structural JSON map schema behind [schema].
  static AckSchema<Map<String, Object?>, Map<String, Object?>> get wireSchema =>
      _accountWireSchema;

  /// Validates [value] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Account parse(Object? value, {String? debugName}) =>
      _accountSchema.parse(value, debugName: debugName)!;

  /// Validates [value] and returns the model or the validation failure.
  static SchemaResult<Account> safeParse(Object? value, {String? debugName}) =>
      _accountSchema.safeParse(value, debugName: debugName);

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static Account fromJson(Map<String, dynamic> json) => parse(json);

  /// Validates [value] and encodes it as a JSON map.
  ///
  /// Throws an `AckException` when validation fails.
  static Map<String, Object?> encode(Account value, {String? debugName}) =>
      _accountSchema.encode(value, debugName: debugName)!;

  /// Validates [value] and encodes it as a JSON map, returning the validation
  /// failure instead of throwing.
  static SchemaResult<Map<String, Object?>> safeEncode(
    Account value, {
    String? debugName,
  }) => _accountSchema.safeEncode(value, debugName: debugName);

  /// The JSON Schema that describes [Account].
  static Map<String, Object?> toJsonSchema() => _accountSchema.toJsonSchema();

  /// The schema model that describes [Account].
  static AckSchemaModel toSchemaModel() =>
      AckSchemaModelExtension(_accountSchema).toSchemaModel();
}

Account _$AccountFromRuntime(Map<String, Object?> value) =>
    _$AccountFromJson(Map<String, dynamic>.from(value));

Map<String, Object?> _$AccountToRuntime(Account model) => <String, Object?>{
  ..._$AccountToJson(model),
};

final class _AccountCopyWithUnset {
  const _AccountCopyWithUnset();
}

/// Creates copies of [Account] with selected fields replaced.
abstract interface class $AccountCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? displayName, Uri? website, String? role});
}

final class _$AccountCopyWith implements $AccountCopyWith<Account> {
  const _$AccountCopyWith(this._source);

  static const _AccountCopyWithUnset _ackCopyWithUnset =
      _AccountCopyWithUnset();

  final Account _source;

  @override
  Account call({
    String? displayName,
    Object? website = _ackCopyWithUnset,
    String? role,
  }) => Account(
    displayName: displayName ?? _source.displayName,
    website: identical(website, _ackCopyWithUnset)
        ? _source.website
        : website as Uri?,
    role: role ?? _source.role,
  );
}

mixin _$AccountAck {
  /// Creates a copy of this model with selected fields replaced.
  $AccountCopyWith<Account> get copyWith => _$AccountCopyWith(this as Account);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Account || runtimeType != other.runtimeType) {
      return false;
    }
    final self = this as Account;
    return deepEquals(self.displayName, other.displayName) &&
        deepEquals(self.website, other.website) &&
        deepEquals(self.role, other.role);
  }

  @override
  int get hashCode {
    final self = this as Account;
    return Object.hashAll([
      runtimeType,
      deepHashCode(self.displayName),
      deepHashCode(self.website),
      deepHashCode(self.role),
    ]);
  }

  @override
  String toString() {
    final self = this as Account;
    return 'Account(displayName: ${self.displayName}, website: ${self.website}, role: ${self.role})';
  }

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(AccountSchema.encode(this as Account));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() =>
      AccountSchema.safeEncode(this as Account);
}

String _ackAccountFromRuntimeDisplayName(Object? value) => value as String;
Object? _ackAccountToRuntimeDisplayName(String value) => value;
Uri? _ackAccountFromRuntimeWebsite(Object? value) => value as Uri?;
Object? _ackAccountToRuntimeWebsite(Uri? value) => value;
String? _ackAccountFromRuntimeRole(Object? value) => value as String?;
Object? _ackAccountToRuntimeRole(String value) => value;
