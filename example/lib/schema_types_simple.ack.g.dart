// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'schema_types_simple.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  name: User._ackFromRuntimeName(json['name']),
  age: User._ackFromRuntimeAge(json['age']),
  active: User._ackFromRuntimeActive(json['active']),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'name': User._ackToRuntimeName(instance.name),
  'age': User._ackToRuntimeAge(instance.age),
  'active': User._ackToRuntimeActive(instance.active),
};
