// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'schema_types_transforms.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

ColorModel _$ColorModelFromJson(Map<String, dynamic> json) =>
    ColorModel(ColorModel._ackFromRuntimeValue(json['value']));

Map<String, dynamic> _$ColorModelToJson(ColorModel instance) =>
    <String, dynamic>{'value': ColorModel._ackToRuntimeValue(instance.value)};

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  homepage: Profile._ackFromRuntimeHomepage(json['homepage']),
  birthday: Profile._ackFromRuntimeBirthday(json['birthday']),
  lastLogin: Profile._ackFromRuntimeLastLogin(json['lastLogin']),
  timeout: Profile._ackFromRuntimeTimeout(json['timeout']),
  links: Profile._ackFromRuntimeLinks(json['links']),
  favoriteColor: Profile._ackFromRuntimeFavoriteColor(json['favoriteColor']),
  slug: Profile._ackFromRuntimeSlug(json['slug']),
  accent: Profile._ackFromRuntimeAccent(json['accent']),
  colors: Profile._ackFromRuntimeColors(json['colors']),
  customColors: Profile._ackFromRuntimeCustomColors(json['customColors']),
  tagList: Profile._ackFromRuntimeTagList(json['tagList']),
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'homepage': Profile._ackToRuntimeHomepage(instance.homepage),
  'birthday': Profile._ackToRuntimeBirthday(instance.birthday),
  'lastLogin': Profile._ackToRuntimeLastLogin(instance.lastLogin),
  'timeout': Profile._ackToRuntimeTimeout(instance.timeout),
  'links': Profile._ackToRuntimeLinks(instance.links),
  'favoriteColor': Profile._ackToRuntimeFavoriteColor(instance.favoriteColor),
  'slug': Profile._ackToRuntimeSlug(instance.slug),
  'accent': Profile._ackToRuntimeAccent(instance.accent),
  'colors': Profile._ackToRuntimeColors(instance.colors),
  'customColors': Profile._ackToRuntimeCustomColors(instance.customColors),
  'tagList': Profile._ackToRuntimeTagList(instance.tagList),
};
