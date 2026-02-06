// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

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
