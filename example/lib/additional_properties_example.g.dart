// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'additional_properties_example.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

/// Immutable model generated from `userConfigSchema`.
final class UserConfig {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  UserConfig({
    required this.username,
    required this.email,
    Map<String, Object?> additionalProperties = const {},
  }) : additionalProperties = deepUnmodifiableJsonMap(additionalProperties);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory UserConfig.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory UserConfig.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String username;

  final String email;

  /// Properties accepted by a schema with additional properties.
  final Map<String, Object?> additionalProperties;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => userConfigSchema,
    fromRuntime: UserConfig._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [UserConfig] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<UserConfig> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $UserConfigCopyWith<UserConfig> get copyWith => _$UserConfigCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserConfig &&
          runtimeType == other.runtimeType &&
          deepEquals(username, other.username) &&
          deepEquals(email, other.email) &&
          deepEquals(additionalProperties, other.additionalProperties));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(username),
    deepHashCode(email),
    deepHashCode(additionalProperties),
  ]);

  @override
  String toString() =>
      'UserConfig(username: $username, email: $email, additionalProperties: $additionalProperties)';

  static UserConfig _fromAckRuntime(Map<String, Object?> value) {
    const declared = <String>{'username', 'email'};
    return UserConfig(
      username: value['username'] as String,
      email: value['email'] as String,
      additionalProperties: Map<String, Object?>.fromEntries(
        value.entries.where((entry) => !declared.contains(entry.key)),
      ),
    );
  }

  Map<String, Object?> _toAckRuntime() {
    const declared = <String>{'username', 'email'};
    return <String, Object?>{
      for (final entry in additionalProperties.entries)
        if (!declared.contains(entry.key)) entry.key: entry.value,
      'username': username,
      'email': email,
    };
  }
}

/// Creates copies of [UserConfig] with selected fields replaced.
abstract interface class $UserConfigCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? username,
    String? email,
    Map<String, Object?>? additionalProperties,
  });
}

final class _$UserConfigCopyWith implements $UserConfigCopyWith<UserConfig> {
  const _$UserConfigCopyWith(this._source);

  final UserConfig _source;

  @override
  UserConfig call({
    String? username,
    String? email,
    Map<String, Object?>? additionalProperties,
  }) => UserConfig(
    username: username ?? _source.username,
    email: email ?? _source.email,
    additionalProperties: additionalProperties ?? _source.additionalProperties,
  );
}

/// Immutable model generated from `apiRequestSchema`.
final class ApiRequest {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  ApiRequest({
    required this.method,
    required this.url,
    Map<String, Object?> additionalProperties = const {},
  }) : additionalProperties = deepUnmodifiableJsonMap(additionalProperties);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ApiRequest.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ApiRequest.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String method;

  final String url;

  /// Properties accepted by a schema with additional properties.
  final Map<String, Object?> additionalProperties;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => apiRequestSchema,
    fromRuntime: ApiRequest._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [ApiRequest] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<ApiRequest> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ApiRequestCopyWith<ApiRequest> get copyWith => _$ApiRequestCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiRequest &&
          runtimeType == other.runtimeType &&
          deepEquals(method, other.method) &&
          deepEquals(url, other.url) &&
          deepEquals(additionalProperties, other.additionalProperties));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(method),
    deepHashCode(url),
    deepHashCode(additionalProperties),
  ]);

  @override
  String toString() =>
      'ApiRequest(method: $method, url: $url, additionalProperties: $additionalProperties)';

  static ApiRequest _fromAckRuntime(Map<String, Object?> value) {
    const declared = <String>{'method', 'url'};
    return ApiRequest(
      method: value['method'] as String,
      url: value['url'] as String,
      additionalProperties: Map<String, Object?>.fromEntries(
        value.entries.where((entry) => !declared.contains(entry.key)),
      ),
    );
  }

  Map<String, Object?> _toAckRuntime() {
    const declared = <String>{'method', 'url'};
    return <String, Object?>{
      for (final entry in additionalProperties.entries)
        if (!declared.contains(entry.key)) entry.key: entry.value,
      'method': method,
      'url': url,
    };
  }
}

/// Creates copies of [ApiRequest] with selected fields replaced.
abstract interface class $ApiRequestCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? method,
    String? url,
    Map<String, Object?>? additionalProperties,
  });
}

final class _$ApiRequestCopyWith implements $ApiRequestCopyWith<ApiRequest> {
  const _$ApiRequestCopyWith(this._source);

  final ApiRequest _source;

  @override
  ApiRequest call({
    String? method,
    String? url,
    Map<String, Object?>? additionalProperties,
  }) => ApiRequest(
    method: method ?? _source.method,
    url: url ?? _source.url,
    additionalProperties: additionalProperties ?? _source.additionalProperties,
  );
}

/// Immutable model generated from `featureFlagsSchema`.
final class FeatureFlags {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  FeatureFlags({
    required this.appVersion,
    required this.environment,
    Map<String, Object?> additionalProperties = const {},
  }) : additionalProperties = deepUnmodifiableJsonMap(additionalProperties);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory FeatureFlags.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String appVersion;

  final String environment;

  /// Properties accepted by a schema with additional properties.
  final Map<String, Object?> additionalProperties;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => featureFlagsSchema,
    fromRuntime: FeatureFlags._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [FeatureFlags] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<FeatureFlags> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $FeatureFlagsCopyWith<FeatureFlags> get copyWith =>
      _$FeatureFlagsCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeatureFlags &&
          runtimeType == other.runtimeType &&
          deepEquals(appVersion, other.appVersion) &&
          deepEquals(environment, other.environment) &&
          deepEquals(additionalProperties, other.additionalProperties));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(appVersion),
    deepHashCode(environment),
    deepHashCode(additionalProperties),
  ]);

  @override
  String toString() =>
      'FeatureFlags(appVersion: $appVersion, environment: $environment, additionalProperties: $additionalProperties)';

  static FeatureFlags _fromAckRuntime(Map<String, Object?> value) {
    const declared = <String>{'appVersion', 'environment'};
    return FeatureFlags(
      appVersion: value['appVersion'] as String,
      environment: value['environment'] as String,
      additionalProperties: Map<String, Object?>.fromEntries(
        value.entries.where((entry) => !declared.contains(entry.key)),
      ),
    );
  }

  Map<String, Object?> _toAckRuntime() {
    const declared = <String>{'appVersion', 'environment'};
    return <String, Object?>{
      for (final entry in additionalProperties.entries)
        if (!declared.contains(entry.key)) entry.key: entry.value,
      'appVersion': appVersion,
      'environment': environment,
    };
  }
}

/// Creates copies of [FeatureFlags] with selected fields replaced.
abstract interface class $FeatureFlagsCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? appVersion,
    String? environment,
    Map<String, Object?>? additionalProperties,
  });
}

final class _$FeatureFlagsCopyWith
    implements $FeatureFlagsCopyWith<FeatureFlags> {
  const _$FeatureFlagsCopyWith(this._source);

  final FeatureFlags _source;

  @override
  FeatureFlags call({
    String? appVersion,
    String? environment,
    Map<String, Object?>? additionalProperties,
  }) => FeatureFlags(
    appVersion: appVersion ?? _source.appVersion,
    environment: environment ?? _source.environment,
    additionalProperties: additionalProperties ?? _source.additionalProperties,
  );
}

/// Immutable model generated from `dynamicDataSchema`.
final class DynamicData {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  DynamicData({Map<String, Object?> additionalProperties = const {}})
    : additionalProperties = deepUnmodifiableJsonMap(additionalProperties);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory DynamicData.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory DynamicData.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  /// Properties accepted by a schema with additional properties.
  final Map<String, Object?> additionalProperties;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => dynamicDataSchema,
    fromRuntime: DynamicData._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [DynamicData] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<DynamicData> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $DynamicDataCopyWith<DynamicData> get copyWith => _$DynamicDataCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DynamicData &&
          runtimeType == other.runtimeType &&
          deepEquals(additionalProperties, other.additionalProperties));

  @override
  int get hashCode =>
      Object.hashAll([runtimeType, deepHashCode(additionalProperties)]);

  @override
  String toString() =>
      'DynamicData(additionalProperties: $additionalProperties)';

  static DynamicData _fromAckRuntime(Map<String, Object?> value) {
    const declared = <String>{};
    return DynamicData(
      additionalProperties: Map<String, Object?>.fromEntries(
        value.entries.where((entry) => !declared.contains(entry.key)),
      ),
    );
  }

  Map<String, Object?> _toAckRuntime() {
    const declared = <String>{};
    return <String, Object?>{
      for (final entry in additionalProperties.entries)
        if (!declared.contains(entry.key)) entry.key: entry.value,
    };
  }
}

/// Creates copies of [DynamicData] with selected fields replaced.
abstract interface class $DynamicDataCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({Map<String, Object?>? additionalProperties});
}

final class _$DynamicDataCopyWith implements $DynamicDataCopyWith<DynamicData> {
  const _$DynamicDataCopyWith(this._source);

  final DynamicData _source;

  @override
  DynamicData call({Map<String, Object?>? additionalProperties}) => DynamicData(
    additionalProperties: additionalProperties ?? _source.additionalProperties,
  );
}
