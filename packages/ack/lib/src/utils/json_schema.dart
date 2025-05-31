import 'dart:convert';
import 'dart:developer';

import '../constraints/constraint.dart';
import '../helpers.dart';
import '../schemas/schema.dart';
import '../validation/ack_exception.dart';

@Deprecated('Use JsonSchemaConverterException instead')
typedef OpenApiConverterException = JsonSchemaConverterException;

@Deprecated('Use JsonSchemaConverter instead')
typedef OpenApiSchemaConverter = JsonSchemaConverter;

class JsonSchemaConverterException implements Exception {
  final Object? error;
  final AckException? _ackException;

  final String _message;

  const JsonSchemaConverterException(
    this._message, {
    this.error,
    AckException? ackException,
  }) : _ackException = ackException;

  static JsonSchemaConverterException validationError(
    AckException ackException,
  ) {
    return JsonSchemaConverterException(
      'Validation error',
      ackException: ackException,
    );
  }

  static JsonSchemaConverterException unknownError(Object error) {
    return JsonSchemaConverterException('Unknown error', error: error);
  }

  static JsonSchemaConverterException jsonDecodeError(Object error) {
    return JsonSchemaConverterException('Invalid JSON format', error: error);
  }

  bool get isValidationError => _ackException != null;

  String get message {
    if (isValidationError) {
      return '$_message\n${_ackException!.toJson()}';
    }

    return '$_message\nError: ${error ?? ''}';
  }

  @override
  String toString() {
    return 'JsonSchemaConverterException: $message';
  }
}

class JsonSchemaConverter {
  /// The sequence that indicates the end of the response.
  /// Use this if you want the LLM to stop once it reaches response.
  final String stopSequence;
  final String startDelimeter;
  final String endDelimeter;
  final ObjectSchema _schema;

  const JsonSchemaConverter({
    required ObjectSchema schema,
    this.startDelimeter = '<response>',
    this.endDelimeter = '</response>',
    this.stopSequence = '<stop_response>',
    String? customResponseInstruction,
  }) : _schema = schema;

  String toResponsePrompt() {
    return '''
<schema>\n${toSchemaString()}\n</schema>

Your response should be valid JSON, that follows the <schema> and formatted as follows:

$startDelimeter
{valid_json_response}
$endDelimeter
$stopSequence
    ''';
  }

  Map<String, Object?> toSchema() {
    return _convertSchema(_schema);
  }

  String toSchemaString() => prettyJson(toSchema());

  Map<String, Object?> parseResponse(String response) {
    try {
      if (looksLikeJson(response)) {
        try {
          final jsonValue = jsonDecode(response) as Map<String, Object?>;

          return _schema.validate(jsonValue).getOrThrow();
        } catch (_) {
          log('Failed to parse response as JSON: $response');
          rethrow;
        }
      }
      // Get all the content after <_startDelimeter>
      final jsonString = response.substring(
        response.indexOf(startDelimeter) + startDelimeter.length,
        response.indexOf(endDelimeter),
      );

      final jsonValue = jsonDecode(jsonString) as Map<String, Object?>;

      return _schema.validate(jsonValue).getOrThrow();
    } on FormatException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        JsonSchemaConverterException.jsonDecodeError(e),
        stackTrace,
      );
    } on AckException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        JsonSchemaConverterException.validationError(e),
        stackTrace,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        JsonSchemaConverterException.unknownError(e),
        stackTrace,
      );
    }
  }
}

typedef JSON = Map<String, Object?>;

JSON _convertObjectSchema(ObjectSchema schema) {
  final properties = schema.getProperties();
  final required = schema.getRequiredProperties();
  final additionalProperties = schema.getAllowsAdditionalProperties();

  return {
    'properties':
        properties.map((key, value) => MapEntry(key, _convertSchema(value))),
    if (required.isNotEmpty) 'required': required,
    'additionalProperties': additionalProperties,
  };
}

JSON _convertDiscriminatedObjectSchema(DiscriminatedObjectSchema schema) {
  final discriminatorKey = schema.getDiscriminatorKey();
  final schemas = schema.getSchemas();

  // Create the oneOf array with each schema
  final oneOfSchemas = schemas.map((schema) => _convertSchema(schema)).toList();

  return {
    'discriminator': {'propertyName': discriminatorKey},
    'oneOf': oneOfSchemas,
  };
}

JSON _convertListSchema(ListSchema schema) => {
      'items': _convertSchema(schema.getItemSchema()),
    };

JSON _convertSchema(AckSchema schema) {
  final type = _convertSchemaType(schema.getSchemaTypeValue());
  final nullable = schema.getNullableValue();
  final description = schema.getDescriptionValue();
  final defaultValue = schema.getDefaultValue();

  JSON schemaMap = {
    if (type.isNotEmpty) 'type': type,
    // Nullable is false by default
    if (nullable) 'nullable': nullable,
    if (description.isNotEmpty) 'description': description,
    if (defaultValue != null) 'default': defaultValue,
  };

  if (schema is ObjectSchema) {
    schemaMap = deepMerge(schemaMap, _convertObjectSchema(schema));
  } else if (schema is DiscriminatedObjectSchema) {
    schemaMap = deepMerge(schemaMap, _convertDiscriminatedObjectSchema(schema));
  } else if (schema is ListSchema) {
    schemaMap = deepMerge(schemaMap, _convertListSchema(schema));
  }

  return deepMerge(
    schemaMap,
    _getMergeJsonSchemaConstraints(schema.getConstraints()),
  );
}

String _convertSchemaType(SchemaType type) {
  switch (type) {
    case SchemaType.string:
      return 'string';
    case SchemaType.double:
      return 'number';
    case SchemaType.int:
      return 'integer';
    case SchemaType.boolean:
      return 'boolean';
    case SchemaType.list:
      return 'array';
    case SchemaType.object:
      return 'object';
    case SchemaType.discriminatedObject:
      return '';
    case SchemaType.unknown:
      return 'unknown';
  }
}

/// Merges the JSON schemas from a list of [Validator<T>].
///
/// This function converts each validator to its schema representation using
/// [toJsonSchema()] and combines them into a single schema map using [deepMerge].
/// If a call to [toJsonSchema()] fails, the error is logged and the schema is skipped.
///
/// [constraints] - The list of OpenAPI constraint validators to merge.
/// Returns a merged schema map, or an empty map if no valid schemas are provided.
JSON _getMergeJsonSchemaConstraints<T extends Object>(
  List<Constraint<T>> constraints,
) {
  final openApiConstraints = constraints.whereType<OpenApiSpec<T>>();

  return openApiConstraints.fold<JSON>({}, (previousValue, element) {
    try {
      final schema = element.toJsonSchema();

      return deepMerge(previousValue, schema);
    } catch (e) {
      // Log the error and skip this schema
      log('Error generating schema for $element: $e');

      return previousValue;
    }
  });
}
