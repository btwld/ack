import 'package:ack/ack.dart';

/// Reads the required numeric field [key] from a decoded [map] as a `double`.
///
/// The schema has already validated the field, so the value is present and a
/// `num`; this just centralises the `as num` cast and `toDouble` conversion
/// shared by the object-shaped codec decoders.
double readDouble(JsonMap map, String key) => (map[key]! as num).toDouble();
