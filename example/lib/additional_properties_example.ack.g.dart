// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'additional_properties_example.dart';

// **************************************************************************
// AckJsonSerializableGenerator
// **************************************************************************

UserConfig _$UserConfigFromJson(Map<String, dynamic> json) => UserConfig(
  username: UserConfig._ackFromRuntimeUsername(json['username']),
  email: UserConfig._ackFromRuntimeEmail(json['email']),
  additionalProperties:
      UserConfig._ackFromRuntimeAdditionalProperties(
        json['additionalProperties'],
      ) ??
      const {},
);

Map<String, dynamic> _$UserConfigToJson(UserConfig instance) =>
    <String, dynamic>{
      'username': UserConfig._ackToRuntimeUsername(instance.username),
      'email': UserConfig._ackToRuntimeEmail(instance.email),
      'additionalProperties': UserConfig._ackToRuntimeAdditionalProperties(
        instance.additionalProperties,
      ),
    };

ApiRequest _$ApiRequestFromJson(Map<String, dynamic> json) => ApiRequest(
  method: ApiRequest._ackFromRuntimeMethod(json['method']),
  url: ApiRequest._ackFromRuntimeUrl(json['url']),
  additionalProperties:
      ApiRequest._ackFromRuntimeAdditionalProperties(
        json['additionalProperties'],
      ) ??
      const {},
);

Map<String, dynamic> _$ApiRequestToJson(ApiRequest instance) =>
    <String, dynamic>{
      'method': ApiRequest._ackToRuntimeMethod(instance.method),
      'url': ApiRequest._ackToRuntimeUrl(instance.url),
      'additionalProperties': ApiRequest._ackToRuntimeAdditionalProperties(
        instance.additionalProperties,
      ),
    };

FeatureFlags _$FeatureFlagsFromJson(Map<String, dynamic> json) => FeatureFlags(
  appVersion: FeatureFlags._ackFromRuntimeAppVersion(json['appVersion']),
  environment: FeatureFlags._ackFromRuntimeEnvironment(json['environment']),
  additionalProperties:
      FeatureFlags._ackFromRuntimeAdditionalProperties(
        json['additionalProperties'],
      ) ??
      const {},
);

Map<String, dynamic> _$FeatureFlagsToJson(
  FeatureFlags instance,
) => <String, dynamic>{
  'appVersion': FeatureFlags._ackToRuntimeAppVersion(instance.appVersion),
  'environment': FeatureFlags._ackToRuntimeEnvironment(instance.environment),
  'additionalProperties': FeatureFlags._ackToRuntimeAdditionalProperties(
    instance.additionalProperties,
  ),
};

DynamicData _$DynamicDataFromJson(Map<String, dynamic> json) => DynamicData(
  additionalProperties:
      DynamicData._ackFromRuntimeAdditionalProperties(
        json['additionalProperties'],
      ) ??
      const {},
);

Map<String, dynamic> _$DynamicDataToJson(DynamicData instance) =>
    <String, dynamic>{
      'additionalProperties': DynamicData._ackToRuntimeAdditionalProperties(
        instance.additionalProperties,
      ),
    };
