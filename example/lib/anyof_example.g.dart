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
  'details': Ack.map(Ack.any()).optional().nullable(),
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
  ApiResponseSchemaModel._();

  factory ApiResponseSchemaModel() {
    return _instance;
  }

  static final _instance = ApiResponseSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return apiResponseSchema;
  }

  @override
  ApiResponse createFromMap(Map<String, dynamic> map) {
    return ApiResponse(
      status: map['status'] as String,
      data: ResponseDataSchemaModel._instance.createFromMap(
        map['data'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Generated SchemaModel for [UserResponse].
class UserResponseSchemaModel extends SchemaModel<UserResponse> {
  UserResponseSchemaModel._();

  factory UserResponseSchemaModel() {
    return _instance;
  }

  static final _instance = UserResponseSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return userResponseSchema;
  }

  @override
  UserResponse createFromMap(Map<String, dynamic> map) {
    return UserResponse(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
    );
  }
}

/// Generated SchemaModel for [ErrorResponse].
class ErrorResponseSchemaModel extends SchemaModel<ErrorResponse> {
  ErrorResponseSchemaModel._();

  factory ErrorResponseSchemaModel() {
    return _instance;
  }

  static final _instance = ErrorResponseSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return errorResponseSchema;
  }

  @override
  ErrorResponse createFromMap(Map<String, dynamic> map) {
    return ErrorResponse(
      code: map['code'] as String,
      message: map['message'] as String,
      details: map['details'] as Map<String, dynamic>?,
    );
  }
}

/// Generated SchemaModel for [ListResponse].
class ListResponseSchemaModel extends SchemaModel<ListResponse> {
  ListResponseSchemaModel._();

  factory ListResponseSchemaModel() {
    return _instance;
  }

  static final _instance = ListResponseSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return listResponseSchema;
  }

  @override
  ListResponse createFromMap(Map<String, dynamic> map) {
    return ListResponse(
      items: (map['items'] as List).cast<String>(),
      total: map['total'] as int,
      page: map['page'] as int,
    );
  }
}

/// Generated SchemaModel for [Setting].
/// Configuration setting with flexible value type
class SettingSchemaModel extends SchemaModel<Setting> {
  SettingSchemaModel._();

  factory SettingSchemaModel() {
    return _instance;
  }

  static final _instance = SettingSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return settingSchema;
  }

  @override
  Setting createFromMap(Map<String, dynamic> map) {
    return Setting(
      key: map['key'] as String,
      value: SettingValueSchemaModel._instance.createFromMap(
        map['value'] as Map<String, dynamic>,
      ),
    );
  }
}
