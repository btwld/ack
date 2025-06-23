import '../helpers.dart';
import 'schema_error.dart';

/// An exception thrown when schema validation fails using `parse()`.
///
/// It wraps a [SchemaError] instance, providing detailed information
/// about the validation failure.
class AckException implements Exception {
  final SchemaError error;

  const AckException(this.error);

  /// Converts this exception (specifically its underlying error) to a map.
  Map<String, dynamic> toMap() {
    return {'validationError': error.toMap()};
  }

  /// Converts this exception to a pretty-printed JSON string.
  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    String errorDetails;
    if (error is SchemaConstraintsError) {
      final constraintError = error as SchemaConstraintsError;
      errorDetails =
          constraintError.constraints.map((c) => c.message).join(', ');
    } else if (error is SchemaNestedError) {
      final nestedError = error as SchemaNestedError;
      errorDetails =
          nestedError.errors.map((e) => '"${e.name}": ${e.message}').join(', ');
    } else {
      errorDetails = error.message;
    }
    final valueStr = error.value?.toString() ?? 'null';
    final truncatedValue =
        valueStr.substring(0, valueStr.length > 30 ? 30 : valueStr.length) +
            (valueStr.length > 30 ? "..." : "");

    return 'AckException: Validation failed for "${error.name}" (value: $truncatedValue). Issues: $errorDetails';
  }
}
