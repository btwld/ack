// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'pet.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

/// Discriminated model base generated from `petSchema`.
sealed class Pet {
  /// Creates a branch of this union.
  const Pet();

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Pet.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Pet.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => petSchema,
    fromRuntime: Pet._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Pet> safeParse(Object? input) => $ack.safeParse(input);

  /// The discriminator value that selects this branch.
  String get type;

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  static Pet _fromAckRuntime(Map<String, Object?> value) {
    return switch (value['type']) {
      'cat' => Cat._fromAckRuntime(value),
      'dog' => Dog._fromAckRuntime(value),
      final unknown => throw StateError('Unknown type: $unknown'),
    };
  }

  Map<String, Object?> _toAckRuntime();
}

/// Discriminated model branch generated from `catSchema`.
@AckInfer.jsonSerializable
final class Cat extends Pet {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Cat({required this.lives});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Cat.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Cat.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final int lives;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => petSchema.effectiveBranch('cat'),
    fromRuntime: Cat._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Cat> safeParse(Object? input) => $ack.safeParse(input);

  @override
  String get type => 'cat';

  /// Creates a copy of this model with selected fields replaced.
  $CatCopyWith<Cat> get copyWith => _$CatCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cat &&
          runtimeType == other.runtimeType &&
          deepEquals(lives, other.lives));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(lives)]);

  @override
  String toString() => 'Cat(lives: $lives)';

  static Cat _fromAckRuntime(Map<String, Object?> value) =>
      _$CatFromJson(Map<String, dynamic>.from(value));

  @override
  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'type': 'cat',
    ..._$CatToJson(this),
  };

  static int _ackFromRuntimeLives(Object? value) => value as int;

  static Object? _ackToRuntimeLives(int value) => value;
}

/// Creates copies of [Cat] with selected fields replaced.
abstract interface class $CatCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({int? lives});
}

final class _$CatCopyWith implements $CatCopyWith<Cat> {
  const _$CatCopyWith(this._source);

  final Cat _source;

  @override
  Cat call({int? lives}) => Cat(lives: lives ?? _source.lives);
}

/// Discriminated model branch generated from `dogSchema`.
@AckInfer.jsonSerializable
final class Dog extends Pet {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Dog({required this.breed});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Dog.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Dog.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String breed;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => petSchema.effectiveBranch('dog'),
    fromRuntime: Dog._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Dog> safeParse(Object? input) => $ack.safeParse(input);

  @override
  String get type => 'dog';

  /// Creates a copy of this model with selected fields replaced.
  $DogCopyWith<Dog> get copyWith => _$DogCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dog &&
          runtimeType == other.runtimeType &&
          deepEquals(breed, other.breed));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(breed)]);

  @override
  String toString() => 'Dog(breed: $breed)';

  static Dog _fromAckRuntime(Map<String, Object?> value) =>
      _$DogFromJson(Map<String, dynamic>.from(value));

  @override
  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'type': 'dog',
    ..._$DogToJson(this),
  };

  static String _ackFromRuntimeBreed(Object? value) => value as String;

  static Object? _ackToRuntimeBreed(String value) => value;
}

/// Creates copies of [Dog] with selected fields replaced.
abstract interface class $DogCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? breed});
}

final class _$DogCopyWith implements $DogCopyWith<Dog> {
  const _$DogCopyWith(this._source);

  final Dog _source;

  @override
  Dog call({String? breed}) => Dog(breed: breed ?? _source.breed);
}
