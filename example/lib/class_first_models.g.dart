// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_first_models.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// Private aliases preserve public underlying types while avoiding model member
// shadowing. Their visibility is intentional; no private runtime type escapes.
// ignore_for_file: library_private_types_in_public_api

typedef _AckObject = Object;
typedef _AckDynamic = dynamic;
typedef _AckString = String;
typedef _AckMap<K, V> = Map<K, V>;
typedef _AckBool = bool;
typedef _AckInt = int;
typedef _AckSchema<B extends Object, R extends Object> = AckSchema<B, R>;
typedef _AckSchemaResult<T extends Object> = SchemaResult<T>;

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
    Cat(id: value['id'] as String, lives: value['lives'] as int);

Map<String, Object?> _$CatToRuntime(Cat model) => <String, Object?>{
  'id': model.id,
  'lives': model.lives,
  'type': 'cat',
};

typedef _$CatSchemaApi = CatSchema;
typedef _$CatCopyWithApi<$Result> = $CatCopyWith<$Result>;

bool _$CatEquals(Cat self, Object other) =>
    identical(self, other) ||
    (other is Cat &&
        self.runtimeType == other.runtimeType &&
        deepEquals(self.id, other.id) &&
        deepEquals(self.lives, other.lives));

int _$CatHashCode(Cat self) => Object.hashAll([
  self.runtimeType,
  deepHashCode(self.id),
  deepHashCode(self.lives),
]);

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

augment final class Cat {
  /// Creates a copy with selected fields replaced.
  _$CatCopyWithApi<Cat> get copyWith => _$CatCopyWith(this);

  _AckBool operator ==(_AckObject other) => _$CatEquals(this, other);

  _AckInt get hashCode => _$CatHashCode(this);

  _AckString toString() => 'Cat(id: $id, lives: $lives)';

  static _AckSchema<_AckMap<_AckString, _AckObject?>, Cat> get schema =>
      _$CatSchemaApi.schema;

  /// Validates decoded JSON and creates a model.
  factory Cat.fromJson(_AckMap<_AckString, _AckDynamic> json) =>
      _$CatSchemaApi.fromJson(json);

  /// Validates an untrusted value and creates a model.
  static Cat parse(_AckObject? value, {_AckString? debugName}) =>
      _$CatSchemaApi.parse(value, debugName: debugName);

  /// Validates an untrusted value without throwing on validation failure.
  static _AckSchemaResult<Cat> safeParse(
    _AckObject? value, {
    _AckString? debugName,
  }) => _$CatSchemaApi.safeParse(value, debugName: debugName);

  /// Validates this model and encodes it for JSON.
  _AckMap<_AckString, _AckDynamic> toJson() =>
      _AckMap<_AckString, _AckDynamic>.from(_$CatSchemaApi.encode(this));

  /// Validates this model and encodes it without throwing on validation failure.
  _AckSchemaResult<_AckMap<_AckString, _AckObject?>> safeToJson() =>
      _$CatSchemaApi.safeEncode(this);
}

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
    Dog(id: value['id'] as String, breed: value['breed'] as String);

Map<String, Object?> _$DogToRuntime(Dog model) => <String, Object?>{
  'id': model.id,
  'breed': model.breed,
  'type': 'Dog',
};

typedef _$DogSchemaApi = DogSchema;
typedef _$DogCopyWithApi<$Result> = $DogCopyWith<$Result>;

bool _$DogEquals(Dog self, Object other) =>
    identical(self, other) ||
    (other is Dog &&
        self.runtimeType == other.runtimeType &&
        deepEquals(self.id, other.id) &&
        deepEquals(self.breed, other.breed));

int _$DogHashCode(Dog self) => Object.hashAll([
  self.runtimeType,
  deepHashCode(self.id),
  deepHashCode(self.breed),
]);

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

augment final class Dog {
  /// Creates a copy with selected fields replaced.
  _$DogCopyWithApi<Dog> get copyWith => _$DogCopyWith(this);

  _AckBool operator ==(_AckObject other) => _$DogEquals(this, other);

  _AckInt get hashCode => _$DogHashCode(this);

  _AckString toString() => 'Dog(id: $id, breed: $breed)';

  static _AckSchema<_AckMap<_AckString, _AckObject?>, Dog> get schema =>
      _$DogSchemaApi.schema;

  /// Validates decoded JSON and creates a model.
  factory Dog.fromJson(_AckMap<_AckString, _AckDynamic> json) =>
      _$DogSchemaApi.fromJson(json);

  /// Validates an untrusted value and creates a model.
  static Dog parse(_AckObject? value, {_AckString? debugName}) =>
      _$DogSchemaApi.parse(value, debugName: debugName);

  /// Validates an untrusted value without throwing on validation failure.
  static _AckSchemaResult<Dog> safeParse(
    _AckObject? value, {
    _AckString? debugName,
  }) => _$DogSchemaApi.safeParse(value, debugName: debugName);

  /// Validates this model and encodes it for JSON.
  _AckMap<_AckString, _AckDynamic> toJson() =>
      _AckMap<_AckString, _AckDynamic>.from(_$DogSchemaApi.encode(this));

  /// Validates this model and encodes it without throwing on validation failure.
  _AckSchemaResult<_AckMap<_AckString, _AckObject?>> safeToJson() =>
      _$DogSchemaApi.safeEncode(this);
}

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

typedef _$PetSchemaApi = PetSchema;

augment sealed class Pet {
  static _AckSchema<_AckMap<_AckString, _AckObject?>, Pet> get schema =>
      _$PetSchemaApi.schema;

  /// Validates decoded JSON and creates a model.
  factory Pet.fromJson(_AckMap<_AckString, _AckDynamic> json) =>
      _$PetSchemaApi.fromJson(json);

  /// Validates an untrusted value and creates a model.
  static Pet parse(_AckObject? value, {_AckString? debugName}) =>
      _$PetSchemaApi.parse(value, debugName: debugName);

  /// Validates an untrusted value without throwing on validation failure.
  static _AckSchemaResult<Pet> safeParse(
    _AckObject? value, {
    _AckString? debugName,
  }) => _$PetSchemaApi.safeParse(value, debugName: debugName);

  /// Validates this model and encodes it for JSON.
  _AckMap<_AckString, _AckDynamic> toJson() =>
      _AckMap<_AckString, _AckDynamic>.from(_$PetSchemaApi.encode(this));

  /// Validates this model and encodes it without throwing on validation failure.
  _AckSchemaResult<_AckMap<_AckString, _AckObject?>> safeToJson() =>
      _$PetSchemaApi.safeEncode(this);
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

Account _$AccountFromRuntime(Map<String, Object?> value) => Account(
  displayName: value['display_name'] as String,
  website: value['website'] as Uri?,
  role: value['role'] as String? ?? 'member',
);

Map<String, Object?> _$AccountToRuntime(Account model) => <String, Object?>{
  'display_name': model.displayName,
  'website': ?model.website,
  'role': model.role,
};

typedef _$AccountSchemaApi = AccountSchema;
typedef _$AccountCopyWithApi<$Result> = $AccountCopyWith<$Result>;

bool _$AccountEquals(Account self, Object other) =>
    identical(self, other) ||
    (other is Account &&
        self.runtimeType == other.runtimeType &&
        deepEquals(self.displayName, other.displayName) &&
        deepEquals(self.website, other.website) &&
        deepEquals(self.role, other.role));

int _$AccountHashCode(Account self) => Object.hashAll([
  self.runtimeType,
  deepHashCode(self.displayName),
  deepHashCode(self.website),
  deepHashCode(self.role),
]);

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

  static bool _ackIsCopyWithUnset(Object? value) =>
      identical(value, _ackCopyWithUnset);

  final Account _source;

  @override
  Account call({
    String? displayName,
    Object? website = _ackCopyWithUnset,
    String? role,
  }) => Account(
    displayName: displayName ?? _source.displayName,
    website: _ackIsCopyWithUnset(website) ? _source.website : website as Uri?,
    role: role ?? _source.role,
  );
}

augment final class Account {
  /// Creates a copy with selected fields replaced.
  _$AccountCopyWithApi<Account> get copyWith => _$AccountCopyWith(this);

  _AckBool operator ==(_AckObject other) => _$AccountEquals(this, other);

  _AckInt get hashCode => _$AccountHashCode(this);

  _AckString toString() =>
      'Account(displayName: $displayName, website: $website, role: $role)';

  static _AckSchema<_AckMap<_AckString, _AckObject?>, Account> get schema =>
      _$AccountSchemaApi.schema;

  /// Validates decoded JSON and creates a model.
  factory Account.fromJson(_AckMap<_AckString, _AckDynamic> json) =>
      _$AccountSchemaApi.fromJson(json);

  /// Validates an untrusted value and creates a model.
  static Account parse(_AckObject? value, {_AckString? debugName}) =>
      _$AccountSchemaApi.parse(value, debugName: debugName);

  /// Validates an untrusted value without throwing on validation failure.
  static _AckSchemaResult<Account> safeParse(
    _AckObject? value, {
    _AckString? debugName,
  }) => _$AccountSchemaApi.safeParse(value, debugName: debugName);

  /// Validates this model and encodes it for JSON.
  _AckMap<_AckString, _AckDynamic> toJson() =>
      _AckMap<_AckString, _AckDynamic>.from(_$AccountSchemaApi.encode(this));

  /// Validates this model and encodes it without throwing on validation failure.
  _AckSchemaResult<_AckMap<_AckString, _AckObject?>> safeToJson() =>
      _$AccountSchemaApi.safeEncode(this);
}
