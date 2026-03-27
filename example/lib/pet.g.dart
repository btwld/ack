// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'pet.dart';

/// Extension type for Pet
extension type PetType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  String get type => _data['type'] as String;

  static PetType parse(Object? data) {
    return petSchema.parseAs(data, (validated) {
      final map = validated as Map<String, Object?>;
      return switch (map['type']) {
        'cat' => CatType(map),
        'dog' => DogType(map),
        _ => throw StateError('Unknown type: ${map['type']}'),
      };
    });
  }

  static SchemaResult<PetType> safeParse(Object? data) {
    return petSchema.safeParseAs(data, (validated) {
      final map = validated as Map<String, Object?>;
      return switch (map['type']) {
        'cat' => CatType(map),
        'dog' => DogType(map),
        _ => throw StateError('Unknown type: ${map['type']}'),
      };
    });
  }
}

/// Extension type for Cat
extension type CatType(Map<String, Object?> _data)
    implements PetType, Map<String, Object?> {
  String get type => _data['type'] as String;

  static CatType parse(Object? data) {
    return catSchema.parseAs(
      data,
      (validated) => CatType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<CatType> safeParse(Object? data) {
    return catSchema.safeParseAs(
      data,
      (validated) => CatType(validated as Map<String, Object?>),
    );
  }

  int get lives => _data['lives'] as int;
}

/// Extension type for Dog
extension type DogType(Map<String, Object?> _data)
    implements PetType, Map<String, Object?> {
  String get type => _data['type'] as String;

  static DogType parse(Object? data) {
    return dogSchema.parseAs(
      data,
      (validated) => DogType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DogType> safeParse(Object? data) {
    return dogSchema.safeParseAs(
      data,
      (validated) => DogType(validated as Map<String, Object?>),
    );
  }

  String get breed => _data['breed'] as String;
}
