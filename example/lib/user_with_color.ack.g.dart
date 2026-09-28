// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'user_with_color.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

ColorModel _$ColorModelFromJson(Map<String, dynamic> json) =>
    ColorModel(ColorModel._ackFromRuntimeValue(json['value']));

Map<String, dynamic> _$ColorModelToJson(ColorModel instance) =>
    <String, dynamic>{'value': ColorModel._ackToRuntimeValue(instance.value)};

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  bio: Profile._ackFromRuntimeBio(json['bio']),
  website: Profile._ackFromRuntimeWebsite(json['website']),
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'bio': Profile._ackToRuntimeBio(instance.bio),
  'website': ?Profile._ackToRuntimeWebsite(instance.website),
};

UserWithColor _$UserWithColorFromJson(Map<String, dynamic> json) =>
    UserWithColor(
      firstName: UserWithColor._ackFromRuntimeFirstName(json['firstName']),
      lastName: UserWithColor._ackFromRuntimeLastName(json['lastName']),
      age: UserWithColor._ackFromRuntimeAge(json['age']),
      profile: UserWithColor._ackFromRuntimeProfile(json['profile']),
      color: UserWithColor._ackFromRuntimeColor(json['color']),
      favoriteColor: UserWithColor._ackFromRuntimeFavoriteColor(
        json['favoriteColor'],
      ),
      pet: UserWithColor._ackFromRuntimePet(json['pet']),
      pets: UserWithColor._ackFromRuntimePets(json['pets']),
    );

Map<String, dynamic> _$UserWithColorToJson(UserWithColor instance) =>
    <String, dynamic>{
      'firstName': UserWithColor._ackToRuntimeFirstName(instance.firstName),
      'lastName': UserWithColor._ackToRuntimeLastName(instance.lastName),
      'age': UserWithColor._ackToRuntimeAge(instance.age),
      'profile': UserWithColor._ackToRuntimeProfile(instance.profile),
      'color': UserWithColor._ackToRuntimeColor(instance.color),
      'favoriteColor': ?UserWithColor._ackToRuntimeFavoriteColor(
        instance.favoriteColor,
      ),
      'pet': UserWithColor._ackToRuntimePet(instance.pet),
      'pets': UserWithColor._ackToRuntimePets(instance.pets),
    };
