import 'dart:convert';
import 'dart:developer';

import '../constraints/constraint.dart';
import '../helpers.dart';
import '../schemas/schema.dart';
import '../validation/ack_exception.dart';

class OpenApiConverterException implements Exception {
  final Object? error;
  final AckException? _ackException;

  final String _message;

  const OpenApiConverterException(
    this._message, {
    this.error,
    AckException? ackException,
  }) : _ackException = ackException;

  static OpenApiConverterException validationError(
    AckException ackException,
  ) {
    return OpenApiConverterException(
      'Validation error',
      ackException: ackException,
    );
  }

  static OpenApiConverterException unknownError(Object error) {
    return OpenApiConverterException('Unknown error', error: error);
  }

  static OpenApiConverterException jsonDecodeError(Object error) {
    return OpenApiConverterException('Invalid JSON format', error: error);
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
    return 'OpenApiConverterException: $message';
  }
}

class OpenApiSchemaConverter {
  /// The sequence that indicates the end of the response.
  /// Use this if you want the LLM to stop once it reaches response.
  final String stopSequence;
  final String startDelimeter;
  final String endDelimeter;
  final ObjectSchema _schema;

  const OpenApiSchemaConverter({
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
        OpenApiConverterException.jsonDecodeError(e),
        stackTrace,
      );
    } on AckException catch (e, stackTrace) {
      Error.throwWithStackTrace(
        OpenApiConverterException.validationError(e),
        stackTrace,
      );
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        OpenApiConverterException.unknownError(e),
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

  if (properties.containsKey('type')) {
    throw ArgumentError('Property name "type" is reserved and cannot be used.');
  }

  return {
    'properties':
        properties.map((key, value) => MapEntry(key, _convertSchema(value))),
    if (required.isNotEmpty) 'required': required,
    'additionalProperties': additionalProperties,
  };
}

JSON _convertDiscriminatedObjectSchema(DiscriminatedObjectSchema schema) => {
      'discriminator': {'propertyName': schema.getDiscriminatorKey()},
      'oneOf':
          schema.getSchemas().map((schema) => _convertSchema(schema)).toList(),
    };

JSON _convertListSchema(ListSchema schema) => {
      'items': _convertSchema(schema.getItemSchema()),
    };

JSON _convertSchema(Schema schema) {
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

  switch (schema) {
    case ObjectSchema o:
      schemaMap = deepMerge(schemaMap, _convertObjectSchema(o));
      break;
    case DiscriminatedObjectSchema d:
      schemaMap = deepMerge(schemaMap, _convertDiscriminatedObjectSchema(d));
      break;
    case ListSchema l:
      schemaMap = deepMerge(schemaMap, _convertListSchema(l));
      break;
    default:
      break;
  }

  return deepMerge(
    schemaMap,
    _getMergedOpenApiConstraints(schema.getConstraints()),
  );
}

String _convertSchemaType(SchemaType type) {
  return switch (type) {
    SchemaType.string => 'string',
    SchemaType.double => 'number',
    SchemaType.int => 'integer',
    SchemaType.boolean => 'boolean',
    SchemaType.list => 'array',
    SchemaType.object => 'object',
    SchemaType.discriminatedObject => '',
    SchemaType.unknown => 'unknown',
  };
}

/// Merges the OpenAPI schemas from a list of [OpenApiConstraintValidator<T>].
///
/// This function converts each validator to its schema representation using
/// [toSchema()] and combines them into a single schema map using [deepMerge].
/// If a call to [toSchema()] fails, the error is logged and the schema is skipped.
///
/// [constraints] - The list of OpenAPI constraint validators to merge.
/// Returns a merged schema map, or an empty map if no valid schemas are provided.
JSON _getMergedOpenApiConstraints<T extends Object>(
  List<Constraint<T>> constraints,
) {
  final openApiConstraints = constraints.whereType<OpenApiSpec<T>>();

  return openApiConstraints.fold<JSON>({}, (previousValue, element) {
    try {
      final schema = element.toOpenApiSpec();

      return deepMerge(previousValue, schema);
    } catch (e) {
      // Log the error and skip this schema
      log('Error generating schema for $element: $e');

      return previousValue;
    }
  });
}
