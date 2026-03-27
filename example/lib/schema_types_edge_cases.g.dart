// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_edge_cases.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for Product
extension type ProductType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ProductType parse(Object? data) {
    return productSchema.parseAs(
      data,
      (validated) => ProductType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ProductType> safeParse(Object? data) {
    return productSchema.safeParseAs(
      data,
      (validated) => ProductType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  List<String> get tags => _$ackListCast<String>(_data['tags']);

  List<int> get scores => _$ackListCast<int>(_data['scores']);

  List<bool> get flags => _$ackListCast<bool>(_data['flags']);
}

/// Extension type for Grid
extension type GridType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static GridType parse(Object? data) {
    return gridSchema.parseAs(
      data,
      (validated) => GridType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<GridType> safeParse(Object? data) {
    return gridSchema.safeParseAs(
      data,
      (validated) => GridType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  List<List<int>> get matrix => _$ackListCast<List<int>>(_data['matrix']);
}

/// Extension type for Address
extension type AddressType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AddressType parse(Object? data) {
    return addressSchema.parseAs(
      data,
      (validated) => AddressType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<AddressType> safeParse(Object? data) {
    return addressSchema.safeParseAs(
      data,
      (validated) => AddressType(validated as Map<String, Object?>),
    );
  }

  String get street => _data['street'] as String;

  String get city => _data['city'] as String;

  String get zipCode => _data['zipCode'] as String;

  String get country => _data['country'] as String;
}

/// Extension type for Person
extension type PersonType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static PersonType parse(Object? data) {
    return personSchema.parseAs(
      data,
      (validated) => PersonType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<PersonType> safeParse(Object? data) {
    return personSchema.safeParseAs(
      data,
      (validated) => PersonType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  String get email => _data['email'] as String;

  AddressType get address =>
      AddressType(_data['address'] as Map<String, Object?>);

  int get age => _data['age'] as int;
}

/// Extension type for Employee
extension type EmployeeType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static EmployeeType parse(Object? data) {
    return employeeSchema.parseAs(
      data,
      (validated) => EmployeeType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<EmployeeType> safeParse(Object? data) {
    return employeeSchema.safeParseAs(
      data,
      (validated) => EmployeeType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  String get employeeId => _data['employeeId'] as String;

  AddressType get homeAddress =>
      AddressType(_data['homeAddress'] as Map<String, Object?>);

  AddressType get workAddress =>
      AddressType(_data['workAddress'] as Map<String, Object?>);
}

/// Extension type for Modifier
extension type ModifierType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ModifierType parse(Object? data) {
    return modifierSchema.parseAs(
      data,
      (validated) => ModifierType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ModifierType> safeParse(Object? data) {
    return modifierSchema.safeParseAs(
      data,
      (validated) => ModifierType(validated as Map<String, Object?>),
    );
  }

  String get requiredField => _data['requiredField'] as String;

  String? get optionalField => _data['optionalField'] as String?;

  String? get nullableField => _data['nullableField'] as String?;

  String? get optionalNullable => _data['optionalNullable'] as String?;

  String? get nullableOptional => _data['nullableOptional'] as String?;
}

/// Extension type for TaggedItem
extension type TaggedItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static TaggedItemType parse(Object? data) {
    return taggedItemSchema.parseAs(
      data,
      (validated) => TaggedItemType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<TaggedItemType> safeParse(Object? data) {
    return taggedItemSchema.safeParseAs(
      data,
      (validated) => TaggedItemType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  List<String> get requiredTags => _$ackListCast<String>(_data['requiredTags']);

  List<String>? get optionalTags => _data['optionalTags'] != null
      ? _$ackListCast<String>(_data['optionalTags'])
      : null;

  List<String>? get nullableTags => _data['nullableTags'] != null
      ? _$ackListCast<String>(_data['nullableTags'])
      : null;
}

/// Extension type for ContactList
extension type ContactListType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ContactListType parse(Object? data) {
    return contactListSchema.parseAs(
      data,
      (validated) => ContactListType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ContactListType> safeParse(Object? data) {
    return contactListSchema.safeParseAs(
      data,
      (validated) => ContactListType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  List<AddressType> get addresses => (_data['addresses'] as List)
      .map((e) => AddressType(e as Map<String, Object?>))
      .toList();
}

/// Extension type for Empty
extension type EmptyType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static EmptyType parse(Object? data) {
    return emptySchema.parseAs(
      data,
      (validated) => EmptyType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<EmptyType> safeParse(Object? data) {
    return emptySchema.safeParseAs(
      data,
      (validated) => EmptyType(validated as Map<String, Object?>),
    );
  }
}

/// Extension type for Minimal
extension type MinimalType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static MinimalType parse(Object? data) {
    return minimalSchema.parseAs(
      data,
      (validated) => MinimalType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<MinimalType> safeParse(Object? data) {
    return minimalSchema.safeParseAs(
      data,
      (validated) => MinimalType(validated as Map<String, Object?>),
    );
  }

  String get id => _data['id'] as String;
}

/// Extension type for NamedItem
extension type NamedItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static NamedItemType parse(Object? data) {
    return namedItemSchema.parseAs(
      data,
      (validated) => NamedItemType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<NamedItemType> safeParse(Object? data) {
    return namedItemSchema.safeParseAs(
      data,
      (validated) => NamedItemType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;
}

/// Extension type for Item
extension type ItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ItemType parse(Object? data) {
    return item.parseAs(
      data,
      (validated) => ItemType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ItemType> safeParse(Object? data) {
    return item.safeParseAs(
      data,
      (validated) => ItemType(validated as Map<String, Object?>),
    );
  }

  String get id => _data['id'] as String;
}

/// Extension type for MyCustomSchema123
extension type MyCustomSchema123Type(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static MyCustomSchema123Type parse(Object? data) {
    return myCustomSchema123.parseAs(
      data,
      (validated) => MyCustomSchema123Type(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<MyCustomSchema123Type> safeParse(Object? data) {
    return myCustomSchema123.safeParseAs(
      data,
      (validated) => MyCustomSchema123Type(validated as Map<String, Object?>),
    );
  }

  String get value => _data['value'] as String;
}
