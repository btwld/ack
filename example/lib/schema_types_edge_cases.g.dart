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

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  List<List<int>> get matrix => _$ackListCast<List<int>>(_data['matrix']);

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

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  String get email => _data['email'] as String;

  AddressType get address =>
      AddressType(_data['address'] as Map<String, Object?>);

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

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  List<AddressType> get addresses => (_data['addresses'] as List)
      .map((e) => AddressType(e as Map<String, Object?>))
      .toList();

  ContactListType copyWith({
    String? name,
    List<Map<String, dynamic>>? addresses,
  }) {
    return ContactListType.parse({
      'name': name ?? this.name,
      'addresses': addresses ?? this.addresses,
    });
  }
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

  Map<String, Object?> toJson() => _data;
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

  Map<String, Object?> toJson() => _data;

  String get id => _data['id'] as String;

  MinimalType copyWith({String? id}) {
    return MinimalType.parse({'id': id ?? this.id});
  }
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

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  NamedItemType copyWith({String? name}) {
    return NamedItemType.parse({'name': name ?? this.name});
  }
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

  Map<String, Object?> toJson() => _data;

  String get id => _data['id'] as String;

  ItemType copyWith({String? id}) {
    return ItemType.parse({'id': id ?? this.id});
  }
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

  Map<String, Object?> toJson() => _data;

  String get value => _data['value'] as String;

  MyCustomSchema123Type copyWith({String? value}) {
    return MyCustomSchema123Type.parse({'value': value ?? this.value});
  }
}
