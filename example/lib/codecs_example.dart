/// Codec examples for the Ack validation library.
///
/// Codecs decode boundary (wire) values into rich Dart runtime types and encode
/// them back. Built-in codecs cover common conversions; `Ack.codec(...)` builds
/// a custom bidirectional codec.
library;

import 'package:ack/ack.dart';

/// Priority levels, used with `Ack.enumCodec`.
enum Priority { low, medium, high }

/// An event whose fields use built-in codecs:
///
/// - `startsAt`: ISO 8601 string <-> UTC `DateTime` (`Ack.datetime`)
/// - `due`: `YYYY-MM-DD` string <-> local-midnight `DateTime` (`Ack.date`)
/// - `website`: string <-> `Uri` (`Ack.uri`)
/// - `timeout`: milliseconds `int` <-> `Duration` (`Ack.duration`)
/// - `priority`: enum-name string <-> `Priority` (`Ack.enumCodec`)
final eventSchema = Ack.object({
  'name': Ack.string(),
  'startsAt': Ack.datetime(),
  'due': Ack.date(),
  'website': Ack.uri(),
  'timeout': Ack.duration(),
  'priority': Ack.enumCodec(Priority.values),
});

/// A custom bidirectional codec: comma-separated string <-> `List<String>`.
///
/// `decode` runs on parse; `encode` runs on `schema.encode`.
final tagsCodec = Ack.codec<String, String, List<String>>(
  input: Ack.string(),
  decode: (value) => value.split(','),
  encode: (tags) => tags.join(','),
);
