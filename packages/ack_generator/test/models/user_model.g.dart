// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'user_model.dart';

/// Generated schema for User
/// A user model with validation
class UserSchema extends SchemaModel<User> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'email': Ack.string.isEmail(),
        'name': Ack.string.isNotEmpty(),
        'age': Ack.int.nullable(),
        'password': Ack.string.minLength(8).nullable(),
        'address': AddressSchema.schema,
      },
      required: ['email', 'name', 'password', 'address'],
      additionalProperties: true,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<User, UserSchema>(
      (data) => UserSchema(data),
    );
    // Register schema dependencies
    AddressSchema.ensureInitialize();
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  UserSchema([Object? value]) : super(value);

  // Type-safe getters
  String get email => getValue<String>('email')!;
  String get name => getValue<String>('name')!;
  int? get age => getValue<int>('age');
  String? get password => getValue<String>('password');
  AddressSchema get address {
    return AddressSchema(getValue<Map<String, dynamic>>('address')!);
  }

  // Get metadata with fallback
  Map<String, Object?> get metadata {
    final result = <String, Object?>{};
    final knownFields = ['email', 'name', 'age', 'password', 'address'];

    for (final key in toMap().keys) {
      if (!knownFields.contains(key)) {
        result[key] = toMap()[key];
      }
    }
    return result;
  }

  // Model conversion methods
  @override
  User toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return User(
      email: email,
      name: name,
      age: age,
      password: password,
      address: address.toModel(),
      metadata: metadata,
    );
  }

  /// Parses the input and returns a User instance.
  /// Throws an [AckException] if validation fails.
  static User parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return UserSchema(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a User instance.
  /// Returns null if validation fails.
  static User? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk ? UserSchema(result.getOrNull()).toModel() : null;
  }

  /// Create a schema from a model instance
  static UserSchema fromModel(User model) {
    return UserSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(User instance) {
    final Map<String, Object?> result = {
      'email': instance.email,
      'name': instance.name,
      'age': instance.age,
      'password': instance.password,
      'address': AddressSchema.toMapFromModel(instance.address),
    };

    // Include additional properties
    if (instance.metadata.isNotEmpty) {
      result.addAll(instance.metadata);
    }

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for Address
class AddressSchema extends SchemaModel<Address> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'street': Ack.string.isNotEmpty(),
        'city': Ack.string.isNotEmpty(),
        'zip': Ack.string.nullable(),
      },
      required: ['street', 'city'],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<Address, AddressSchema>(
      (data) => AddressSchema(data),
    );
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  AddressSchema([Object? value]) : super(value);

  // Type-safe getters
  String get street => getValue<String>('street')!;
  String get city => getValue<String>('city')!;
  String? get zip => getValue<String>('zip');

  // Model conversion methods
  @override
  Address toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return Address(
      street: street,
      city: city,
      zip: zip,
    );
  }

  /// Parses the input and returns a Address instance.
  /// Throws an [AckException] if validation fails.
  static Address parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return AddressSchema(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a Address instance.
  /// Returns null if validation fails.
  static Address? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk ? AddressSchema(result.getOrNull()).toModel() : null;
  }

  /// Create a schema from a model instance
  static AddressSchema fromModel(Address model) {
    return AddressSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(Address instance) {
    final Map<String, Object?> result = {
      'street': instance.street,
      'city': instance.city,
      'zip': instance.zip,
    };

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

