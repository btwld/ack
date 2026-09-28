// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'schema_types_edge_cases.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  name: Product._ackFromRuntimeName(json['name']),
  tags: Product._ackFromRuntimeTags(json['tags']),
  scores: Product._ackFromRuntimeScores(json['scores']),
  flags: Product._ackFromRuntimeFlags(json['flags']),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'name': Product._ackToRuntimeName(instance.name),
  'tags': Product._ackToRuntimeTags(instance.tags),
  'scores': Product._ackToRuntimeScores(instance.scores),
  'flags': Product._ackToRuntimeFlags(instance.flags),
};

Grid _$GridFromJson(Map<String, dynamic> json) => Grid(
  name: Grid._ackFromRuntimeName(json['name']),
  matrix: Grid._ackFromRuntimeMatrix(json['matrix']),
);

Map<String, dynamic> _$GridToJson(Grid instance) => <String, dynamic>{
  'name': Grid._ackToRuntimeName(instance.name),
  'matrix': Grid._ackToRuntimeMatrix(instance.matrix),
};

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  street: Address._ackFromRuntimeStreet(json['street']),
  city: Address._ackFromRuntimeCity(json['city']),
  zipCode: Address._ackFromRuntimeZipCode(json['zipCode']),
  country: Address._ackFromRuntimeCountry(json['country']),
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': Address._ackToRuntimeStreet(instance.street),
  'city': Address._ackToRuntimeCity(instance.city),
  'zipCode': Address._ackToRuntimeZipCode(instance.zipCode),
  'country': Address._ackToRuntimeCountry(instance.country),
};

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
  name: Person._ackFromRuntimeName(json['name']),
  email: Person._ackFromRuntimeEmail(json['email']),
  address: Person._ackFromRuntimeAddress(json['address']),
  age: Person._ackFromRuntimeAge(json['age']),
);

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
  'name': Person._ackToRuntimeName(instance.name),
  'email': Person._ackToRuntimeEmail(instance.email),
  'address': Person._ackToRuntimeAddress(instance.address),
  'age': Person._ackToRuntimeAge(instance.age),
};

Employee _$EmployeeFromJson(Map<String, dynamic> json) => Employee(
  name: Employee._ackFromRuntimeName(json['name']),
  employeeId: Employee._ackFromRuntimeEmployeeId(json['employeeId']),
  homeAddress: Employee._ackFromRuntimeHomeAddress(json['homeAddress']),
  workAddress: Employee._ackFromRuntimeWorkAddress(json['workAddress']),
);

Map<String, dynamic> _$EmployeeToJson(Employee instance) => <String, dynamic>{
  'name': Employee._ackToRuntimeName(instance.name),
  'employeeId': Employee._ackToRuntimeEmployeeId(instance.employeeId),
  'homeAddress': Employee._ackToRuntimeHomeAddress(instance.homeAddress),
  'workAddress': Employee._ackToRuntimeWorkAddress(instance.workAddress),
};

Modifier _$ModifierFromJson(Map<String, dynamic> json) => Modifier(
  requiredField: Modifier._ackFromRuntimeRequiredField(json['requiredField']),
  optionalField: Modifier._ackFromRuntimeOptionalField(json['optionalField']),
  nullableField: Modifier._ackFromRuntimeNullableField(json['nullableField']),
  optionalNullable: Modifier._ackFromRuntimeOptionalNullable(
    json['optionalNullable'],
  ),
  nullableOptional: Modifier._ackFromRuntimeNullableOptional(
    json['nullableOptional'],
  ),
);

Map<String, dynamic> _$ModifierToJson(Modifier instance) => <String, dynamic>{
  'requiredField': Modifier._ackToRuntimeRequiredField(instance.requiredField),
  'optionalField': ?Modifier._ackToRuntimeOptionalField(instance.optionalField),
  'nullableField': ?Modifier._ackToRuntimeNullableField(instance.nullableField),
  'optionalNullable': ?Modifier._ackToRuntimeOptionalNullable(
    instance.optionalNullable,
  ),
  'nullableOptional': ?Modifier._ackToRuntimeNullableOptional(
    instance.nullableOptional,
  ),
};

TaggedItem _$TaggedItemFromJson(Map<String, dynamic> json) => TaggedItem(
  name: TaggedItem._ackFromRuntimeName(json['name']),
  requiredTags: TaggedItem._ackFromRuntimeRequiredTags(json['requiredTags']),
  optionalTags: TaggedItem._ackFromRuntimeOptionalTags(json['optionalTags']),
  nullableTags: TaggedItem._ackFromRuntimeNullableTags(json['nullableTags']),
);

Map<String, dynamic> _$TaggedItemToJson(
  TaggedItem instance,
) => <String, dynamic>{
  'name': TaggedItem._ackToRuntimeName(instance.name),
  'requiredTags': TaggedItem._ackToRuntimeRequiredTags(instance.requiredTags),
  'optionalTags': ?TaggedItem._ackToRuntimeOptionalTags(instance.optionalTags),
  'nullableTags': ?TaggedItem._ackToRuntimeNullableTags(instance.nullableTags),
};

ContactList _$ContactListFromJson(Map<String, dynamic> json) => ContactList(
  name: ContactList._ackFromRuntimeName(json['name']),
  addresses: ContactList._ackFromRuntimeAddresses(json['addresses']),
);

Map<String, dynamic> _$ContactListToJson(ContactList instance) =>
    <String, dynamic>{
      'name': ContactList._ackToRuntimeName(instance.name),
      'addresses': ContactList._ackToRuntimeAddresses(instance.addresses),
    };

Empty _$EmptyFromJson(Map<String, dynamic> json) => Empty();

Map<String, dynamic> _$EmptyToJson(Empty instance) => <String, dynamic>{};

Minimal _$MinimalFromJson(Map<String, dynamic> json) =>
    Minimal(id: Minimal._ackFromRuntimeId(json['id']));

Map<String, dynamic> _$MinimalToJson(Minimal instance) => <String, dynamic>{
  'id': Minimal._ackToRuntimeId(instance.id),
};

NamedItem _$NamedItemFromJson(Map<String, dynamic> json) =>
    NamedItem(name: NamedItem._ackFromRuntimeName(json['name']));

Map<String, dynamic> _$NamedItemToJson(NamedItem instance) => <String, dynamic>{
  'name': NamedItem._ackToRuntimeName(instance.name),
};

Item _$ItemFromJson(Map<String, dynamic> json) =>
    Item(id: Item._ackFromRuntimeId(json['id']));

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'id': Item._ackToRuntimeId(instance.id),
};

MyCustomSchema123 _$MyCustomSchema123FromJson(Map<String, dynamic> json) =>
    MyCustomSchema123(
      value: MyCustomSchema123._ackFromRuntimeValue(json['value']),
    );

Map<String, dynamic> _$MyCustomSchema123ToJson(MyCustomSchema123 instance) =>
    <String, dynamic>{
      'value': MyCustomSchema123._ackToRuntimeValue(instance.value),
    };
