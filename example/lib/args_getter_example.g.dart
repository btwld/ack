// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'args_getter_example.dart';

/// Extension type for UserConfig
extension type UserConfigType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UserConfigType parse(Object? data) {
    final validated = userConfigSchema.parse(data);
    return UserConfigType(validated as Map<String, Object?>);
  }

  static SchemaResult<UserConfigType> safeParse(Object? data) {
    final result = userConfigSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(UserConfigType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get username => _data['username'] as String;

  String get email => _data['email'] as String;

  Map<String, Object?> get args => Map.fromEntries(
    _data.entries.where((e) => e.key != 'username' && e.key != 'email'),
  );

  UserConfigType copyWith({String? username, String? email}) {
    return UserConfigType.parse({
      'username': username ?? this.username,
      'email': email ?? this.email,
    });
  }
}

/// Extension type for ApiRequest
extension type ApiRequestType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ApiRequestType parse(Object? data) {
    final validated = apiRequestSchema.parse(data);
    return ApiRequestType(validated as Map<String, Object?>);
  }

  static SchemaResult<ApiRequestType> safeParse(Object? data) {
    final result = apiRequestSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(ApiRequestType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get method => _data['method'] as String;

  String get url => _data['url'] as String;

  Map<String, Object?> get args => Map.fromEntries(
    _data.entries.where((e) => e.key != 'method' && e.key != 'url'),
  );

  ApiRequestType copyWith({String? method, String? url}) {
    return ApiRequestType.parse({
      'method': method ?? this.method,
      'url': url ?? this.url,
    });
  }
}

/// Extension type for FeatureFlags
extension type FeatureFlagsType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static FeatureFlagsType parse(Object? data) {
    final validated = featureFlagsSchema.parse(data);
    return FeatureFlagsType(validated as Map<String, Object?>);
  }

  static SchemaResult<FeatureFlagsType> safeParse(Object? data) {
    final result = featureFlagsSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(FeatureFlagsType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get appVersion => _data['appVersion'] as String;

  String get environment => _data['environment'] as String;

  Map<String, Object?> get args => Map.fromEntries(
    _data.entries.where((e) => e.key != 'appVersion' && e.key != 'environment'),
  );

  FeatureFlagsType copyWith({String? appVersion, String? environment}) {
    return FeatureFlagsType.parse({
      'appVersion': appVersion ?? this.appVersion,
      'environment': environment ?? this.environment,
    });
  }
}

/// Extension type for DynamicData
extension type DynamicDataType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static DynamicDataType parse(Object? data) {
    final validated = dynamicDataSchema.parse(data);
    return DynamicDataType(validated as Map<String, Object?>);
  }

  static SchemaResult<DynamicDataType> safeParse(Object? data) {
    final result = dynamicDataSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(DynamicDataType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  Map<String, Object?> toJson() => _data;

  Map<String, Object?> get args => _data;
}
