// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_extension_types.dart';

/// Generated schema for SimpleUser
final simpleUserSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
  'email': Ack.string().optional().nullable(),
});

/// Generated schema for Address
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
  'country': Ack.string(),
});

/// Generated schema for UserWithAddress
final userWithAddressSchema = Ack.object({
  'name': Ack.string(),
  'address': addressSchema,
  'billingAddress': addressSchema.optional().nullable(),
});

/// Generated schema for BlogPost
final blogPostSchema = Ack.object({
  'title': Ack.string(),
  'content': Ack.string(),
  'tags': Ack.list(Ack.string()),
  'locations': Ack.list(addressSchema),
});

/// Extension type for SimpleUser
extension type SimpleUserType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static SimpleUserType parse(Object? data) {
    final validated = simpleUserSchema.parse(data);
    return SimpleUserType(validated as Map<String, Object?>);
  }

  static SchemaResult<SimpleUserType> safeParse(Object? data) {
    final result = simpleUserSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(SimpleUserType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  int get age => _data['age'] as int;

  String? get email => _data['email'] as String?;

  Map<String, Object?> toJson() => _data;

  SimpleUserType copyWith({String? name, int? age, String? email}) {
    return SimpleUserType.parse({
      'name': name ?? this.name,
      'age': age ?? this.age,
      if (email != null || _data.containsKey('email'))
        'email': email ?? this.email,
    });
  }
}

/// Extension type for Address
extension type AddressType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AddressType parse(Object? data) {
    final validated = addressSchema.parse(data);
    return AddressType(validated as Map<String, Object?>);
  }

  static SchemaResult<AddressType> safeParse(Object? data) {
    final result = addressSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(AddressType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get street => _data['street'] as String;

  String get city => _data['city'] as String;

  String get country => _data['country'] as String;

  Map<String, Object?> toJson() => _data;

  AddressType copyWith({String? street, String? city, String? country}) {
    return AddressType.parse({
      'street': street ?? this.street,
      'city': city ?? this.city,
      'country': country ?? this.country,
    });
  }
}

/// Extension type for UserWithAddress
extension type UserWithAddressType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UserWithAddressType parse(Object? data) {
    final validated = userWithAddressSchema.parse(data);
    return UserWithAddressType(validated as Map<String, Object?>);
  }

  static SchemaResult<UserWithAddressType> safeParse(Object? data) {
    final result = userWithAddressSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(
        UserWithAddressType(validated as Map<String, Object?>),
      ),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  AddressType get address =>
      AddressType(_data['address'] as Map<String, Object?>);

  AddressType? get billingAddress => _data['billingAddress'] != null
      ? AddressType(_data['billingAddress'] as Map<String, Object?>)
      : null;

  Map<String, Object?> toJson() => _data;

  UserWithAddressType copyWith({
    String? name,
    Address? address,
    Address? billingAddress,
  }) {
    return UserWithAddressType.parse({
      'name': name ?? this.name,
      'address': address ?? this.address,
      if (billingAddress != null || _data.containsKey('billingAddress'))
        'billingAddress': billingAddress ?? this.billingAddress,
    });
  }
}

/// Extension type for BlogPost
extension type BlogPostType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static BlogPostType parse(Object? data) {
    final validated = blogPostSchema.parse(data);
    return BlogPostType(validated as Map<String, Object?>);
  }

  static SchemaResult<BlogPostType> safeParse(Object? data) {
    final result = blogPostSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(BlogPostType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get title => _data['title'] as String;

  String get content => _data['content'] as String;

  List<String> get tags => (_data['tags'] as List).cast<String>();

  Iterable<AddressType> get locations => (_data['locations'] as List).map(
    (e) => AddressType(e as Map<String, Object?>),
  );

  Map<String, Object?> toJson() => _data;

  BlogPostType copyWith({
    String? title,
    String? content,
    List<String>? tags,
    List<Address>? locations,
  }) {
    return BlogPostType.parse({
      'title': title ?? this.title,
      'content': content ?? this.content,
      'tags': tags ?? this.tags,
      'locations': locations ?? this.locations,
    });
  }
}
