// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_discriminated.dart';

/// Extension type for Pet
extension type PetType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  String get kind => _data['kind'] as String;

  Map<String, Object?> toJson() => _data;

  static PetType parse(Object? data) {
    return petSchema.parseRepresentationAs(data, (representation) {
      final map = representation as Map<String, Object?>;
      return switch (map['kind']) {
        'cat' => CatType(map),
        'dog' => DogType(map),
        _ => throw StateError('Unknown kind: ${map['kind']}'),
      };
    });
  }

  static SchemaResult<PetType> safeParse(Object? data) {
    return petSchema.safeParseRepresentationAs(data, (representation) {
      final map = representation as Map<String, Object?>;
      return switch (map['kind']) {
        'cat' => CatType(map),
        'dog' => DogType(map),
        _ => throw StateError('Unknown kind: ${map['kind']}'),
      };
    });
  }
}

/// Extension type for Cat
extension type CatType(Map<String, Object?> _data)
    implements PetType, Map<String, Object?> {
  String get kind => _data['kind'] as String;

  Map<String, Object?> toJson() => _data;

  static CatType parse(Object? data) {
    return catSchema.parseRepresentationAs(
      data,
      (representation) => CatType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<CatType> safeParse(Object? data) {
    return catSchema.safeParseRepresentationAs(
      data,
      (representation) => CatType(representation as Map<String, Object?>),
    );
  }

  int get lives => _data['lives'] as int;

  CatType copyWith({int? lives}) {
    return CatType.parse({'kind': 'cat', 'lives': lives ?? _data['lives']});
  }
}

/// Extension type for Dog
extension type DogType(Map<String, Object?> _data)
    implements PetType, Map<String, Object?> {
  String get kind => _data['kind'] as String;

  Map<String, Object?> toJson() => _data;

  static DogType parse(Object? data) {
    return dogSchema.parseRepresentationAs(
      data,
      (representation) => DogType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<DogType> safeParse(Object? data) {
    return dogSchema.safeParseRepresentationAs(
      data,
      (representation) => DogType(representation as Map<String, Object?>),
    );
  }

  bool get bark => _data['bark'] as bool;

  Map<String, Object?> get args => Map.fromEntries(
    _data.entries.where((e) => e.key != 'kind' && e.key != 'bark'),
  );

  DogType copyWith({bool? bark}) {
    return DogType.parse({'kind': 'dog', 'bark': bark ?? _data['bark']});
  }
}
