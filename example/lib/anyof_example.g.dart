// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'anyof_example.dart';

/// Generated schema for ApiResponse
/// API response with different possible payloads
final apiResponseSchema = Ack.object({
  'status': Ack.string(),
  'data': responseDataSchema,
});

/// Generated schema for UserResponse
final userResponseSchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'email': Ack.string(),
});

/// Generated schema for ErrorResponse
final errorResponseSchema = Ack.object({
  'code': Ack.string(),
  'message': Ack.string(),
  'details': Ack.object({}, additionalProperties: true).optional().nullable(),
});

/// Generated schema for ListResponse
final listResponseSchema = Ack.object({
  'items': Ack.list(Ack.string()),
  'total': Ack.integer(),
  'page': Ack.integer(),
});

/// Generated schema for Setting
/// Configuration setting with flexible value type
final settingSchema = Ack.object({
  'key': Ack.string(),
  'value': settingValueSchema,
});

/// Generated SchemaModel for [ApiResponse].
/// API response with different possible payloads
class ApiResponseSchemaModel extends SchemaModel<ApiResponse> {
  ApiResponseSchemaModel._internal(ObjectSchema this.schema);

  factory ApiResponseSchemaModel() {
    return ApiResponseSchemaModel._internal(apiResponseSchema);
  }

  ApiResponseSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  ApiResponse createFromMap(Map<String, dynamic> map) {
    return ApiResponse(
      status: map['status'] as String,
      data: map['data'] as ResponseData,
    );
  }

  /// Returns a new schema with the specified description.
  ApiResponseSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return ApiResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  ApiResponseSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return ApiResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  ApiResponseSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return ApiResponseSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [UserResponse].
class UserResponseSchemaModel extends SchemaModel<UserResponse> {
  UserResponseSchemaModel._internal(ObjectSchema this.schema);

  factory UserResponseSchemaModel() {
    return UserResponseSchemaModel._internal(userResponseSchema);
  }

  UserResponseSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  UserResponse createFromMap(Map<String, dynamic> map) {
    return UserResponse(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
    );
  }

  /// Returns a new schema with the specified description.
  UserResponseSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return UserResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  UserResponseSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return UserResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  UserResponseSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return UserResponseSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [ErrorResponse].
class ErrorResponseSchemaModel extends SchemaModel<ErrorResponse> {
  ErrorResponseSchemaModel._internal(ObjectSchema this.schema);

  factory ErrorResponseSchemaModel() {
    return ErrorResponseSchemaModel._internal(errorResponseSchema);
  }

  ErrorResponseSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  ErrorResponse createFromMap(Map<String, dynamic> map) {
    return ErrorResponse(
      code: map['code'] as String,
      message: map['message'] as String,
      details: map['details'] as Map<String, dynamic>?,
    );
  }

  /// Returns a new schema with the specified description.
  ErrorResponseSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return ErrorResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  ErrorResponseSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return ErrorResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  ErrorResponseSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return ErrorResponseSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [ListResponse].
class ListResponseSchemaModel extends SchemaModel<ListResponse> {
  ListResponseSchemaModel._internal(ObjectSchema this.schema);

  factory ListResponseSchemaModel() {
    return ListResponseSchemaModel._internal(listResponseSchema);
  }

  ListResponseSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  ListResponse createFromMap(Map<String, dynamic> map) {
    return ListResponse(
      items: (map['items'] as List).cast<String>(),
      total: map['total'] as int,
      page: map['page'] as int,
    );
  }

  /// Returns a new schema with the specified description.
  ListResponseSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return ListResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  ListResponseSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return ListResponseSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  ListResponseSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return ListResponseSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [Setting].
/// Configuration setting with flexible value type
class SettingSchemaModel extends SchemaModel<Setting> {
  SettingSchemaModel._internal(ObjectSchema this.schema);

  factory SettingSchemaModel() {
    return SettingSchemaModel._internal(settingSchema);
  }

  SettingSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  Setting createFromMap(Map<String, dynamic> map) {
    return Setting(
      key: map['key'] as String,
      value: map['value'] as SettingValue,
    );
  }

  /// Returns a new schema with the specified description.
  SettingSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return SettingSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  SettingSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return SettingSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  SettingSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return SettingSchemaModel._withSchema(newSchema);
  }
}
