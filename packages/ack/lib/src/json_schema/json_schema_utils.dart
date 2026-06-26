/// Shared utilities for JSON Schema conversion.
library;

import 'package:meta/meta.dart';

/// Wraps property conversion with enhanced error context.
///
/// When converting schema properties, this wrapper catches errors and re-throws
/// them with additional context about which property caused the failure.
@internal
T wrapPropertyConversion<T>(String key, T Function() fn) {
  try {
    return fn();
  } catch (e, st) {
    final msg =
        'Error converting property "$key": ${e is Error ? e.toString() : e}';
    if (e is UnsupportedError) {
      Error.throwWithStackTrace(UnsupportedError(msg), st);
    } else if (e is ArgumentError) {
      Error.throwWithStackTrace(ArgumentError(msg), st);
    } else if (e is StateError) {
      Error.throwWithStackTrace(StateError(msg), st);
    }
    rethrow;
  }
}
