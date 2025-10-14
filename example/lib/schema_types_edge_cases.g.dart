// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_types_edge_cases.dart';

/// Extension type for Product
extension type ProductType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ProductType parse(Object? data) {
    final validated = productSchema.parse(data);
    return ProductType(validated as Map<String, Object?>);
  }

  static SchemaResult<ProductType> safeParse(Object? data) {
    final result = productSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(ProductType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  List<String> get tags => (_data['tags'] as List).cast<String>();

  List<int> get scores => (_data['scores'] as List).cast<int>();

  List<bool> get flags => (_data['flags'] as List).cast<bool>();

  ProductType copyWith({
    String? name,
    List<String>? tags,
    List<int>? scores,
    List<bool>? flags,
  }) {
    return ProductType.parse({
      'name': name ?? this.name,
      'tags': tags ?? this.tags,
      'scores': scores ?? this.scores,
      'flags': flags ?? this.flags,
    });
  }
}

/// Extension type for Grid
extension type GridType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static GridType parse(Object? data) {
    final validated = gridSchema.parse(data);
    return GridType(validated as Map<String, Object?>);
  }

  static SchemaResult<GridType> safeParse(Object? data) {
    final result = gridSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(GridType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  List<List<int>> get matrix => (_data['matrix'] as List).cast<List<int>>();

  GridType copyWith({String? name, List<List<int>>? matrix}) {
    return GridType.parse({
      'name': name ?? this.name,
      'matrix': matrix ?? this.matrix,
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

  String get zipCode => _data['zipCode'] as String;

  String get country => _data['country'] as String;

  AddressType copyWith({
    String? street,
    String? city,
    String? zipCode,
    String? country,
  }) {
    return AddressType.parse({
      'street': street ?? this.street,
      'city': city ?? this.city,
      'zipCode': zipCode ?? this.zipCode,
      'country': country ?? this.country,
    });
  }
}

/// Extension type for Person
extension type PersonType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static PersonType parse(Object? data) {
    final validated = personSchema.parse(data);
    return PersonType(validated as Map<String, Object?>);
  }

  static SchemaResult<PersonType> safeParse(Object? data) {
    final result = personSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(PersonType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  String get email => _data['email'] as String;

  Map<String, Object?> get address => _data['address'] as Map<String, Object?>;

  int get age => _data['age'] as int;

  PersonType copyWith({
    String? name,
    String? email,
    Map<String, dynamic>? address,
    int? age,
  }) {
    return PersonType.parse({
      'name': name ?? this.name,
      'email': email ?? this.email,
      'address': address ?? this.address,
      'age': age ?? this.age,
    });
  }
}

/// Extension type for Employee
extension type EmployeeType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static EmployeeType parse(Object? data) {
    final validated = employeeSchema.parse(data);
    return EmployeeType(validated as Map<String, Object?>);
  }

  static SchemaResult<EmployeeType> safeParse(Object? data) {
    final result = employeeSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(EmployeeType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  String get employeeId => _data['employeeId'] as String;

  Map<String, Object?> get homeAddress =>
      _data['homeAddress'] as Map<String, Object?>;

  Map<String, Object?> get workAddress =>
      _data['workAddress'] as Map<String, Object?>;

  EmployeeType copyWith({
    String? name,
    String? employeeId,
    Map<String, dynamic>? homeAddress,
    Map<String, dynamic>? workAddress,
  }) {
    return EmployeeType.parse({
      'name': name ?? this.name,
      'employeeId': employeeId ?? this.employeeId,
      'homeAddress': homeAddress ?? this.homeAddress,
      'workAddress': workAddress ?? this.workAddress,
    });
  }
}

/// Extension type for Modifier
extension type ModifierType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ModifierType parse(Object? data) {
    final validated = modifierSchema.parse(data);
    return ModifierType(validated as Map<String, Object?>);
  }

  static SchemaResult<ModifierType> safeParse(Object? data) {
    final result = modifierSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(ModifierType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get requiredField => _data['requiredField'] as String;

  String get optionalField => _data['optionalField'] as String;

  String? get nullableField => _data['nullableField'] as String?;

  String? get optionalNullable => _data['optionalNullable'] as String?;

  String? get nullableOptional => _data['nullableOptional'] as String?;

  ModifierType copyWith({
    String? requiredField,
    String? optionalField,
    String? nullableField,
    String? optionalNullable,
    String? nullableOptional,
  }) {
    return ModifierType.parse({
      'requiredField': requiredField ?? this.requiredField,
      'optionalField': optionalField ?? this.optionalField,
      if (nullableField != null || _data.containsKey('nullableField'))
        'nullableField': nullableField ?? this.nullableField,
      if (optionalNullable != null || _data.containsKey('optionalNullable'))
        'optionalNullable': optionalNullable ?? this.optionalNullable,
      if (nullableOptional != null || _data.containsKey('nullableOptional'))
        'nullableOptional': nullableOptional ?? this.nullableOptional,
    });
  }
}

/// Extension type for TaggedItem
extension type TaggedItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static TaggedItemType parse(Object? data) {
    final validated = taggedItemSchema.parse(data);
    return TaggedItemType(validated as Map<String, Object?>);
  }

  static SchemaResult<TaggedItemType> safeParse(Object? data) {
    final result = taggedItemSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(TaggedItemType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  List<String> get requiredTags =>
      (_data['requiredTags'] as List).cast<String>();

  List<String> get optionalTags =>
      (_data['optionalTags'] as List).cast<String>();

  List<String>? get nullableTags => _data['nullableTags'] != null
      ? (_data['nullableTags'] as List).cast<String>()
      : null;

  TaggedItemType copyWith({
    String? name,
    List<String>? requiredTags,
    List<String>? optionalTags,
    List<String>? nullableTags,
  }) {
    return TaggedItemType.parse({
      'name': name ?? this.name,
      'requiredTags': requiredTags ?? this.requiredTags,
      'optionalTags': optionalTags ?? this.optionalTags,
      if (nullableTags != null || _data.containsKey('nullableTags'))
        'nullableTags': nullableTags ?? this.nullableTags,
    });
  }
}

/// Extension type for ContactList
extension type ContactListType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ContactListType parse(Object? data) {
    final validated = contactListSchema.parse(data);
    return ContactListType(validated as Map<String, Object?>);
  }

  static SchemaResult<ContactListType> safeParse(Object? data) {
    final result = contactListSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(ContactListType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  ContactListType copyWith({String? name}) {
    return ContactListType.parse({'name': name ?? this.name});
  }
}

/// Extension type for Empty
extension type EmptyType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static EmptyType parse(Object? data) {
    final validated = emptySchema.parse(data);
    return EmptyType(validated as Map<String, Object?>);
  }

  static SchemaResult<EmptyType> safeParse(Object? data) {
    final result = emptySchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(EmptyType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }
}

/// Extension type for Minimal
extension type MinimalType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static MinimalType parse(Object? data) {
    final validated = minimalSchema.parse(data);
    return MinimalType(validated as Map<String, Object?>);
  }

  static SchemaResult<MinimalType> safeParse(Object? data) {
    final result = minimalSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(MinimalType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get id => _data['id'] as String;

  MinimalType copyWith({String? id}) {
    return MinimalType.parse({'id': id ?? this.id});
  }
}

/// Extension type for NamedItem
extension type NamedItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static NamedItemType parse(Object? data) {
    final validated = namedItemSchema.parse(data);
    return NamedItemType(validated as Map<String, Object?>);
  }

  static SchemaResult<NamedItemType> safeParse(Object? data) {
    final result = namedItemSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(NamedItemType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get name => _data['name'] as String;

  NamedItemType copyWith({String? name}) {
    return NamedItemType.parse({'name': name ?? this.name});
  }
}

/// Extension type for Item
extension type ItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ItemType parse(Object? data) {
    final validated = item.parse(data);
    return ItemType(validated as Map<String, Object?>);
  }

  static SchemaResult<ItemType> safeParse(Object? data) {
    final result = item.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(ItemType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get id => _data['id'] as String;

  ItemType copyWith({String? id}) {
    return ItemType.parse({'id': id ?? this.id});
  }
}

/// Extension type for MyCustomSchema123
extension type MyCustomSchema123Type(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static MyCustomSchema123Type parse(Object? data) {
    final validated = myCustomSchema123.parse(data);
    return MyCustomSchema123Type(validated as Map<String, Object?>);
  }

  static SchemaResult<MyCustomSchema123Type> safeParse(Object? data) {
    final result = myCustomSchema123.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(
        MyCustomSchema123Type(validated as Map<String, Object?>),
      ),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String get value => _data['value'] as String;

  MyCustomSchema123Type copyWith({String? value}) {
    return MyCustomSchema123Type.parse({'value': value ?? this.value});
  }
}
