import 'dart:convert' show jsonEncode;

import 'package:build/build.dart' show log;

import '../models/constraint_info.dart';
import '../models/field_info.dart';
import '../models/model_info.dart';
import '../utils/type_resolver.dart';

/// Builds field schema expressions
class FieldBuilder {
  /// All models in the current compilation unit, used to look up
  /// custom schemaClassNames for nested type references
  List<ModelInfo> _allModels = [];

  /// Sets the list of all models for cross-referencing nested schemas
  void setAllModels(List<ModelInfo> models) {
    _allModels = models;
  }

  static final _constraintBuilders = {
    'minLength': (schema, args) => '$schema.minLength(${args[0]})',
    'maxLength': (schema, args) => '$schema.maxLength(${args[0]})',
    'notEmpty': (schema, args) => '$schema.notEmpty()',
    'email': (schema, args) => '$schema.email()',
    'url': (schema, args) => '$schema.url()',
    'matches': (schema, args) =>
        '$schema.matches(${_buildRegexLiteral(args[0])})',
    'min': (schema, args) => '$schema.min(${args[0]})',
    'max': (schema, args) => '$schema.max(${args[0]})',
    'positive': (schema, args) => '$schema.positive()',
    'multipleOf': (schema, args) => '$schema.multipleOf(${args[0]})',
    'minItems': (schema, args) => '$schema.minItems(${args[0]})',
    'maxItems': (schema, args) => '$schema.maxItems(${args[0]})',
    'enumString': (_, args) {
      final values = args.map((v) => "'$v'").join(', ');
      return 'Ack.enumString([$values])';
    },
    'pattern': (schema, args) =>
        '$schema.matches(${_buildRegexLiteral(args[0])})',
  };

  String buildFieldSchema(FieldInfo field, [ModelInfo? modelInfo]) {
    if (modelInfo != null &&
        modelInfo.isDiscriminatedSubtype &&
        modelInfo.discriminatorKey != null &&
        field.name == modelInfo.discriminatorKey) {
      return 'Ack.literal(\'${modelInfo.discriminatorValue}\')';
    }

    var schema =
        field.schemaExpressionOverride ??
        SchemableTypeResolver(
          allModels: _allModels,
          typeProviders: modelInfo?.typeProviders ?? const [],
        ).schemaExpressionFor(field.type);

    for (final constraint in field.constraints) {
      schema = _applyConstraint(schema, constraint);
    }

    if (!field.isRequired) {
      schema = '$schema.optional()';
    }

    if (field.isNullable) {
      schema = '$schema.nullable()';
    }

    if (field.description != null && field.description!.isNotEmpty) {
      final escapedDescription = _escapeForSingleQuotedString(
        field.description!,
      );
      schema = "$schema.describe('$escapedDescription')";
    }

    return schema;
  }

  String _applyConstraint(String schema, ConstraintInfo constraint) {
    final generator = _constraintBuilders[constraint.name];
    if (generator != null) {
      return generator(schema, constraint.arguments);
    }

    log.fine(
      'Unknown constraint "${constraint.name}" ignored. '
      'Check spelling or ensure constraint is registered.',
    );
    return schema;
  }

  /// Escapes a string for use in a single-quoted Dart string literal.
  ///
  /// Uses jsonEncode to properly handle all special characters (backslashes,
  /// newlines, unicode, etc.) then converts to single-quote format.
  String _escapeForSingleQuotedString(String value) {
    final jsonStr = jsonEncode(value);
    var escaped = jsonStr.substring(1, jsonStr.length - 1);
    escaped = escaped.replaceAll(r'\"', '"');
    escaped = escaped.replaceAll("'", r"\'");
    escaped = escaped.replaceAll(r'$', r'\$');
    return escaped;
  }

  /// Builds a safe regex literal string for code generation.
  ///
  /// Chooses the appropriate quoting strategy based on content:
  /// - Raw triple-quoted string if pattern doesn't contain `'''`
  /// - Double-quoted string with escaping otherwise (including `$` escaping)
  static String _buildRegexLiteral(String pattern) {
    if (!pattern.contains("'''")) {
      return "r'''$pattern'''";
    }

    final encoded = jsonEncode(pattern);
    return encoded.replaceAll(r'$', r'\$');
  }
}
