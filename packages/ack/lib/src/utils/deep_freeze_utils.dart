/// Public deep-freeze helpers used by generated Ack types.
library;

import 'default_utils.dart';

/// Recursively freezes supported collection values.
///
/// Maps, lists, and sets are converted to unmodifiable deep copies.
Object? ackDeepFreeze(Object? value) => cloneDefault(value);

/// Deep-freezes a JSON object map while preserving its key type.
Map<String, Object?> ackDeepFreezeObjectMap(Map<String, Object?> value) {
  final frozen = <String, Object?>{};
  value.forEach((key, entryValue) {
    frozen[key] = ackDeepFreeze(entryValue);
  });
  return Map<String, Object?>.unmodifiable(frozen);
}
