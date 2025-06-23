import 'package:meta/meta.dart';

import '../helpers.dart';
import 'schema_error.dart';

/// An exception thrown when schema validation fails using `parse()`.
///
/// It wraps a [SchemaError] instance, providing detailed information
/// about the validation failure.
@immutable
class AckException implements Exception {
  final List<SchemaError> errors;

  const AckException(this.errors);

  /// Converts this exception (specifically its underlying error) to a map.
  Map<String, dynamic> toMap() {
    return {'validationError': errors.map((e) => e.toMap()).toList()};
  }

  /// Converts this exception to a pretty-printed JSON string.
  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    if (errors.length == 1) {
      return errors.first.toString();
    }

    return 'AckException: Multiple validation errors occurred:\n${errors.map((e) => '  - ${e.toString()}').join('\n')}';
  }
}
