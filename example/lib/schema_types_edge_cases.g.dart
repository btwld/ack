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
    return productSchema.parseRepresentationAs(
      data,
      (representation) => ProductType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<ProductType> safeParse(Object? data) {
    return productSchema.safeParseRepresentationAs(
      data,
      (representation) => ProductType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  List<String> get tags => _$ackListCast<String>(_data['tags']);

  List<int> get scores => _$ackListCast<int>(_data['scores']);

  List<bool> get flags => _$ackListCast<bool>(_data['flags']);

  ProductType copyWith({
    String? name,
    List<String>? tags,
    List<int>? scores,
    List<bool>? flags,
  }) {
    return ProductType.parse({
      'name': name ?? _data['name'],
      'tags': tags ?? _data['tags'],
      'scores': scores ?? _data['scores'],
      'flags': flags ?? _data['flags'],
    });
  }
}

/// Extension type for Grid
extension type GridType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static GridType parse(Object? data) {
    return gridSchema.parseRepresentationAs(
      data,
      (representation) => GridType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<GridType> safeParse(Object? data) {
    return gridSchema.safeParseRepresentationAs(
      data,
      (representation) => GridType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  List<List<int>> get matrix =>
      (_data['matrix'] as List).map((e) => _$ackListCast<int>(e)).toList();

  GridType copyWith({String? name, List<List<int>>? matrix}) {
    return GridType.parse({
      'name': name ?? _data['name'],
      'matrix': matrix ?? _data['matrix'],
    });
  }
}

/// Extension type for Address
extension type AddressType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static AddressType parse(Object? data) {
    return addressSchema.parseRepresentationAs(
      data,
      (representation) => AddressType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<AddressType> safeParse(Object? data) {
    return addressSchema.safeParseRepresentationAs(
      data,
      (representation) => AddressType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

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
      'street': street ?? _data['street'],
      'city': city ?? _data['city'],
      'zipCode': zipCode ?? _data['zipCode'],
      'country': country ?? _data['country'],
    });
  }
}

/// Extension type for Person
extension type PersonType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static PersonType parse(Object? data) {
    return personSchema.parseRepresentationAs(
      data,
      (representation) => PersonType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<PersonType> safeParse(Object? data) {
    return personSchema.safeParseRepresentationAs(
      data,
      (representation) => PersonType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  String get email => _data['email'] as String;

  AddressType get address =>
      AddressType(_data['address'] as Map<String, Object?>);

  int get age => _data['age'] as int;

  PersonType copyWith({
    String? name,
    String? email,
    AddressType? address,
    int? age,
  }) {
    return PersonType.parse({
      'name': name ?? _data['name'],
      'email': email ?? _data['email'],
      'address': address?.toJson() ?? _data['address'],
      'age': age ?? _data['age'],
    });
  }
}

/// Extension type for Employee
extension type EmployeeType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static EmployeeType parse(Object? data) {
    return employeeSchema.parseRepresentationAs(
      data,
      (representation) => EmployeeType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<EmployeeType> safeParse(Object? data) {
    return employeeSchema.safeParseRepresentationAs(
      data,
      (representation) => EmployeeType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  String get employeeId => _data['employeeId'] as String;

  AddressType get homeAddress =>
      AddressType(_data['homeAddress'] as Map<String, Object?>);

  AddressType get workAddress =>
      AddressType(_data['workAddress'] as Map<String, Object?>);

  EmployeeType copyWith({
    String? name,
    String? employeeId,
    AddressType? homeAddress,
    AddressType? workAddress,
  }) {
    return EmployeeType.parse({
      'name': name ?? _data['name'],
      'employeeId': employeeId ?? _data['employeeId'],
      'homeAddress': homeAddress?.toJson() ?? _data['homeAddress'],
      'workAddress': workAddress?.toJson() ?? _data['workAddress'],
    });
  }
}

/// Extension type for Modifier
extension type ModifierType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ModifierType parse(Object? data) {
    return modifierSchema.parseRepresentationAs(
      data,
      (representation) => ModifierType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<ModifierType> safeParse(Object? data) {
    return modifierSchema.safeParseRepresentationAs(
      data,
      (representation) => ModifierType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get requiredField => _data['requiredField'] as String;

  String? get optionalField => _data['optionalField'] as String?;

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
      'requiredField': requiredField ?? _data['requiredField'],
      if (optionalField != null || _data.containsKey('optionalField'))
        'optionalField': optionalField ?? _data['optionalField'],
      if (nullableField != null || _data.containsKey('nullableField'))
        'nullableField': nullableField ?? _data['nullableField'],
      if (optionalNullable != null || _data.containsKey('optionalNullable'))
        'optionalNullable': optionalNullable ?? _data['optionalNullable'],
      if (nullableOptional != null || _data.containsKey('nullableOptional'))
        'nullableOptional': nullableOptional ?? _data['nullableOptional'],
    });
  }
}

/// Extension type for TaggedItem
extension type TaggedItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static TaggedItemType parse(Object? data) {
    return taggedItemSchema.parseRepresentationAs(
      data,
      (representation) =>
          TaggedItemType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<TaggedItemType> safeParse(Object? data) {
    return taggedItemSchema.safeParseRepresentationAs(
      data,
      (representation) =>
          TaggedItemType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  List<String> get requiredTags => _$ackListCast<String>(_data['requiredTags']);

  List<String>? get optionalTags => _data['optionalTags'] != null
      ? _$ackListCast<String>(_data['optionalTags'])
      : null;

  List<String>? get nullableTags => _data['nullableTags'] != null
      ? _$ackListCast<String>(_data['nullableTags'])
      : null;

  TaggedItemType copyWith({
    String? name,
    List<String>? requiredTags,
    List<String>? optionalTags,
    List<String>? nullableTags,
  }) {
    return TaggedItemType.parse({
      'name': name ?? _data['name'],
      'requiredTags': requiredTags ?? _data['requiredTags'],
      if (optionalTags != null || _data.containsKey('optionalTags'))
        'optionalTags': optionalTags ?? _data['optionalTags'],
      if (nullableTags != null || _data.containsKey('nullableTags'))
        'nullableTags': nullableTags ?? _data['nullableTags'],
    });
  }
}

/// Extension type for ContactList
extension type ContactListType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ContactListType parse(Object? data) {
    return contactListSchema.parseRepresentationAs(
      data,
      (representation) =>
          ContactListType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<ContactListType> safeParse(Object? data) {
    return contactListSchema.safeParseRepresentationAs(
      data,
      (representation) =>
          ContactListType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  List<AddressType> get addresses => (_data['addresses'] as List)
      .map((e) => AddressType(e as Map<String, Object?>))
      .toList();

  ContactListType copyWith({String? name, List<AddressType>? addresses}) {
    return ContactListType.parse({
      'name': name ?? _data['name'],
      'addresses':
          addresses?.map((e) => e.toJson()).toList() ?? _data['addresses'],
    });
  }
}

/// Extension type for Empty
extension type EmptyType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static EmptyType parse(Object? data) {
    return emptySchema.parseRepresentationAs(
      data,
      (representation) => EmptyType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<EmptyType> safeParse(Object? data) {
    return emptySchema.safeParseRepresentationAs(
      data,
      (representation) => EmptyType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;
}

/// Extension type for Minimal
extension type MinimalType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static MinimalType parse(Object? data) {
    return minimalSchema.parseRepresentationAs(
      data,
      (representation) => MinimalType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<MinimalType> safeParse(Object? data) {
    return minimalSchema.safeParseRepresentationAs(
      data,
      (representation) => MinimalType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get id => _data['id'] as String;

  MinimalType copyWith({String? id}) {
    return MinimalType.parse({'id': id ?? _data['id']});
  }
}

/// Extension type for NamedItem
extension type NamedItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static NamedItemType parse(Object? data) {
    return namedItemSchema.parseRepresentationAs(
      data,
      (representation) => NamedItemType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<NamedItemType> safeParse(Object? data) {
    return namedItemSchema.safeParseRepresentationAs(
      data,
      (representation) => NamedItemType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  NamedItemType copyWith({String? name}) {
    return NamedItemType.parse({'name': name ?? _data['name']});
  }
}

/// Extension type for Item
extension type ItemType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ItemType parse(Object? data) {
    return item.parseRepresentationAs(
      data,
      (representation) => ItemType(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<ItemType> safeParse(Object? data) {
    return item.safeParseRepresentationAs(
      data,
      (representation) => ItemType(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get id => _data['id'] as String;

  ItemType copyWith({String? id}) {
    return ItemType.parse({'id': id ?? _data['id']});
  }
}

/// Extension type for MyCustomSchema123
extension type MyCustomSchema123Type(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static MyCustomSchema123Type parse(Object? data) {
    return myCustomSchema123.parseRepresentationAs(
      data,
      (representation) =>
          MyCustomSchema123Type(representation as Map<String, Object?>),
    );
  }

  static SchemaResult<MyCustomSchema123Type> safeParse(Object? data) {
    return myCustomSchema123.safeParseRepresentationAs(
      data,
      (representation) =>
          MyCustomSchema123Type(representation as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get value => _data['value'] as String;

  MyCustomSchema123Type copyWith({String? value}) {
    return MyCustomSchema123Type.parse({'value': value ?? _data['value']});
  }
}
