// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'pet.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

Cat _$CatFromJson(Map<String, dynamic> json) =>
    Cat(lives: Cat._ackFromRuntimeLives(json['lives']));

Map<String, dynamic> _$CatToJson(Cat instance) => <String, dynamic>{
  'lives': Cat._ackToRuntimeLives(instance.lives),
};

Dog _$DogFromJson(Map<String, dynamic> json) =>
    Dog(breed: Dog._ackFromRuntimeBreed(json['breed']));

Map<String, dynamic> _$DogToJson(Dog instance) => <String, dynamic>{
  'breed': Dog._ackToRuntimeBreed(instance.breed),
};
