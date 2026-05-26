import 'package:ack/ack.dart';

/// A finite number — rejects `NaN` and the infinities, which are never valid
/// for Flutter measurements and are not JSON-safe.
NumberSchema finiteNumber() {
  return Ack.number().refine(
    (value) => value.isFinite,
    message: 'Expected a finite number.',
  );
}

/// A finite, non-negative number.
NumberSchema nonNegativeFiniteNumber() {
  return Ack.number().refine(
    (value) => value.isFinite && value >= 0,
    message: 'Expected a finite, non-negative number.',
  );
}

/// Reads the required numeric field [key] from a decoded [map] as a `double`.
///
/// The schema has already validated the field, so the value is present and a
/// `num`; this just centralises the `as num` cast and `toDouble` conversion
/// shared by the object-shaped codec decoders.
double readDouble(JsonMap map, String key) => (map[key]! as num).toDouble();
