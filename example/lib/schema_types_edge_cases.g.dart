// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_types_edge_cases.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

/// Immutable model generated from `productSchema`.
final class Product {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Product({
    required this.name,
    required List<String> tags,
    required List<int> scores,
    required List<bool> flags,
  }) : tags = List<String>.unmodifiable(tags.map((item) => item)),
       scores = List<int>.unmodifiable(scores.map((item) => item)),
       flags = List<bool>.unmodifiable(flags.map((item) => item));

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Product.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Product.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  final List<String> tags;

  final List<int> scores;

  final List<bool> flags;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => productSchema,
    fromRuntime: Product._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Product] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Product> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ProductCopyWith<Product> get copyWith => _$ProductCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(tags, other.tags) &&
          deepEquals(scores, other.scores) &&
          deepEquals(flags, other.flags));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(name),
    deepHashCode(tags),
    deepHashCode(scores),
    deepHashCode(flags),
  ]);

  @override
  String toString() =>
      'Product(name: $name, tags: $tags, scores: $scores, flags: $flags)';

  static Product _fromAckRuntime(Map<String, Object?> value) => Product(
    name: value['name'] as String,
    tags: (value['tags'] as List).map((item) => item as String).toList(),
    scores: (value['scores'] as List).map((item) => item as int).toList(),
    flags: (value['flags'] as List).map((item) => item as bool).toList(),
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'name': name,
    'tags': tags.map((item) => item).toList(growable: false),
    'scores': scores.map((item) => item).toList(growable: false),
    'flags': flags.map((item) => item).toList(growable: false),
  };
}

/// Creates copies of [Product] with selected fields replaced.
abstract interface class $ProductCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? name,
    List<String>? tags,
    List<int>? scores,
    List<bool>? flags,
  });
}

final class _$ProductCopyWith implements $ProductCopyWith<Product> {
  const _$ProductCopyWith(this._source);

  final Product _source;

  @override
  Product call({
    String? name,
    List<String>? tags,
    List<int>? scores,
    List<bool>? flags,
  }) => Product(
    name: name ?? _source.name,
    tags: tags ?? _source.tags,
    scores: scores ?? _source.scores,
    flags: flags ?? _source.flags,
  );
}

/// Immutable model generated from `gridSchema`.
final class Grid {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Grid({required this.name, required List<List<int>> matrix})
    : matrix = List<List<int>>.unmodifiable(
        matrix.map((item) => List<int>.unmodifiable(item.map((item) => item))),
      );

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Grid.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Grid.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  final List<List<int>> matrix;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => gridSchema,
    fromRuntime: Grid._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Grid] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Grid> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $GridCopyWith<Grid> get copyWith => _$GridCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grid &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(matrix, other.matrix));

  @override
  int get hashCode =>
      Object.hashAll([runtimeType, deepHashCode(name), deepHashCode(matrix)]);

  @override
  String toString() => 'Grid(name: $name, matrix: $matrix)';

  static Grid _fromAckRuntime(Map<String, Object?> value) => Grid(
    name: value['name'] as String,
    matrix: (value['matrix'] as List)
        .map((item) => (item as List).map((item) => item as int).toList())
        .toList(),
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'name': name,
    'matrix': matrix
        .map((item) => item.map((item) => item).toList(growable: false))
        .toList(growable: false),
  };
}

/// Creates copies of [Grid] with selected fields replaced.
abstract interface class $GridCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? name, List<List<int>>? matrix});
}

final class _$GridCopyWith implements $GridCopyWith<Grid> {
  const _$GridCopyWith(this._source);

  final Grid _source;

  @override
  Grid call({String? name, List<List<int>>? matrix}) =>
      Grid(name: name ?? _source.name, matrix: matrix ?? _source.matrix);
}

/// Immutable model generated from `addressSchema`.
final class Address {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Address({
    required this.street,
    required this.city,
    required this.zipCode,
    required this.country,
  });

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Address.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Address.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String street;

  final String city;

  final String zipCode;

  final String country;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => addressSchema,
    fromRuntime: Address._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Address] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Address> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $AddressCopyWith<Address> get copyWith => _$AddressCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Address &&
          runtimeType == other.runtimeType &&
          deepEquals(street, other.street) &&
          deepEquals(city, other.city) &&
          deepEquals(zipCode, other.zipCode) &&
          deepEquals(country, other.country));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(street),
    deepHashCode(city),
    deepHashCode(zipCode),
    deepHashCode(country),
  ]);

  @override
  String toString() =>
      'Address(street: $street, city: $city, zipCode: $zipCode, country: $country)';

  static Address _fromAckRuntime(Map<String, Object?> value) => Address(
    street: value['street'] as String,
    city: value['city'] as String,
    zipCode: value['zipCode'] as String,
    country: value['country'] as String,
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'street': street,
    'city': city,
    'zipCode': zipCode,
    'country': country,
  };
}

/// Creates copies of [Address] with selected fields replaced.
abstract interface class $AddressCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? street,
    String? city,
    String? zipCode,
    String? country,
  });
}

final class _$AddressCopyWith implements $AddressCopyWith<Address> {
  const _$AddressCopyWith(this._source);

  final Address _source;

  @override
  Address call({
    String? street,
    String? city,
    String? zipCode,
    String? country,
  }) => Address(
    street: street ?? _source.street,
    city: city ?? _source.city,
    zipCode: zipCode ?? _source.zipCode,
    country: country ?? _source.country,
  );
}

/// Immutable model generated from `personSchema`.
final class Person {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Person({
    required this.name,
    required this.email,
    required this.address,
    required this.age,
  });

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Person.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Person.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  final String email;

  final Address address;

  final int age;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => personSchema,
    fromRuntime: Person._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Person] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Person> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $PersonCopyWith<Person> get copyWith => _$PersonCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(email, other.email) &&
          deepEquals(address, other.address) &&
          deepEquals(age, other.age));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(name),
    deepHashCode(email),
    deepHashCode(address),
    deepHashCode(age),
  ]);

  @override
  String toString() =>
      'Person(name: $name, email: $email, address: $address, age: $age)';

  static Person _fromAckRuntime(Map<String, Object?> value) => Person(
    name: value['name'] as String,
    email: value['email'] as String,
    address: Address.$ack.fromRuntime(value['address'] as Map<String, Object?>),
    age: value['age'] as int,
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'name': name,
    'email': email,
    'address': Address.$ack.toRuntime(address),
    'age': age,
  };
}

/// Creates copies of [Person] with selected fields replaced.
abstract interface class $PersonCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? name, String? email, Address? address, int? age});
}

final class _$PersonCopyWith implements $PersonCopyWith<Person> {
  const _$PersonCopyWith(this._source);

  final Person _source;

  @override
  Person call({String? name, String? email, Address? address, int? age}) =>
      Person(
        name: name ?? _source.name,
        email: email ?? _source.email,
        address: address ?? _source.address,
        age: age ?? _source.age,
      );
}

/// Immutable model generated from `employeeSchema`.
final class Employee {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Employee({
    required this.name,
    required this.employeeId,
    required this.homeAddress,
    required this.workAddress,
  });

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Employee.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Employee.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  final String employeeId;

  final Address homeAddress;

  final Address workAddress;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => employeeSchema,
    fromRuntime: Employee._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Employee] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Employee> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $EmployeeCopyWith<Employee> get copyWith => _$EmployeeCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employee &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(employeeId, other.employeeId) &&
          deepEquals(homeAddress, other.homeAddress) &&
          deepEquals(workAddress, other.workAddress));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(name),
    deepHashCode(employeeId),
    deepHashCode(homeAddress),
    deepHashCode(workAddress),
  ]);

  @override
  String toString() =>
      'Employee(name: $name, employeeId: $employeeId, homeAddress: $homeAddress, workAddress: $workAddress)';

  static Employee _fromAckRuntime(Map<String, Object?> value) => Employee(
    name: value['name'] as String,
    employeeId: value['employeeId'] as String,
    homeAddress: Address.$ack.fromRuntime(
      value['homeAddress'] as Map<String, Object?>,
    ),
    workAddress: Address.$ack.fromRuntime(
      value['workAddress'] as Map<String, Object?>,
    ),
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'name': name,
    'employeeId': employeeId,
    'homeAddress': Address.$ack.toRuntime(homeAddress),
    'workAddress': Address.$ack.toRuntime(workAddress),
  };
}

/// Creates copies of [Employee] with selected fields replaced.
abstract interface class $EmployeeCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? name,
    String? employeeId,
    Address? homeAddress,
    Address? workAddress,
  });
}

final class _$EmployeeCopyWith implements $EmployeeCopyWith<Employee> {
  const _$EmployeeCopyWith(this._source);

  final Employee _source;

  @override
  Employee call({
    String? name,
    String? employeeId,
    Address? homeAddress,
    Address? workAddress,
  }) => Employee(
    name: name ?? _source.name,
    employeeId: employeeId ?? _source.employeeId,
    homeAddress: homeAddress ?? _source.homeAddress,
    workAddress: workAddress ?? _source.workAddress,
  );
}

/// Immutable model generated from `modifierSchema`.
final class Modifier {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Modifier({
    required this.requiredField,
    this.optionalField,
    required this.nullableField,
    this.optionalNullable,
    this.nullableOptional,
  });

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Modifier.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Modifier.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String requiredField;

  final String? optionalField;

  final String? nullableField;

  final String? optionalNullable;

  final String? nullableOptional;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => modifierSchema,
    fromRuntime: Modifier._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Modifier] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Modifier> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ModifierCopyWith<Modifier> get copyWith => _$ModifierCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Modifier &&
          runtimeType == other.runtimeType &&
          deepEquals(requiredField, other.requiredField) &&
          deepEquals(optionalField, other.optionalField) &&
          deepEquals(nullableField, other.nullableField) &&
          deepEquals(optionalNullable, other.optionalNullable) &&
          deepEquals(nullableOptional, other.nullableOptional));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(requiredField),
    deepHashCode(optionalField),
    deepHashCode(nullableField),
    deepHashCode(optionalNullable),
    deepHashCode(nullableOptional),
  ]);

  @override
  String toString() =>
      'Modifier(requiredField: $requiredField, optionalField: $optionalField, nullableField: $nullableField, optionalNullable: $optionalNullable, nullableOptional: $nullableOptional)';

  static Modifier _fromAckRuntime(Map<String, Object?> value) => Modifier(
    requiredField: value['requiredField'] as String,
    optionalField: value['optionalField'] as String?,
    nullableField: value['nullableField'] as String?,
    optionalNullable: value['optionalNullable'] as String?,
    nullableOptional: value['nullableOptional'] as String?,
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'requiredField': requiredField,
    'optionalField': ?optionalField,
    'nullableField': nullableField,
    'optionalNullable': ?optionalNullable,
    'nullableOptional': ?nullableOptional,
  };
}

final class _ModifierCopyWithUnset {
  const _ModifierCopyWithUnset();
}

/// Creates copies of [Modifier] with selected fields replaced.
abstract interface class $ModifierCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? requiredField,
    String? optionalField,
    String? nullableField,
    String? optionalNullable,
    String? nullableOptional,
  });
}

final class _$ModifierCopyWith implements $ModifierCopyWith<Modifier> {
  const _$ModifierCopyWith(this._source);

  static const _ModifierCopyWithUnset _ackCopyWithUnset =
      _ModifierCopyWithUnset();

  final Modifier _source;

  @override
  Modifier call({
    String? requiredField,
    Object? optionalField = _ackCopyWithUnset,
    Object? nullableField = _ackCopyWithUnset,
    Object? optionalNullable = _ackCopyWithUnset,
    Object? nullableOptional = _ackCopyWithUnset,
  }) => Modifier(
    requiredField: requiredField ?? _source.requiredField,
    optionalField: identical(optionalField, _ackCopyWithUnset)
        ? _source.optionalField
        : optionalField as String?,
    nullableField: identical(nullableField, _ackCopyWithUnset)
        ? _source.nullableField
        : nullableField as String?,
    optionalNullable: identical(optionalNullable, _ackCopyWithUnset)
        ? _source.optionalNullable
        : optionalNullable as String?,
    nullableOptional: identical(nullableOptional, _ackCopyWithUnset)
        ? _source.nullableOptional
        : nullableOptional as String?,
  );
}

/// Immutable model generated from `taggedItemSchema`.
final class TaggedItem {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  TaggedItem({
    required this.name,
    required List<String> requiredTags,
    List<String>? optionalTags,
    required List<String>? nullableTags,
  }) : requiredTags = List<String>.unmodifiable(
         requiredTags.map((item) => item),
       ),
       optionalTags = switch (optionalTags) {
         null => null,
         final fieldValue => List<String>.unmodifiable(
           fieldValue.map((item) => item),
         ),
       },
       nullableTags = switch (nullableTags) {
         null => null,
         final fieldValue => List<String>.unmodifiable(
           fieldValue.map((item) => item),
         ),
       };

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory TaggedItem.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory TaggedItem.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  final List<String> requiredTags;

  final List<String>? optionalTags;

  final List<String>? nullableTags;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => taggedItemSchema,
    fromRuntime: TaggedItem._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [TaggedItem] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<TaggedItem> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $TaggedItemCopyWith<TaggedItem> get copyWith => _$TaggedItemCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaggedItem &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(requiredTags, other.requiredTags) &&
          deepEquals(optionalTags, other.optionalTags) &&
          deepEquals(nullableTags, other.nullableTags));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(name),
    deepHashCode(requiredTags),
    deepHashCode(optionalTags),
    deepHashCode(nullableTags),
  ]);

  @override
  String toString() =>
      'TaggedItem(name: $name, requiredTags: $requiredTags, optionalTags: $optionalTags, nullableTags: $nullableTags)';

  static TaggedItem _fromAckRuntime(Map<String, Object?> value) => TaggedItem(
    name: value['name'] as String,
    requiredTags: (value['requiredTags'] as List)
        .map((item) => item as String)
        .toList(),
    optionalTags: switch (value['optionalTags']) {
      null => null,
      final fieldValue =>
        (fieldValue as List).map((item) => item as String).toList(),
    },
    nullableTags: switch (value['nullableTags']) {
      null => null,
      final fieldValue =>
        (fieldValue as List).map((item) => item as String).toList(),
    },
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'name': name,
    'requiredTags': requiredTags.map((item) => item).toList(growable: false),
    'optionalTags': ?optionalTags?.map((item) => item).toList(growable: false),
    'nullableTags': nullableTags?.map((item) => item).toList(growable: false),
  };
}

final class _TaggedItemCopyWithUnset {
  const _TaggedItemCopyWithUnset();
}

/// Creates copies of [TaggedItem] with selected fields replaced.
abstract interface class $TaggedItemCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? name,
    List<String>? requiredTags,
    List<String>? optionalTags,
    List<String>? nullableTags,
  });
}

final class _$TaggedItemCopyWith implements $TaggedItemCopyWith<TaggedItem> {
  const _$TaggedItemCopyWith(this._source);

  static const _TaggedItemCopyWithUnset _ackCopyWithUnset =
      _TaggedItemCopyWithUnset();

  final TaggedItem _source;

  @override
  TaggedItem call({
    String? name,
    List<String>? requiredTags,
    Object? optionalTags = _ackCopyWithUnset,
    Object? nullableTags = _ackCopyWithUnset,
  }) => TaggedItem(
    name: name ?? _source.name,
    requiredTags: requiredTags ?? _source.requiredTags,
    optionalTags: identical(optionalTags, _ackCopyWithUnset)
        ? _source.optionalTags
        : optionalTags as List<String>?,
    nullableTags: identical(nullableTags, _ackCopyWithUnset)
        ? _source.nullableTags
        : nullableTags as List<String>?,
  );
}

/// Immutable model generated from `contactListSchema`.
final class ContactList {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  ContactList({required this.name, required List<Address> addresses})
    : addresses = List<Address>.unmodifiable(addresses.map((item) => item));

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ContactList.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ContactList.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  final List<Address> addresses;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => contactListSchema,
    fromRuntime: ContactList._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [ContactList] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<ContactList> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ContactListCopyWith<ContactList> get copyWith => _$ContactListCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactList &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(addresses, other.addresses));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(name),
    deepHashCode(addresses),
  ]);

  @override
  String toString() => 'ContactList(name: $name, addresses: $addresses)';

  static ContactList _fromAckRuntime(Map<String, Object?> value) => ContactList(
    name: value['name'] as String,
    addresses: (value['addresses'] as List)
        .map((item) => Address.$ack.fromRuntime(item as Map<String, Object?>))
        .toList(),
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'name': name,
    'addresses': addresses
        .map((item) => Address.$ack.toRuntime(item))
        .toList(growable: false),
  };
}

/// Creates copies of [ContactList] with selected fields replaced.
abstract interface class $ContactListCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? name, List<Address>? addresses});
}

final class _$ContactListCopyWith implements $ContactListCopyWith<ContactList> {
  const _$ContactListCopyWith(this._source);

  final ContactList _source;

  @override
  ContactList call({String? name, List<Address>? addresses}) => ContactList(
    name: name ?? _source.name,
    addresses: addresses ?? _source.addresses,
  );
}

/// Immutable model generated from `emptySchema`.
final class Empty {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Empty();

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Empty.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Empty.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => emptySchema,
    fromRuntime: Empty._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Empty] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Empty> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $EmptyCopyWith<Empty> get copyWith => const _$EmptyCopyWith();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Empty && runtimeType == other.runtimeType);

  @override
  int get hashCode => Object.hashAll([runtimeType]);

  @override
  String toString() => 'Empty()';

  static Empty _fromAckRuntime(Map<String, Object?> value) => Empty();

  Map<String, Object?> _toAckRuntime() => <String, Object?>{};
}

/// Creates copies of [Empty] with selected fields replaced.
abstract interface class $EmptyCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call();
}

final class _$EmptyCopyWith implements $EmptyCopyWith<Empty> {
  const _$EmptyCopyWith();

  @override
  Empty call() => Empty();
}

/// Immutable model generated from `minimalSchema`.
final class Minimal {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Minimal({required this.id});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Minimal.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Minimal.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String id;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => minimalSchema,
    fromRuntime: Minimal._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Minimal] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Minimal> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $MinimalCopyWith<Minimal> get copyWith => _$MinimalCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Minimal &&
          runtimeType == other.runtimeType &&
          deepEquals(id, other.id));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(id)]);

  @override
  String toString() => 'Minimal(id: $id)';

  static Minimal _fromAckRuntime(Map<String, Object?> value) =>
      Minimal(id: value['id'] as String);

  Map<String, Object?> _toAckRuntime() => <String, Object?>{'id': id};
}

/// Creates copies of [Minimal] with selected fields replaced.
abstract interface class $MinimalCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? id});
}

final class _$MinimalCopyWith implements $MinimalCopyWith<Minimal> {
  const _$MinimalCopyWith(this._source);

  final Minimal _source;

  @override
  Minimal call({String? id}) => Minimal(id: id ?? _source.id);
}

/// Immutable model generated from `namedItemSchema`.
final class NamedItem {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  NamedItem({required this.name});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory NamedItem.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory NamedItem.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => namedItemSchema,
    fromRuntime: NamedItem._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [NamedItem] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<NamedItem> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $NamedItemCopyWith<NamedItem> get copyWith => _$NamedItemCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NamedItem &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(name)]);

  @override
  String toString() => 'NamedItem(name: $name)';

  static NamedItem _fromAckRuntime(Map<String, Object?> value) =>
      NamedItem(name: value['name'] as String);

  Map<String, Object?> _toAckRuntime() => <String, Object?>{'name': name};
}

/// Creates copies of [NamedItem] with selected fields replaced.
abstract interface class $NamedItemCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? name});
}

final class _$NamedItemCopyWith implements $NamedItemCopyWith<NamedItem> {
  const _$NamedItemCopyWith(this._source);

  final NamedItem _source;

  @override
  NamedItem call({String? name}) => NamedItem(name: name ?? _source.name);
}

/// Immutable model generated from `item`.
final class Item {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Item({required this.id});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Item.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Item.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String id;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => item,
    fromRuntime: Item._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Item] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Item> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ItemCopyWith<Item> get copyWith => _$ItemCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          runtimeType == other.runtimeType &&
          deepEquals(id, other.id));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(id)]);

  @override
  String toString() => 'Item(id: $id)';

  static Item _fromAckRuntime(Map<String, Object?> value) =>
      Item(id: value['id'] as String);

  Map<String, Object?> _toAckRuntime() => <String, Object?>{'id': id};
}

/// Creates copies of [Item] with selected fields replaced.
abstract interface class $ItemCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? id});
}

final class _$ItemCopyWith implements $ItemCopyWith<Item> {
  const _$ItemCopyWith(this._source);

  final Item _source;

  @override
  Item call({String? id}) => Item(id: id ?? _source.id);
}

/// Immutable model generated from `myCustomSchema123`.
final class MyCustomSchema123 {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  MyCustomSchema123({required this.value});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory MyCustomSchema123.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory MyCustomSchema123.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => myCustomSchema123,
    fromRuntime: MyCustomSchema123._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [MyCustomSchema123] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<MyCustomSchema123> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $MyCustomSchema123CopyWith<MyCustomSchema123> get copyWith =>
      _$MyCustomSchema123CopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyCustomSchema123 &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'MyCustomSchema123(value: $value)';

  static MyCustomSchema123 _fromAckRuntime(Map<String, Object?> value) =>
      MyCustomSchema123(value: value['value'] as String);

  Map<String, Object?> _toAckRuntime() => <String, Object?>{'value': value};
}

/// Creates copies of [MyCustomSchema123] with selected fields replaced.
abstract interface class $MyCustomSchema123CopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? value});
}

final class _$MyCustomSchema123CopyWith
    implements $MyCustomSchema123CopyWith<MyCustomSchema123> {
  const _$MyCustomSchema123CopyWith(this._source);

  final MyCustomSchema123 _source;

  @override
  MyCustomSchema123 call({String? value}) =>
      MyCustomSchema123(value: value ?? _source.value);
}
