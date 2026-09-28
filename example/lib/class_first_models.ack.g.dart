// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'class_first_models.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  displayName: _ackAccountFromRuntimeDisplayName(json['display_name']),
  website: _ackAccountFromRuntimeWebsite(json['website']),
  role: _ackAccountFromRuntimeRole(json['role']) ?? 'member',
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'display_name': _ackAccountToRuntimeDisplayName(instance.displayName),
  'website': ?_ackAccountToRuntimeWebsite(instance.website),
  'role': _ackAccountToRuntimeRole(instance.role),
};

Cat _$CatFromJson(Map<String, dynamic> json) => Cat(
  id: _ackCatFromRuntimeId(json['id']),
  lives: _ackCatFromRuntimeLives(json['lives']),
);

Map<String, dynamic> _$CatToJson(Cat instance) => <String, dynamic>{
  'id': _ackCatToRuntimeId(instance.id),
  'lives': _ackCatToRuntimeLives(instance.lives),
};

Dog _$DogFromJson(Map<String, dynamic> json) => Dog(
  id: _ackDogFromRuntimeId(json['id']),
  breed: _ackDogFromRuntimeBreed(json['breed']),
);

Map<String, dynamic> _$DogToJson(Dog instance) => <String, dynamic>{
  'id': _ackDogToRuntimeId(instance.id),
  'breed': _ackDogToRuntimeBreed(instance.breed),
};
